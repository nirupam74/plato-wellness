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
    @Environment(\.scenePhase) private var scenePhase

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
        .onAppear { syncWidgets() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { syncWidgets() }
        }
    }

    /// Apply any water logged from a widget, then publish today's numbers.
    private func syncWidgets() {
        let pending = WidgetSync.consumePendingWater()
        if pending > 0 { appState.restore.addWater(ml: pending) }

        WidgetSync.publish(
            waterMl: appState.restore.todayWaterMl,
            waterGoal: user.profile?.targets.waterMl ?? 2000,
            calories: appState.nutrition.totals(on: Date()).calories,
            calorieTarget: user.profile?.targets.calories ?? 0,
            steps: appState.activity.todaySteps
        )
    }
}

#Preview {
    RootTabView()
        .withSampleStores()
}
