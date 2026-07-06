//
//  ProfileGoalsView.swift
//  Wellness App
//
//  View and edit the primary goal, target weight, daily calorie and macro
//  targets, and the water, sleep, and step goals. Editing weight or activity
//  level offers a recompute of the daily targets, which the user accepts or
//  dismisses after seeing the old and new numbers side by side.
//

import SwiftUI

struct ProfileGoalsView: View {
    @Environment(UserStore.self) private var user
    @State private var viewModel = ProfileGoalsViewModel()

    private var system: UnitSystem { user.profile?.unitSystem ?? .metric }

    var body: some View {
        Form {
            if user.profile == nil {
                ProfileEmptyState(
                    systemImage: "target",
                    title: "No profile yet",
                    message: "Finish onboarding to set your goals and targets."
                )
            } else {
                goalSection
                inputsSection
                recomputeSection
                targetsSection
                wellnessSection
            }
        }
        .navigationTitle("Goals & targets")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(get: { viewModel.proposal }, set: { viewModel.proposal = $0 })) { proposal in
            ProfileTargetsProposalView(
                proposal: proposal,
                accept: { viewModel.accept(using: user) },
                cancel: { viewModel.dismiss() }
            )
        }
    }

    // MARK: - Goal

    private var goalSection: some View {
        Section("Primary goal") {
            Picker("Goal", selection: user.profileBinding(\.goal, default: .maintain)) {
                ForEach(Goal.allCases) { goal in
                    Text(goal.label).tag(goal)
                }
            }

            LabeledContent("Target weight") {
                HStack {
                    TextField("Target", value: targetWeightBinding, format: ProfileFormat.decimal)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                    Text(ProfileFormat.weightUnitLabel(system))
                        .foregroundStyle(.secondary)
                }
            }

            if user.profile?.goal != .maintain {
                Picker("Weekly rate", selection: weeklyRateBinding) {
                    ForEach(weeklyRateOptions, id: \.self) { rateKg in
                        Text(weeklyRateLabel(rateKg)).tag(rateKg)
                    }
                }
            }
        }
    }

    // MARK: - Inputs that feed recompute

    private var inputsSection: some View {
        Section {
            LabeledContent("Current weight") {
                HStack {
                    TextField("Weight", value: currentWeightBinding, format: ProfileFormat.decimal)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                    Text(ProfileFormat.weightUnitLabel(system))
                        .foregroundStyle(.secondary)
                }
            }

            Picker("Activity level", selection: user.profileBinding(\.activityLevel, default: .moderate)) {
                ForEach(ActivityLevel.allCases) { level in
                    Text(level.label).tag(level)
                }
            }
        } header: {
            Text("Your info")
        } footer: {
            Text("These feed your calorie and macro targets. Recalculate below after you change them.")
        }
    }

    // MARK: - Recompute

    private var recomputeSection: some View {
        Section {
            if user.requestedTargetIsUnsafe {
                Label {
                    Text("Your goal and rate would put you below a safe daily calorie floor. We clamp calories to the floor for you.")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                .font(.footnote)
            }

            Button {
                viewModel.recompute(using: user)
            } label: {
                Label("Recalculate my targets", systemImage: "arrow.triangle.2.circlepath")
            }
        } footer: {
            Text("We will show you the new numbers and you decide whether to apply them.")
        }
    }

    // MARK: - Targets (editable)

    private var targetsSection: some View {
        Section {
            intRow("Calories", binding: user.profileBinding(\.targets.calories, default: 0), unit: "kcal")
            intRow("Protein", binding: user.profileBinding(\.targets.proteinG, default: 0), unit: "g")
            intRow("Carbs", binding: user.profileBinding(\.targets.carbsG, default: 0), unit: "g")
            intRow("Fat", binding: user.profileBinding(\.targets.fatG, default: 0), unit: "g")
            intRow("Water", binding: user.profileBinding(\.targets.waterMl, default: 0), unit: "ml")
        } header: {
            Text("Daily targets")
        } footer: {
            Text("You can fine-tune any number by hand. Recalculating replaces them all.")
        }
    }

    // MARK: - Wellness goals

    private var wellnessSection: some View {
        Section("Wellness goals") {
            LabeledContent("Sleep") {
                HStack {
                    TextField("Sleep", value: user.profileBinding(\.wellnessGoals.sleepHours, default: 8),
                              format: ProfileFormat.decimal)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 60)
                    Text("hr")
                        .foregroundStyle(.secondary)
                }
            }
            Stepper(value: user.profileBinding(\.wellnessGoals.stepGoal, default: 10000), in: 1000...30000, step: 500) {
                LabeledContent("Steps", value: "\(user.profile?.wellnessGoals.stepGoal ?? 0)")
            }
            Stepper(value: user.profileBinding(\.wellnessGoals.workoutDaysPerWeek, default: 3), in: 0...7) {
                LabeledContent("Workout days / week", value: "\(user.profile?.wellnessGoals.workoutDaysPerWeek ?? 0)")
            }
        }
    }

    private func intRow(_ title: String, binding: Binding<Int>, unit: String) -> some View {
        LabeledContent(title) {
            HStack {
                TextField(title, value: binding, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 80)
                Text(unit)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Unit-aware bindings

    private var currentWeightBinding: Binding<Double> {
        Binding(
            get: { ProfileFormat.weightDisplayValue(kg: user.profile?.currentWeightKg ?? 0, system: system) },
            set: { newValue in
                let kg = ProfileFormat.kg(fromDisplayWeight: newValue, system: system)
                user.update { $0.currentWeightKg = kg }
            }
        )
    }

    private var targetWeightBinding: Binding<Double> {
        Binding(
            get: {
                let kg = user.profile?.targetWeightKg ?? user.profile?.currentWeightKg ?? 0
                return ProfileFormat.weightDisplayValue(kg: kg, system: system)
            },
            set: { newValue in
                let kg = ProfileFormat.kg(fromDisplayWeight: newValue, system: system)
                user.update { $0.targetWeightKg = kg > 0 ? kg : nil }
            }
        )
    }

    /// Weekly-rate options, held in kg (the stored unit) and snapped to the
    /// nearest option so the picker always shows a valid selection.
    private let weeklyRateOptions: [Double] = [0.25, 0.5, 0.75, 1.0]

    private func weeklyRateLabel(_ kg: Double) -> String {
        let value = ProfileFormat.weightDisplayValue(kg: kg, system: system)
        return String(format: "%@ %@/wk", ProfileFormat.decimal.format(value), ProfileFormat.weightUnitLabel(system))
    }

    private var weeklyRateBinding: Binding<Double> {
        Binding(
            get: {
                let kg = user.profile?.weeklyRateKg ?? 0.5
                return weeklyRateOptions.min(by: { abs($0 - kg) < abs($1 - kg) }) ?? 0.5
            },
            set: { newValue in
                user.update { $0.weeklyRateKg = newValue }
            }
        )
    }
}

// MARK: - Proposal comparison sheet

private struct ProfileTargetsProposalView: View {
    let proposal: ProfileTargetsProposal
    let accept: () -> Void
    let cancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    row("Calories", proposal.current.calories, proposal.proposed.calories, unit: "kcal")
                    row("Protein", proposal.current.proteinG, proposal.proposed.proteinG, unit: "g")
                    row("Carbs", proposal.current.carbsG, proposal.proposed.carbsG, unit: "g")
                    row("Fat", proposal.current.fatG, proposal.proposed.fatG, unit: "g")
                    row("Water", proposal.current.waterMl, proposal.proposed.waterMl, unit: "ml")
                } header: {
                    Text("Now vs proposed")
                } footer: {
                    Text("Apply the new targets or keep your current ones.")
                }
            }
            .navigationTitle("Review targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Keep current") {
                        cancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        accept()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func row(_ title: String, _ current: Int, _ proposed: Int, unit: String) -> some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                Text("\(current)")
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(proposed)")
                    .fontWeight(.semibold)
                    .foregroundStyle(proposed == current ? Color.primary : Theme.accent)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): was \(current), now \(proposed) \(unit)")
    }
}

#Preview {
    NavigationStack {
        ProfileGoalsView()
    }
    .withSampleStores()
}
