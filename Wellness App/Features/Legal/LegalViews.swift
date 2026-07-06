//
//  LegalViews.swift
//  Wellness App
//
//  In-app help, guidelines, and privacy policy. Static content, reachable from
//  Settings. Keeping these in the app (not just a website) helps with Apple
//  review and gives people answers offline.
//

import SwiftUI

// MARK: - Help and guidelines

struct HelpView: View {
    var body: some View {
        List {
            Section("Getting started") {
                HelpRow(icon: "fork.knife", title: "Log your food",
                        text: "Tap the plus on the Nutrition tab to add a meal. Your calories and macros update against your daily target.")
                HelpRow(icon: "figure.run", title: "Track activity",
                        text: "Log workouts on the Activity tab, or connect Apple Health in Settings to import steps and energy automatically.")
                HelpRow(icon: "moon.stars", title: "Restore",
                        text: "Log water, mood, sleep, and skincare, and use the breathing and meditation timers to wind down.")
                HelpRow(icon: "sparkles", title: "Your companion",
                        text: "The companion is a warm space to reflect and check in. It is an AI, not a therapist or a crisis service.")
            }

            Section("Guidelines") {
                Text("Plato Wellness is for personal wellness tracking. It does not provide medical advice, diagnosis, or treatment. Talk to a qualified professional about any health concern.")
                Text("Targets and estimates are guides, not prescriptions. Never drop below a safe calorie intake to hit a goal faster.")
            }

            Section("If you are in crisis") {
                Text("If you are thinking about harming yourself, please reach out right now. In the US and Canada you can call or text 988, or call 911 for immediate danger. You are not alone.")
            }

            Section("Contact") {
                Text("Questions or feedback? Reach us at support@platowellness.app.")
            }
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HelpRow: View {
    var icon: String
    var title: String
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.restore)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Privacy policy

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PolicySection(title: "Your data is yours",
                    text: "Plato Wellness stores your logs, profile, and photos privately in your own account. No other user can see them. We never sell your data and we do not use it for advertising or tracking.")

                PolicySection(title: "What we collect",
                    text: "The information you enter (food, activity, sleep, mood, water, skincare, measurements, and companion messages), your name and email from Sign in with Apple, and progress photos you choose to add. If you connect Apple Health, we read steps, energy, and sleep, and can write your nutrition, water, weight, and mindful minutes back to Health.")

                PolicySection(title: "The companion",
                    text: "Companion messages are sent to a secure server that talks to an AI model to generate replies. Your recent mood, sleep, and activity are only shared with the companion if you turn that on in Settings. The companion is not a medical or emergency service.")

                PolicySection(title: "How it is stored",
                    text: "Your data lives in Google Firebase (Firestore and Storage) scoped to your account, protected by security rules and App Check. Traffic is encrypted in transit.")

                PolicySection(title: "Your controls",
                    text: "You can delete your companion history at any time, and you can delete your entire account from Settings, which permanently removes all of your data.")

                PolicySection(title: "Contact",
                    text: "Questions about privacy? Email privacy@platowellness.app.")
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PolicySection: View {
    var title: String
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
