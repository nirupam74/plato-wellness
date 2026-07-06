# Autonomous Loop — Activity Log

Human-readable log of every fix and feature the loop ships. The control
dashboard parses this table. Newest entries at the bottom. One row per shipped
change.

| # | Date | Area | Files | What | Verified |
|---|------|------|-------|------|----------|
| 1 | 2026-07-05 | ios | 75 Swift files | Built the full app: 4-tab shell, all models, HealthMath, in-memory stores, and every feature UI (Nutrition, Activity, Restore, AI Companion, Profile, Onboarding). Firebase/HealthKit/Auth deliberately stubbed. | ✓ build + 4-tab launch |
| 2 | 2026-07-05 | firebase, ios | functions, rules, app | Wired the whole app to live Firebase: Auth (Sign in with Apple), Firestore-backed stores, Storage, App Check, companion Cloud Function. Deployed backend. | ✓ build + launch |
| 3 | 2026-07-05 | ios, healthkit | HealthKitManager, NotificationManager, ProgressPhoto | HealthKit read/write, local notification reminders, and progress-photo upload to Storage. | ✓ build + launch |
| 4 | 2026-07-05 | security, ios | functions, rules, ProfileSettingsView, PrivacyInfo | App Store readiness: in-app account deletion (deleteAccount function + UI), PrivacyInfo.xcprivacy manifest, hardened Firestore rules, accessibility options, and in-app Help + Privacy Policy. | ✓ build + deploy |
| 5 | 2026-07-05 | ios | Stores | Bounded the busy Firestore listeners (food, activity, water, sleep, mood, sessions) with ordering + limits to cap reads for long histories. | ✓ build |
| 6 | 2026-07-05 | ios | Theme, RestoreView, Nutrition/Activity | UI refresh from the dashboard task: blue and white palette, distinct skincare icon, and removed redundant empty-state log buttons. | ✓ build |
| 7 | 2026-07-05 | ios | Focus/ | Focus Lock: commitment-based app blocking via Family Controls / Screen Time, reached from Restore. Needs a real device + entitlement approval. | ✓ build |
| 8 | 2026-07-05 | ios, firebase | AuthManager, SignInView | Email and password sign up alongside Sign in with Apple; enabled the Email/Password provider. | ✓ build |
| 9 | 2026-07-05 | ios | Legal, Profile | Self-directed: in-app Terms of Use screen + time-of-day personalized greeting. | ✓ build |
| 10 | 2026-07-05 | ios | Nutrition, Activity, Restore | Self-directed: haptic feedback on food, workout, sport, and mood logging. | ✓ build |
| 11 | 2026-07-05 | ios | UserStore | Self-directed: bounded the progress-photos Firestore listener (order + limit). | ✓ build |
| 12 | 2026-07-05 | ios | Components | Self-directed: StatTile combines into one VoiceOver element with accessibilityValue. | ✓ build |
| 13 | 2026-07-05 | ios, healthkit | ActivityView | Self-directed: pull-to-refresh on Activity re-syncs HealthKit. | ✓ build |
| 14 | 2026-07-05 | ios, healthkit | RestoreView | Self-directed: pull-to-refresh on Restore re-syncs HealthKit. | ✓ build |
| 15 | 2026-07-05 | ios | ProfileView | Self-directed: streak-milestone celebration in the Profile header. | ✓ build |
| 2026-07-06 00:00 | self-directed | About section in Settings showing app version + build number (App Store expectation, VoiceOver-combined) | dffda53 |
| 2026-07-06 00:05 | self-directed | Per-bar VoiceOver accessibility on steps + active-energy charts (date + value per day, navigable) | 62c4243 |
| 2026-07-06 00:11 | self-directed | Per-mark VoiceOver a11y on sleep (bars) + mood (points) trend charts | bc4c283 |
| 2026-07-06 00:17 | self-directed | Wired the sleep view Apple Health import button to real syncHealthKit (was a stale disabled stub) | 3bcd981 |
| 2026-07-06 00:23 | self-directed | Per-point VoiceOver a11y on weight, measurement, and body-fat trend charts (ProfileBodyDataView) | 5fcb9a0 |
| 2026-07-06 00:30 | self-directed | MetricRing marked accessibilityHidden (decorative); reviewed all 5 ring sites (already labeled) + Firestore rules (already owner-scoped, companion length-capped, no unsafe change to make) | 1db2a98 |
| 2026-07-06 00:36 | self-directed | MetricRing honors system Reduce Motion (no ring animation when enabled) | aed9f1f |
| 2026-07-06 00:42 | self-directed | Session countdown timer scales with Dynamic Type (ScaledMetric + minimumScaleFactor); confirmed other .system(size:) uses are decorative SF Symbols | 06eb072 |
| 2026-07-06 00:49 | self-directed | Companion chat welcome/empty state: personalized greeting + tappable conversation starters (fills draft, not auto-send) | 88ed300 |
| 2026-07-06 00:55 | self-directed | Companion chat honors Reduce Motion (crisis card fade vs slide, unanimated state change, non-animated scroll) | 032aba9 |
| 2026-07-06 01:01 | self-directed | Typing indicator stops its repeatForever pulse under Reduce Motion (audited all remaining Features animations; others already guarded/gentle) | e9e9da3 |
| 2026-07-06 01:06 | self-directed | SectionHeaderRow title marked .isHeader (VoiceOver rotor heading navigation app-wide from one component) | b80ba7c |
| 2026-07-06 01:13 | self-directed | Actionable crisis (Call/Text 988 tel+sms) and contact (mailto) links in Help/Privacy/Terms; PolicySection gained optional contactEmail | 0fccea6 |
| 2026-07-06 01:20 | self-directed | FIX: Settings Delete companion history was a no-op stub despite its confirm dialog; now calls CompanionStore.clearHistory (real privacy control) | dc24cf7 |
| 2026-07-06 01:28 | self-directed | FIX: removed redundant placeholder Sign in with Apple onboarding step (real auth is upstream in SignInView); dropped OnboardingSignInStep + OnboardingApplePlaceholderButton + didSignIn | 5d8db8f |
| 2026-07-06 01:35 | self-directed | Onboarding Connect Health now calls real HealthKitManager.requestAuthorization + honest copy (was placeholder). Deferred (risky unattended): onboarding notifications prompt wiring + RootView sign-in-vs-onboarding HealthKit timing | 36dcaf2 |
| 2026-07-06 01:42 | self-directed | FIX: onboarding reminder choices were silently discarded; finish() now persists notify.* prefs, requests notification auth, and schedules (was dead placeholder). Fixed stale MARKs | 7f493e7 |
| 2026-07-06 01:50 | self-directed | FIX: onboarding Foods to avoid was silently discarded (no UserProfile field); added optional foodsToAvoid to model + makeProfile. Follow-up: surface allergies/foodsToAvoid in profile editing | b935287 |
| 2026-07-06 01:57 | self-directed | Diet type / allergies / foods-to-avoid now viewable + editable in Goals & targets (were onboarding-only, unreachable after); completes the foodsToAvoid fix | 080de43 |
| 2026-07-06 02:03 | self-directed | companionChat context note now includes consent-gated diet/allergies/foods-to-avoid (safety: never-suggest allergies), reusing already-fetched profile. Verified: consent gating + mood/sleep/activity already correctly wired. NEEDS firebase deploy --only functions | c8543e1 |
| 2026-07-06 02:11 | self-directed | Data export now includes companion messages (JSON + CSV + count row); verified ProfileExporter is a real serializer, not a stub | 6d06b1f |
| 2026-07-06 02:20 | self-directed | FIX: mood check-ins were undeletable; added RestoreStore.removeMood + Recent check ins list with per-entry delete. Verified recipes/customFoods fully wired. Follow-up: same delete gap for sleep + water entries | 754daa5 |
| 2026-07-06 02:26 | self-directed | FIX: sleep entries were undeletable; added RestoreStore.removeSleep + Recent nights list with per-entry delete. Follow-up: water entries (last one) | 9b68e14 |
| 2026-07-06 02:32 | self-directed | FIX: water entries were undeletable; added RestoreStore.removeWater + Today log list with per-entry delete. All Restore log types (mood/sleep/water) now deletable | e92abfb |
| 2026-07-06 02:38 | self-directed | FIX: custom foods + recipes were undeletable; added NutritionStore.removeCustomFood/removeRecipe + swipe-to-delete. Mindful sessions have no per-session list UI (skipped); body measurements delete still pending | b0feb51 |
| 2026-07-06 02:45 | self-directed | FIX: body measurements were undeletable; added UserStore.removeMeasurement (no weight recompute) + History section with swipe-to-delete. DELETION SWEEP COMPLETE across all log types | 0ff1963 |
| 2026-07-06 02:53 | self-directed | FIX: progress photos were undeletable + footer falsely claimed on-device-only; added UserStore.removePhoto (Storage+Firestore) + context-menu delete + honest privacy copy | c5d2776 |
| 2026-07-06 03:00 | self-directed | Corrected 3 stale stub comments (sleep import, settings actions, daily activity source); audited HealthMath + streak logic and confirmed correct + DST-safe (no change needed) | 22b2af8 |
| 2026-07-06 03:07 | self-directed | FIX: progress photo upload failures were silent; uploadPhoto now returns success and the gallery shows a retry message on failure | 6822937 |
| 2026-07-06 03:14 | self-directed | FIX: account-deletion failures were silent in Settings; now shown under Account (stale errors cleared on appear/before attempt) + footer notes recent-login requirement. Verified sign-in errors already surfaced | 539969d |
| 2026-07-06 03:21 | self-directed | Clamp custom-food + manual food entry calories/macros/servings to non-negative on save (defense against negatives corrupting daily totals). Verified weight editor already guards <=0; catch blocks all handled | 9e7b4d5 |
| 2026-07-06 03:28 | self-directed | Weight entry now validated to a sane 20-500 kg range (protects BMR/target math from fat-fingered values) with an inline hint | 571f9af |
