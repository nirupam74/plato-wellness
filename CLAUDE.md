# Wellness App

iOS SwiftUI health-tracking app with a home-screen WidgetKit extension. Firebase backend. **UI largely built; backend being wired up** via an autonomous loop.

Global principles in `~/.claude/CLAUDE.md` apply. This file adds only project specifics. For autonomous-loop work, follow `.claude/AUTONOMOUS_LOOP.md`.

## Stack & layout
- `Wellness App/` — SwiftUI app source; `Wellness App.xcodeproj`
- `Wellness Widget/` — WidgetKit extension
- `functions/` — Firebase Cloud Functions (Node, `index.js`); `firestore.rules`, `firestore.indexes.json`, `storage.rules`
- `control/` — autonomous-loop dashboard (default port 4319); `BACKEND.md` — backend status
- Firebase project: **wellness-app-4b33d7** (Blaze). iOS-only (no web app).

## Commands (from the repo's loop protocol)
- iOS build: `xcodebuild -project "Wellness App.xcodeproj" -scheme "Wellness App" -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO` → expect `** BUILD SUCCEEDED **`
- Functions syntax check: `node --check functions/index.js`
- Deploy: `firebase deploy --only firestore:rules` (or `firestore:indexes`, `storage`, `functions`)

## Branches
- `auto/build-out` — primary loop work line; `main` fast-forwards to it. **Don't commit to `main` directly** (keep it an ancestor of the branch, or the loop's fast-forward breaks).

## Gotchas
- The project path and the `.xcodeproj`/scheme names contain a **space** ("Wellness App") — always quote them in shell commands.
- Trust a full `xcodebuild ** BUILD SUCCEEDED **` over SourceKit's phantom single-file errors (it lacks the build's module graph).

## Never touch / needs human sign-off
- Secrets — never commit or expose: `functions/.env`, `GoogleService-Info.plist`, signing certs/profiles, StoreKit product IDs, bundle IDs, `*.entitlements`. No force-push, no history rewrite, no destructive Firestore/Storage data ops.
- Auth, billing/IAP, and destructive data changes need human sign-off (see `.claude/AUTONOMOUS_LOOP.md`).
