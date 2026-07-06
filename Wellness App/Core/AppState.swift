//
//  AppState.swift
//  Wellness App
//
//  Root, app-wide state injected through the environment. Owns the feature
//  stores plus the HealthKit and notification managers, and binds everything to
//  the signed in user's uid. Previews use `seeded: true` (in-memory, uid nil).
//

import Observation

@Observable
final class AppState {
    var selectedTab: AppTab = .nutrition

    let user: UserStore
    let nutrition: NutritionStore
    let activity: ActivityStore
    let restore: RestoreStore
    let companion: CompanionStore

    let healthKit = HealthKitManager()
    let notifications = NotificationManager()
    let focus = FocusManager()

    init(seeded: Bool = false) {
        self.user = UserStore(seeded: seeded)
        self.nutrition = NutritionStore(seeded: seeded)
        self.activity = ActivityStore(seeded: seeded)
        self.restore = RestoreStore(seeded: seeded)
        self.companion = CompanionStore(seeded: seeded)

        // Stores write user logs back to Apple Health through this manager.
        user.healthKit = healthKit
        nutrition.healthKit = healthKit
        restore.healthKit = healthKit
    }

    /// Start (uid non nil) or stop (uid nil) live Firestore sync on every store.
    func bind(uid: String?) {
        user.bind(uid: uid)
        nutrition.bind(uid: uid)
        activity.bind(uid: uid)
        restore.bind(uid: uid)
        companion.bind(uid: uid)
    }

    /// Ask for HealthKit access, then pull device metrics into the stores. Safe
    /// to call repeatedly; the permission sheet only appears once.
    @MainActor
    func syncHealthKit() async {
        await healthKit.requestAuthorization()
        activity.dailySummaries = await healthKit.loadActivitySummaries(days: 14)
        let sleep = await healthKit.loadSleep(days: 14)
        restore.importHealthKitSleep(sleep)
    }
}
