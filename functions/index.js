"use strict";

/**
 * Wellness app — Cloud Functions
 *
 * companionChat        callable HTTPS. Proxies the Anthropic Messages API so the
 *                      API key never touches the client. Enforces Firebase Auth
 *                      and App Check, runs an independent crisis check, and
 *                      injects a short recent-data summary only with consent.
 * deleteCompanionHistory  callable HTTPS. Deletes all of a user's companion
 *                      messages (the one tap "delete all history" control).
 * dailyRollup          nightly scheduled job. Writes users/{uid}/dailyRollups.
 *
 * The Anthropic key is a secret (defineSecret), never in code or the client.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getStorage } = require("firebase-admin/storage");
const Anthropic = require("@anthropic-ai/sdk");

initializeApp();
const db = getFirestore();
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");

// A Sonnet class model is a good default for warm, supportive conversation
// (the build spec's recommendation). Set COMPANION_MODEL to claude-opus-4-8 for
// higher quality or claude-haiku-4-5 for lower cost and latency, without a code
// change.
const COMPANION_MODEL = process.env.COMPANION_MODEL || "claude-sonnet-5";

// Caps to control cost and abuse.
const MAX_OUTPUT_TOKENS = 1024;
const MAX_HISTORY_MESSAGES = 20;
const DAILY_MESSAGE_CAP = 100;

// ---- System prompt (lives here, never in the app) --------------------------

const SYSTEM_PROMPT = `You are a warm, patient, non judgmental companion inside a personal wellness app. You listen actively, reflect back what you hear, and offer gentle, practical coping tools (breathing, grounding, reframing, journaling prompts) and encouragement toward the user's own wellness goals.

Style: plain language, brief, human. Never clinical, never preachy. Do not use em dashes.

Hard boundaries: you are an AI companion, not a licensed professional. You do not diagnose, and you do not give medical or medication advice. For anything serious, you gently encourage reaching out to a real person, a professional, and trusted friends or family. You never try to become the user's only source of support, and you never reinforce negative self talk or harmful patterns.

Crisis protocol: if the user expresses self harm, suicidal thoughts, abuse, or acute crisis, respond with empathy, do not discuss methods, and encourage them to reach out to a real person or professional right now. In the US and Canada, 988 is the Suicide and Crisis Lifeline (call or text), and 911 is for immediate danger. Keep them talking and steer toward safety.`;

const CRISIS_APPENDIX = `

IMPORTANT: The user's latest message may indicate a crisis. Lead with warmth and safety. Do not discuss methods. Encourage them to contact 988 (call or text, US and Canada) or 911 if in immediate danger, and to reach out to someone they trust right now.`;

// ---- Independent crisis signal check (defense in depth, spec 8.2) ----------

const CRISIS_KEYWORDS = [
  "suicide", "kill myself", "end my life", "want to die", "self harm",
  "self-harm", "hurt myself", "no reason to live", "cant go on", "can't go on",
];

function crisisSignal(text) {
  const lower = (text || "").toLowerCase();
  return CRISIS_KEYWORDS.some((k) => lower.includes(k));
}

// ---- Consent gated context injection ---------------------------------------

async function buildContextNote(uid, profileSnap) {
  try {
    const [moods, sleeps, activities] = await Promise.all([
      db.collection(`users/${uid}/moodEntries`).orderBy("loggedAt", "desc").limit(3).get(),
      db.collection(`users/${uid}/sleepEntries`).orderBy("wakeTime", "desc").limit(3).get(),
      db.collection(`users/${uid}/activityEntries`).orderBy("loggedAt", "desc").limit(3).get(),
    ]);

    const parts = [];

    // Dietary constraints from the profile (already fetched by the caller, no
    // extra read). Allergies matter most, so the companion never suggests them.
    if (profileSnap && profileSnap.exists) {
      const diet = profileSnap.get("dietType");
      if (diet && diet !== "none") parts.push(`follows a ${diet} diet`);
      const allergies = profileSnap.get("allergies");
      if (Array.isArray(allergies) && allergies.length) {
        parts.push(`allergies (never suggest these): ${allergies.join(", ")}`);
      }
      const avoid = profileSnap.get("foodsToAvoid");
      if (Array.isArray(avoid) && avoid.length) {
        parts.push(`foods they prefer to avoid: ${avoid.join(", ")}`);
      }
    }
    if (!moods.empty) {
      const m = moods.docs.map((d) => d.get("mood")).filter((v) => v != null);
      if (m.length) parts.push(`recent mood ratings (1 to 5): ${m.join(", ")}`);
    }
    if (!sleeps.empty) {
      const h = sleeps.docs.map((d) => {
        const mins = d.get("durationMin");
        return mins != null ? (mins / 60).toFixed(1) : null;
      }).filter(Boolean);
      if (h.length) parts.push(`recent sleep (hours): ${h.join(", ")}`);
    }
    if (!activities.empty) {
      parts.push(`recent workouts logged: ${activities.size}`);
    }
    if (!parts.length) return "";
    return `\n\nContext the user consented to share, use it gently and only if relevant: ${parts.join("; ")}.`;
  } catch (err) {
    // Context is a nice to have. Never fail the chat because of it.
    console.warn("buildContextNote failed", err);
    return "";
  }
}

// ---- Soft per user daily rate limit ----------------------------------------

async function checkAndBumpDailyQuota(uid) {
  const day = new Date().toISOString().slice(0, 10);
  const ref = db.doc(`users/${uid}/companionUsage/${day}`);
  const snap = await ref.get();
  const count = snap.exists ? (snap.get("count") || 0) : 0;
  if (count >= DAILY_MESSAGE_CAP) {
    throw new HttpsError("resource-exhausted", "Daily companion message limit reached. Please try again tomorrow.");
  }
  await ref.set({ count: FieldValue.increment(1), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
}

// ---- companionChat ----------------------------------------------------------

exports.companionChat = onCall(
  { secrets: [ANTHROPIC_API_KEY], enforceAppCheck: true, cors: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to use the companion.");
    }
    const uid = request.auth.uid;
    const userMessage = (request.data && request.data.message ? String(request.data.message) : "").trim();
    if (!userMessage) {
      throw new HttpsError("invalid-argument", "A message is required.");
    }
    if (userMessage.length > 4000) {
      throw new HttpsError("invalid-argument", "Message is too long.");
    }

    await checkAndBumpDailyQuota(uid);

    const flagged = crisisSignal(userMessage);

    // Consent gate: only read recent data if the user opted in.
    let contextNote = "";
    const profileSnap = await db.doc(`users/${uid}`).get();
    if (profileSnap.exists && profileSnap.get("companionContextConsent") === true) {
      contextNote = await buildContextNote(uid, profileSnap);
    }

    // Recent history from the client, capped and normalized.
    const rawHistory = Array.isArray(request.data && request.data.history) ? request.data.history : [];
    const history = rawHistory
      .slice(-MAX_HISTORY_MESSAGES)
      .filter((m) => m && (m.role === "user" || m.role === "assistant") && typeof m.text === "string")
      .map((m) => ({ role: m.role, content: m.text }));

    const messages = history.concat([{ role: "user", content: userMessage }]);

    const client = new Anthropic({ apiKey: ANTHROPIC_API_KEY.value() });

    let reply;
    try {
      const resp = await client.messages.create({
        model: COMPANION_MODEL,
        max_tokens: MAX_OUTPUT_TOKENS,
        // Keep replies snappy for a chat companion.
        thinking: { type: "disabled" },
        system: SYSTEM_PROMPT + contextNote + (flagged ? CRISIS_APPENDIX : ""),
        messages,
      });
      reply = resp.content.filter((b) => b.type === "text").map((b) => b.text).join("").trim();
    } catch (err) {
      console.error("Anthropic call failed", err);
      throw new HttpsError("internal", "The companion is unavailable right now. Please try again.");
    }

    if (!reply) {
      reply = "I am here with you. Would you like to tell me a little more about what is on your mind?";
    }

    return { reply, flaggedForCrisis: flagged };
  }
);

// ---- deleteCompanionHistory -------------------------------------------------

exports.deleteCompanionHistory = onCall(
  { enforceAppCheck: true, cors: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;
    const col = db.collection(`users/${uid}/companionMessages`);
    let deleted = 0;
    // Delete in batches so we do not blow memory on long histories.
    while (true) {
      const snap = await col.limit(300).get();
      if (snap.empty) break;
      const batch = db.batch();
      snap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
      deleted += snap.size;
      if (snap.size < 300) break;
    }
    return { deleted };
  }
);

// ---- deleteAccount ----------------------------------------------------------

// Full account deletion, required by Apple for apps that create accounts
// (guideline 5.1.1(v)). Removes all Firestore data, all Storage files, and the
// Auth user itself. Irreversible.
exports.deleteAccount = onCall(
  { enforceAppCheck: true, cors: true },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;

    // Firestore: the user document and every subcollection under it.
    await db.recursiveDelete(db.doc(`users/${uid}`));

    // Storage: progress photos and anything else under the user's prefix.
    try {
      await getStorage().bucket().deleteFiles({ prefix: `users/${uid}/` });
    } catch (err) {
      console.warn("deleteAccount storage cleanup failed", err);
    }

    // Auth: the account itself.
    await getAuth().deleteUser(uid);

    return { ok: true };
  }
);

// ---- dailyRollup (nightly) --------------------------------------------------

// Writes a per user rollup for the prior day: calories in, calories burned,
// water, steps, mood, sleep. A starting point, extend the aggregation as needed.
exports.dailyRollup = onSchedule(
  { schedule: "every day 03:00", timeZone: "America/Toronto" },
  async () => {
    const day = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
    const start = new Date(`${day}T00:00:00.000Z`);
    const end = new Date(`${day}T23:59:59.999Z`);

    const users = await db.collection("users").get();
    for (const userDoc of users.docs) {
      const uid = userDoc.id;
      try {
        const [food, activity, water] = await Promise.all([
          db.collection(`users/${uid}/foodEntries`).where("loggedAt", ">=", start).where("loggedAt", "<=", end).get(),
          db.collection(`users/${uid}/activityEntries`).where("loggedAt", ">=", start).where("loggedAt", "<=", end).get(),
          db.collection(`users/${uid}/waterEntries`).where("loggedAt", ">=", start).where("loggedAt", "<=", end).get(),
        ]);

        const caloriesIn = food.docs.reduce((sum, d) => sum + (d.get("calories") || 0), 0);
        const caloriesBurned = activity.docs.reduce((sum, d) => sum + (d.get("caloriesBurned") || 0), 0);
        const waterMl = water.docs.reduce((sum, d) => sum + (d.get("amountMl") || 0), 0);

        await db.doc(`users/${uid}/dailyRollups/${day}`).set(
          {
            date: day,
            caloriesIn,
            caloriesBurned,
            waterMl,
            foodEntryCount: food.size,
            activityCount: activity.size,
            computedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      } catch (err) {
        console.error(`dailyRollup failed for ${uid}`, err);
      }
    }
  }
);
