//
//  ProfileSettingsView.swift
//  Wellness App
//
//  Units, notifications, HealthKit, privacy, appearance, and account. Preferences
//  that belong to the profile persist through the store; purely local ones use
//  @AppStorage. HealthKit, companion deletion, and account actions are stubs
//  wired up in later phases.
//

import SwiftUI

struct ProfileSettingsView: View {
    @Environment(UserStore.self) private var user
    @Environment(AppState.self) private var appState
    @Environment(HealthKitManager.self) private var healthKit
    @Environment(NotificationManager.self) private var notifications

    @AppStorage("appearance") private var appearance: ProfileAppearance = .system
    @AppStorage("notify.meals") private var notifyMeals = true
    @AppStorage("notify.water") private var notifyWater = true
    @AppStorage("notify.sleep") private var notifySleep = false
    @AppStorage("notify.activity") private var notifyActivity = true

    @State private var showSignOutConfirm = false
    @State private var showDeleteCompanionConfirm = false
    @State private var healthKitNote = false

    var body: some View {
        Form {
            unitsSection
            appearanceSection
            notificationsSection
            healthKitSection
            privacySection
            accountSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: notifyMeals) { _, _ in applyNotificationPrefs() }
        .onChange(of: notifyWater) { _, _ in applyNotificationPrefs() }
        .onChange(of: notifySleep) { _, _ in applyNotificationPrefs() }
        .onChange(of: notifyActivity) { _, _ in applyNotificationPrefs() }
    }

    private func applyNotificationPrefs() {
        Task {
            let anyOn = notifyMeals || notifyWater || notifySleep || notifyActivity
            if anyOn && !notifications.isAuthorized {
                await notifications.requestAuthorization()
            }
            notifications.reschedule(.init(
                meals: notifyMeals,
                water: notifyWater,
                bedtime: notifySleep,
                move: notifyActivity
            ))
        }
    }

    // MARK: - Units

    private var unitsSection: some View {
        Section("Units") {
            Picker("Measurement system", selection: user.profileBinding(\.unitSystem, default: .metric)) {
                ForEach(UnitSystem.allCases) { system in
                    Text(system.label).tag(system)
                }
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $appearance) {
                ForEach(ProfileAppearance.allCases) { option in
                    Label(option.label, systemImage: option.systemImage).tag(option)
                }
            }
            .pickerStyle(.inline)
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section {
            Toggle("Meal reminders", isOn: $notifyMeals)
            Toggle("Water reminders", isOn: $notifyWater)
            Toggle("Bedtime reminder", isOn: $notifySleep)
            Toggle("Move reminders", isOn: $notifyActivity)
        } header: {
            Text("Notifications")
        } footer: {
            Text("Reminder scheduling turns on once notification permission is granted.")
        }
    }

    // MARK: - HealthKit

    private var healthKitSection: some View {
        Section {
            Button {
                Task {
                    await healthKit.requestAuthorization()
                    await appState.syncHealthKit()
                    healthKitNote = true
                }
            } label: {
                Label("Connect Apple Health", systemImage: "heart.fill")
            }
        } header: {
            Text("Apple Health")
        } footer: {
            Text(healthKitNote
                 ? "Connected. Steps and energy sync in, and your logs sync out to Apple Health."
                 : "Sync steps, workouts, sleep, and nutrition with Apple Health.")
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        Section {
            Toggle(isOn: user.profileBinding(\.companionContextConsent, default: false)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Share context with the companion")
                    Text("Lets the companion reference your logs to personalize replies.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button(role: .destructive) {
                showDeleteCompanionConfirm = true
            } label: {
                Label("Delete companion history", systemImage: "trash")
            }
        } header: {
            Text("Privacy")
        } footer: {
            Text("You control what the companion can see. Deleting history cannot be undone.")
        }
        .confirmationDialog(
            "Delete all companion history?",
            isPresented: $showDeleteCompanionConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete history", role: .destructive) {
                // Wired to the companion store's delete in a later phase.
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes your conversation with the companion.")
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section("Account") {
            Button {
                // Account management arrives with Auth.
            } label: {
                Label("Manage account", systemImage: "person.crop.circle")
            }

            Button(role: .destructive) {
                showSignOutConfirm = true
            } label: {
                Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
        .confirmationDialog(
            "Sign out?",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign out", role: .destructive) {
                // Sign-out wires to Auth in a later phase.
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSettingsView()
    }
    .withSampleStores()
}
