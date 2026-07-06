# Wellness App — Backend

## Current state (2026-07-05)

- **Firebase project:** `wellness-app-4b33d7` on Blaze billing (`.firebaserc` points at it).
  Console: https://console.firebase.google.com/project/wellness-app-4b33d7/overview
- **Firestore:** database (nam5) + uid-scoped **rules + indexes DEPLOYED & LIVE.**
- **Storage:** default bucket `wellness-app-4b33d7.firebasestorage.app` provisioned;
  owner-only **rules DEPLOYED & LIVE.**
- **Cloud Functions:** `companionChat`, `deleteCompanionHistory`, `dailyRollup`
  **DEPLOYED & LIVE** (Node 20, us-central1). `ANTHROPIC_API_KEY` stored as a
  secret and granted to the functions service account. Companion model: `claude-sonnet-5`.
- **Auth (Sign in with Apple), App Check:** NOT started — console + Xcode.
  NOTE: the functions set `enforceAppCheck: true`, so the app cannot call
  `companionChat` until App Check is registered and wired in the app (use a debug
  token during development).

---


Every backend service the app needs, what it is, and exactly how to deploy each
one. Some steps only you can do (they need your Google account, billing, or the
Anthropic key). Those are marked **YOU**.

Note: **HealthKit is not a backend.** It is an on device Apple framework. There
is nothing to deploy; it is entitlements plus Swift code on the phone. It is
listed at the end for completeness.

---

## 0. One time setup (YOU)

The Firebase CLI is installed and you are logged in, but your account only has
the OneTake Crew project so far. The Wellness app needs its **own** Firebase
project.

1. **Create the project** (console is the reliable path — Blaze billing must be
   enabled there anyway):
   - Go to https://console.firebase.google.com, "Add project", name it
     (for example `Wellness App`). Note the generated project id.
   - Or via CLI: `firebase projects:create wellness-app-XXXX --display-name "Wellness App"`
2. **Point this repo at it:** edit `.firebaserc` and replace `wellness-app-REPLACE`
   with your real project id, or run `firebase use --add` and pick it.
3. **Enable Blaze (pay as you go) billing.** Cloud Functions require it. Console
   → your project → upgrade to Blaze. There is a generous free tier; you only
   pay past it.
4. **Register the iOS app** in the console (Project settings → Add app → iOS),
   use the bundle id, and **download `GoogleService-Info.plist`** into the Xcode
   project. This file is gitignored and must never be committed.

---

## 1. Firebase Auth — Sign in with Apple

- **What:** user identity. The app uses Sign in with Apple.
- **Deploy:** mostly console + Xcode, not CLI.
  - Console → Authentication → Get started → enable **Apple** as a provider.
  - Xcode → Signing & Capabilities → add **Sign in with Apple**.
  - Apple Developer portal → configure the Service ID / key if you use web
    sign in later.
- **YOU:** enable the provider, add the capability, Apple Developer config.

## 2. Cloud Firestore — user data

- **What:** all user generated logs (food, activity, water, sleep, mood,
  sessions, skincare, companion messages, measurements, rollups). Layout and
  the owner only security rules are already written in `firestore.rules`.
- **Deploy the rules + indexes:**
  ```bash
  firebase deploy --only firestore:rules,firestore:indexes
  ```
- Create the database first if needed: Console → Firestore → Create database
  (production mode). The rules above then lock it down per user.

## 3. Firebase Storage — progress photos

- **What:** private progress photos, one folder per user. Rules in
  `storage.rules` (owner only, image only, size capped).
- **Deploy:**
  ```bash
  firebase deploy --only storage
  ```

## 4. Cloud Functions — companion proxy, rollups, history delete

- **What:** `functions/index.js` holds:
  - `companionChat` — proxies the Anthropic Messages API so the key never
    reaches the client. Enforces Auth + App Check, runs the independent crisis
    check, and injects recent data only with consent.
  - `deleteCompanionHistory` — the one tap "delete all history" control.
  - `dailyRollup` — nightly per user rollups (scheduled).
- **Set the Anthropic key as a secret (YOU — you provide the key):**
  ```bash
  firebase functions:secrets:set ANTHROPIC_API_KEY
  # paste your key when prompted
  ```
- **Deploy:**
  ```bash
  cd functions && npm install && cd ..
  firebase deploy --only functions
  ```
- **Model:** defaults to `claude-sonnet-5` (good for warm chat). To change it
  without a code edit, set an env var on the function config, for example
  `claude-opus-4-8` for higher quality or `claude-haiku-4-5` for lower cost.
- Requires Blaze billing (step 0) and the scheduler API, which Firebase enables
  on first deploy of a scheduled function.

## 5. Anthropic Messages API — the companion's brain

- **What:** the actual model behind `companionChat`. Called only from the Cloud
  Function, never from the app.
- **Deploy:** nothing separate. You just supply the key as the function secret
  in step 4. Get a key at https://console.anthropic.com.
- **YOU:** provide the API key.

## 6. Firebase App Check — abuse protection

- **What:** ensures only your real app can call Firestore, Storage, and the
  companion function. A launch blocker per the build spec.
- **Deploy:**
  - Console → App Check → register the iOS app with **App Attest**.
  - Add the App Check SDK in the app and activate it at launch.
  - Enforce App Check on Firestore, Storage, and the function (the function
    already sets `enforceAppCheck: true`; turn on enforcement in the console).
- **YOU:** console registration + SDK wiring.

---

## Deploy order (once step 0 is done)

```bash
# 1. rules + storage (no billing needed)
firebase deploy --only firestore:rules,firestore:indexes,storage

# 2. the Anthropic secret, then functions (needs Blaze billing)
firebase functions:secrets:set ANTHROPIC_API_KEY
cd functions && npm install && cd ..
firebase deploy --only functions

# everything at once, later
firebase deploy
```

## Still on the app side (not a deploy)

- Wire the Firebase SDKs into the Xcode project (Auth, Firestore, Storage,
  Functions, App Check) and replace the in memory stores' `// SYNC:` seams with
  real reads and writes.
- Add `GoogleService-Info.plist` to the app target.
- HealthKit: add the capability and request authorization (on device, no deploy).
