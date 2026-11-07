# Wellness Tracker

A personal iOS wellness app in SwiftUI. It tracks nutrition, activity, sleep, mood, water and daily rituals in one place, syncs with Apple Health, and includes an AI companion for check-ins. It is not released on the App Store.

## Features

- **Nutrition:** food log with barcode scanning, custom foods, a food library, meal plans, macro breakdowns and trends.
- **Activity:** steps, workout logging and live workout tracking, strength sessions and sports, with trends. Reads from HealthKit.
- **Restore:** sleep, mood check-ins, water, guided breathing, movement and skincare routines, with session timers.
- **Companion:** a chat companion for mental-health check-ins, with a disclaimer and a resources screen. Users can delete their chat history.
- **Focus:** a focus mode that limits distracting apps.
- **Profile:** goals, body measurements, stats and data export.
- **Widget:** a home-screen widget.

## How it is built

```
Wellness App/        SwiftUI app (iOS 17.6+): Core, Models, Stores, Features
Wellness Widget/     WidgetKit extension
functions/           Firebase Cloud Functions (Node)
firestore.rules      per-user security rules
storage.rules        owner-only storage rules
```

- SwiftUI with an MVVM structure and `@Observable` stores passed through the environment.
- Firebase Auth, Firestore and Storage. Rules scope all data to `users/{uid}`, so only the owner can read or write it.
- Cloud Functions:
  - `companionChat` proxies the Claude API, so the API key stays on the server (Secret Manager) and never ships in the app.
  - `dailyRollup` runs nightly and writes per-day summaries.
  - `deleteCompanionHistory` and `deleteAccount` handle user data deletion.
- HealthKit for steps and workouts.

## Running it

1. Open `Wellness App.xcodeproj` in Xcode.
2. Add your own `GoogleService-Info.plist` from a Firebase project to `Wellness App/`. It is git-ignored and not included in this repo.
3. For the companion, deploy `functions/` and set the `ANTHROPIC_API_KEY` secret with `firebase functions:secrets:set ANTHROPIC_API_KEY`.

No keys are committed to this repo.
