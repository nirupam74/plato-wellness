//
//  OnboardingStepsFinish.swift
//  Wellness App
//
//  The final steps: computed targets summary with manual overrides, HealthKit
//  and notification placeholders, the AI companion intro with consent, and the
//  done screen. The done screen's primary button is handled by the flow view,
//  which builds the profile and calls completeOnboarding.
//

import SwiftUI

// MARK: - 9. Your targets

struct OnboardingTargetsStep: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        OnboardingStepScaffold(
            title: "Your daily targets",
            subtitle: "Calculated from your details. Accept them or fine tune any value.",
            systemImage: "chart.bar.doc.horizontal"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // Read only derived figures.
                Card {
                    VStack(spacing: 12) {
                        summaryRow("Basal metabolic rate", value: "\(Int(vm.bmrValue.rounded())) kcal")
                        Divider()
                        summaryRow("Total daily energy", value: "\(Int(vm.tdeeValue.rounded())) kcal")
                    }
                }

                SectionHeaderRow(title: "Targets") {
                    Button("Use recommended") {
                        vm.prepareTargets(force: true)
                    }
                    .font(.subheadline)
                }

                Card {
                    VStack(spacing: 12) {
                        OnboardingIntField(title: "Calories", unit: "kcal", value: $vm.caloriesInput)
                        Divider()
                        OnboardingIntField(title: "Protein", unit: "g", value: $vm.proteinInput)
                        Divider()
                        OnboardingIntField(title: "Carbs", unit: "g", value: $vm.carbsInput)
                        Divider()
                        OnboardingIntField(title: "Fat", unit: "g", value: $vm.fatInput)
                        Divider()
                        OnboardingIntField(title: "Water", unit: "ml", value: $vm.waterInput)
                    }
                }

                if HealthMath.isBelowSafeFloor(vm.caloriesInput, sex: vm.biologicalSex) {
                    OnboardingCallout(
                        kind: .warning,
                        title: "Calories are below the safe floor",
                        message: "For your profile we recommend staying at or above \(vm.safeFloor) kcal per day."
                    )
                }
            }
        }
        .onAppear { vm.prepareTargets() }
    }

    private func summaryRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 10. HealthKit

struct OnboardingHealthKitStep: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(HealthKitManager.self) private var healthKit

    var body: some View {
        OnboardingStepScaffold(
            title: "Connect Health",
            subtitle: "Sync steps, workouts, and weight with Apple Health.",
            systemImage: "heart.fill"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    Task {
                        await healthKit.requestAuthorization()
                        vm.healthKitRequested = true
                    }
                } label: {
                    Label(
                        vm.healthKitRequested ? "Requested" : "Allow Health access",
                        systemImage: vm.healthKitRequested ? "checkmark.circle.fill" : "heart.circle"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(vm.healthKitRequested)

                OnboardingCallout(
                    kind: .info,
                    title: "You are in control",
                    message: "Apple Health will ask which data to share. You can connect or change this anytime in Settings."
                )
            }
        }
    }
}

// MARK: - 11. Notifications

struct OnboardingNotificationsStep: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        OnboardingStepScaffold(
            title: "Stay on track",
            subtitle: "Gentle reminders help you keep your routines.",
            systemImage: "bell.badge"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Card {
                    Toggle("Enable reminders", isOn: $vm.notificationsEnabled)
                        .tint(Theme.accent)
                        .font(.headline)
                }

                if vm.notificationsEnabled {
                    Card {
                        VStack(spacing: 4) {
                            Toggle("Meal logging", isOn: $vm.mealReminders)
                            Divider()
                            Toggle("Move reminders", isOn: $vm.moveReminders)
                            Divider()
                            Toggle("Wind down for sleep", isOn: $vm.sleepReminders)
                        }
                        .tint(Theme.accent)
                    }
                }

                OnboardingCallout(
                    kind: .info,
                    title: "Your choice",
                    message: "If you turn reminders on, we will ask permission to send notifications when you finish setup. You can fine tune or turn these off anytime in Settings."
                )
            }
        }
    }
}

// MARK: - 12. Companion intro and consent

struct OnboardingCompanionStep: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        OnboardingStepScaffold(
            title: "Meet your companion",
            subtitle: "A supportive AI guide for reflection and encouragement.",
            systemImage: "bubble.left.and.text.bubble.right"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                OnboardingCallout(
                    kind: .info,
                    title: "This is an AI, not a person",
                    message: "The companion is an automated assistant. It is not a therapist, doctor, or crisis service, and it cannot provide medical or mental health treatment."
                )

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("If you are in crisis", systemImage: "phone.fill")
                            .font(.headline)
                        Text("In the US, call or text 988 to reach the Suicide and Crisis Lifeline. If you or someone else is in immediate danger, call 911 or your local emergency number.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Card {
                    Toggle(isOn: $vm.companionContextConsent) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Share a recent summary")
                                .font(.headline)
                            Text("Let the companion read a short summary of your recent mood, sleep, and activity to give more relevant replies. Off by default. You can change this anytime.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(Theme.accent)
                }

                Card {
                    Toggle(isOn: $vm.companionAcknowledged) {
                        Text("I understand the companion is an AI and not a substitute for professional care.")
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .tint(Theme.accent)
                }
            }
        }
    }
}

// MARK: - 13. Done

struct OnboardingDoneStep: View {
    let firstName: String

    private var greeting: String {
        firstName.isEmpty ? "You are all set" : "You are all set, \(firstName)"
    }

    var body: some View {
        OnboardingStepScaffold(
            title: greeting,
            subtitle: "Your plan is ready. Let's begin your first day.",
            systemImage: "checkmark.seal.fill"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                OnboardingCallout(
                    kind: .info,
                    title: "Everything is editable",
                    message: "Your targets, goals, and preferences can be adjusted anytime from your profile."
                )
            }
        }
    }
}
