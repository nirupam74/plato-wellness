//
//  OnboardingFlowView.swift
//  Wellness App
//
//  The onboarding entry point. Presented by the orchestrator when the user is
//  not yet onboarded. It owns the view model, renders a progress header, the
//  current step, and a Back / Next footer, then builds the UserProfile and
//  calls completeOnboarding on finish (spec section 4).
//

import SwiftUI

struct OnboardingFlowView: View {
    @Environment(UserStore.self) private var user
    @Environment(NotificationManager.self) private var notifications

    @State private var vm = OnboardingViewModel()

    /// Called after the profile is saved, so a host can dismiss the flow.
    private let onComplete: (() -> Void)?

    // Two inits, as required: a no arg convenience and one that accepts a
    // completion handler. The second has no default so the two never collide.
    init() {
        self.onComplete = nil
    }

    init(onComplete: (() -> Void)?) {
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(
                current: vm.step.rawValue,
                total: OnboardingStep.allCases.count,
                title: vm.step.shortTitle
            )

            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
                .id(vm.step)

            footer
        }
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Step routing

    @ViewBuilder
    private var stepContent: some View {
        switch vm.step {
        case .welcome:       OnboardingWelcomeStep()
        case .basics:        OnboardingBasicsStep(vm: vm)
        case .measurements:  OnboardingMeasurementsStep(vm: vm)
        case .activity:      OnboardingActivityStep(vm: vm)
        case .goal:          OnboardingGoalStep(vm: vm)
        case .nutrition:     OnboardingNutritionStep(vm: vm)
        case .wellness:      OnboardingWellnessStep(vm: vm)
        case .targets:       OnboardingTargetsStep(vm: vm)
        case .healthKit:     OnboardingHealthKitStep(vm: vm)
        case .notifications: OnboardingNotificationsStep(vm: vm)
        case .companion:     OnboardingCompanionStep(vm: vm)
        case .done:          OnboardingDoneStep(firstName: vm.firstName.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    // MARK: - Footer navigation

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 12) {
            Divider()
            HStack(spacing: 12) {
                if !vm.isFirstStep {
                    Button {
                        vm.goBack()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.headline)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 18)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Go back")
                }

                if vm.step == .measurements {
                    Button("Skip") { vm.skip() }
                        .font(.headline)
                        .buttonStyle(.bordered)
                        .padding(.vertical, 4)
                }

                if showsPrimaryButton {
                    Button(action: primaryAction) {
                        Text(primaryLabel)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .disabled(!vm.canAdvance)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    /// Every step uses the generic primary (Next) button in the footer.
    private var showsPrimaryButton: Bool { true }

    private var primaryLabel: String {
        switch vm.step {
        case .welcome: "Get started"
        case .done:    "Start using the app"
        default:       "Next"
        }
    }

    private func primaryAction() {
        if vm.isLastStep {
            finish()
        } else {
            vm.advance()
        }
    }

    private func finish() {
        let profile = vm.makeProfile()
        user.completeOnboarding(with: profile)
        if let measurement = vm.makeMeasurement() {
            user.addMeasurement(measurement)
        }
        applyNotificationChoices()
        onComplete?()
    }

    /// Persist the reminder choices from onboarding to the same notify.* keys
    /// Settings uses, then request the system prompt and schedule if the user
    /// opted in. Without this the onboarding toggles were silently discarded.
    private func applyNotificationChoices() {
        let defaults = UserDefaults.standard
        let enabled = vm.notificationsEnabled
        defaults.set(enabled && vm.mealReminders, forKey: "notify.meals")
        defaults.set(enabled && vm.moveReminders, forKey: "notify.activity")
        defaults.set(enabled && vm.sleepReminders, forKey: "notify.sleep")
        defaults.set(enabled, forKey: "notify.water")

        guard enabled else { return }
        Task {
            await notifications.requestAuthorization()
            notifications.reschedule(.init(
                meals: vm.mealReminders,
                water: true,
                bedtime: vm.sleepReminders,
                move: vm.moveReminders
            ))
        }
    }
}

// The seeded preview user is already onboarded, so render the flow directly
// to exercise the onboarding UI.
#Preview {
    OnboardingFlowView()
        .withSampleStores()
}
