//
//  RootTabView.swift
//  Wellness App
//
//  The four-tab shell: Nutrition, Activity, Restore, Profile.
//

import SwiftUI

struct RootTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(UserStore.self) private var user

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)

            NutritionView()
                .tabItem { Label("Nutrition", systemImage: "fork.knife") }
                .tag(AppTab.nutrition)

            ActivityView()
                .tabItem { Label("Activity", systemImage: "figure.run") }
                .tag(AppTab.activity)

            RestoreView()
                .tabItem { Label("Restore", systemImage: "moon.stars") }
                .tag(AppTab.restore)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(AppTab.profile)
        }
        .tint(appState.selectedTab.tint)
        // Onboarding gate. Auth drives `hasCompletedOnboarding` later; for now
        // the seeded user is already onboarded, so this stays dismissed.
        .fullScreenCover(isPresented: .constant(!user.hasCompletedOnboarding)) {
            OnboardingFlowView()
        }
    }
}

#Preview {
    RootTabView()
        .withSampleStores()
}
