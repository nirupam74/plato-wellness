//
//  RootView.swift
//  Wellness App
//
//  Top level routing: sign in -> (loading) -> onboarding -> the four tabs.
//  Binds the stores to the signed in uid so they load live data from Firestore.
//

import SwiftUI

struct RootView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(AppState.self) private var appState
    @Environment(UserStore.self) private var user

    var body: some View {
        Group {
            if !auth.isSignedIn {
                SignInView()
            } else if !user.isLoaded {
                ProgressView("Loading your data...")
                    .controlSize(.large)
            } else if !user.hasCompletedOnboarding {
                OnboardingFlowView()
            } else {
                RootTabView()
            }
        }
        .onChange(of: auth.uid, initial: true) { _, uid in
            appState.bind(uid: uid)
            if uid != nil {
                Task {
                    await appState.notifications.refreshStatus()
                    await appState.syncHealthKit()
                }
            }
        }
    }
}
