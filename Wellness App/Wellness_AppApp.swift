//
//  Wellness_AppApp.swift
//  Wellness App
//
//  Created by Nirupam on 2026-07-05.
//

import SwiftUI

@main
struct Wellness_AppApp: App {
    @State private var appState: AppState
    @State private var auth: AuthManager

    init() {
        // Firebase + App Check must be configured before anything touches them.
        // Both AppState (its stores hold Firestore handles) and AuthManager touch
        // Firebase, so they are created here, after configure(), not as defaults.
        FirebaseBootstrap.configure()
        _appState = State(initialValue: AppState(seeded: false))
        _auth = State(initialValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(appState.user)
                .environment(appState.nutrition)
                .environment(appState.activity)
                .environment(appState.restore)
                .environment(appState.companion)
                .environment(appState.healthKit)
                .environment(appState.notifications)
                .environment(auth)
        }
    }
}
