//
//  OnboardingStepsIntro.swift
//  Wellness App
//
//  The first half of the onboarding flow: welcome, sign in, basics, optional
//  body measurements, activity level, primary goal, nutrition, wellness goals.
//  Each step is a small View reading and writing the shared view model.
//

import SwiftUI

// MARK: - 1. Welcome

struct OnboardingWelcomeStep: View {
    var body: some View {
        OnboardingStepScaffold(
            title: "Welcome",
            subtitle: "One calm place for your nutrition, movement, sleep, and skin.",
            systemImage: "leaf.fill"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                OnboardingWelcomeBullet(
                    systemImage: "fork.knife",
                    tint: Theme.nutrition,
                    text: "Track meals and hit personalized macro targets."
                )
                OnboardingWelcomeBullet(
                    systemImage: "figure.run",
                    tint: Theme.activity,
                    text: "Log workouts and daily movement."
                )
                OnboardingWelcomeBullet(
                    systemImage: "moon.stars.fill",
                    tint: Theme.restore,
                    text: "Build restful sleep and skincare routines."
                )
            }
        }
    }
}

private struct OnboardingWelcomeBullet: View {
    let systemImage: String
    let tint: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 30)
                .accessibilityHidden(true)
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 2. Basics

struct OnboardingBasicsStep: View {
    @Bindable var vm: OnboardingViewModel

    private var dobRange: ClosedRange<Date> {
        let cal = Calendar.current
        let now = Date()
        let oldest = cal.date(byAdding: .year, value: -120, to: now) ?? now
        let youngest = cal.date(byAdding: .year, value: -13, to: now) ?? now
        return oldest...youngest
    }

    var body: some View {
        OnboardingStepScaffold(
            title: "About you",
            subtitle: "We use these to calculate your energy needs. Everything stays private.",
            systemImage: "person.text.rectangle"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Card {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("First name").font(.subheadline).foregroundStyle(.secondary)
                        TextField("First name", text: $vm.firstName)
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                            .font(.body)
                    }
                }

                Card {
                    DatePicker(
                        "Date of birth",
                        selection: $vm.dateOfBirth,
                        in: dobRange,
                        displayedComponents: .date
                    )
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Biological sex").font(.subheadline).foregroundStyle(.secondary)
                        Picker("Biological sex", selection: $vm.biologicalSex) {
                            ForEach(BiologicalSex.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        Text("Used only for the metabolic rate formula.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Units").font(.subheadline).foregroundStyle(.secondary)
                        Picker("Units", selection: $vm.unitSystem) {
                            ForEach(UnitSystem.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Card {
                    VStack(spacing: 12) {
                        OnboardingDecimalField(title: "Height", unit: vm.lengthUnitLabel, value: vm.heightInput)
                        Divider()
                        OnboardingDecimalField(title: "Current weight", unit: vm.weightUnitLabel, value: vm.weightInput)
                    }
                }
            }
        }
    }
}

// MARK: - 4. Body measurements (optional)

struct OnboardingMeasurementsStep: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        OnboardingStepScaffold(
            title: "Body measurements",
            subtitle: "Optional. Add any you like now, or skip and log them later.",
            systemImage: "ruler"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Card {
                    VStack(spacing: 12) {
                        OnboardingOptionalField(title: "Waist", unit: vm.lengthUnitLabel, text: $vm.waistText)
                        Divider()
                        OnboardingOptionalField(title: "Hips", unit: vm.lengthUnitLabel, text: $vm.hipsText)
                        Divider()
                        OnboardingOptionalField(title: "Chest", unit: vm.lengthUnitLabel, text: $vm.chestText)
                        Divider()
                        OnboardingOptionalField(title: "Arms", unit: vm.lengthUnitLabel, text: $vm.armText)
                        Divider()
                        OnboardingOptionalField(title: "Thighs", unit: vm.lengthUnitLabel, text: $vm.thighText)
                        Divider()
                        OnboardingOptionalField(title: "Neck", unit: vm.lengthUnitLabel, text: $vm.neckText)
                        Divider()
                        OnboardingOptionalField(title: "Body fat", unit: "%", text: $vm.bodyFatText)
                    }
                }
            }
        }
    }
}

// MARK: - 5. Activity level

struct OnboardingActivityStep: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        OnboardingStepScaffold(
            title: "How active are you?",
            subtitle: "Pick the option that best matches a typical week.",
            systemImage: "figure.walk.motion"
        ) {
            VStack(spacing: 12) {
                ForEach(ActivityLevel.allCases) { level in
                    OnboardingChoiceRow(
                        title: level.label,
                        subtitle: level.detail,
                        isSelected: vm.activityLevel == level
                    ) {
                        vm.activityLevel = level
                    }
                }
            }
        }
    }
}

// MARK: - 6. Primary goal

struct OnboardingGoalStep: View {
    @Bindable var vm: OnboardingViewModel

    private let rateOptions: [Double] = [0.25, 0.5, 0.75]

    var body: some View {
        OnboardingStepScaffold(
            title: "What is your main goal?",
            subtitle: "This shapes your calorie target. You can change it anytime.",
            systemImage: "target"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 12) {
                    ForEach(Goal.allCases) { goal in
                        OnboardingChoiceRow(
                            title: goal.label,
                            isSelected: vm.goal == goal
                        ) {
                            vm.goal = goal
                        }
                    }
                }

                if vm.goalNeedsTarget {
                    Card {
                        OnboardingOptionalField(
                            title: "Target weight",
                            unit: vm.weightUnitLabel,
                            text: $vm.targetWeightText
                        )
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Weekly pace").font(.subheadline).foregroundStyle(.secondary)
                            Picker("Weekly pace", selection: $vm.weeklyRateKg) {
                                ForEach(rateOptions, id: \.self) { rate in
                                    Text("\(rate, format: .number) kg").tag(rate)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    if vm.requestedRateIsUnsafe {
                        OnboardingCallout(
                            kind: .warning,
                            title: "That pace may be too aggressive",
                            message: "It would put your daily calories near or below the safe floor of \(vm.safeFloor) kcal. Consider a slower weekly pace. We will not set your target below the floor."
                        )
                    }
                }
            }
        }
    }
}

// MARK: - 7. Nutrition preferences

struct OnboardingNutritionStep: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        OnboardingStepScaffold(
            title: "Nutrition preferences",
            subtitle: "Helps tailor suggestions. All optional.",
            systemImage: "carrot"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Diet").font(.subheadline).foregroundStyle(.secondary)
                        Picker("Diet", selection: $vm.dietType) {
                            ForEach(DietType.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Card {
                    OnboardingTokenEditor(
                        title: "Allergies",
                        placeholder: "Add an allergy",
                        items: $vm.allergies
                    )
                }

                Card {
                    OnboardingTokenEditor(
                        title: "Foods to avoid",
                        placeholder: "Add a food",
                        items: $vm.foodsToAvoid
                    )
                }
            }
        }
    }
}

// MARK: - 8. Wellness goals

struct OnboardingWellnessStep: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        OnboardingStepScaffold(
            title: "Wellness goals",
            subtitle: "Set daily targets for rest, hydration, and movement.",
            systemImage: "heart.text.square"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Target sleep")
                            Spacer()
                            Text("\(vm.sleepHours, format: .number.precision(.fractionLength(1))) hours")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $vm.sleepHours, in: 4...12, step: 0.5)
                            .accessibilityLabel("Target sleep hours")
                            .accessibilityValue("\(vm.sleepHours, format: .number.precision(.fractionLength(1))) hours")
                    }
                }

                Card {
                    OnboardingIntField(title: "Daily water", unit: "ml", value: $vm.waterTargetMl)
                }

                Card {
                    OnboardingIntField(title: "Daily steps", unit: "steps", value: $vm.stepGoal)
                }

                Card {
                    Stepper(value: $vm.workoutsPerWeek, in: 0...14) {
                        HStack {
                            Text("Workouts per week")
                            Spacer()
                            Text("\(vm.workoutsPerWeek)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .accessibilityValue("\(vm.workoutsPerWeek) per week")
                }

                Card {
                    VStack(spacing: 4) {
                        Toggle("Morning skincare routine", isOn: $vm.morningSkincare)
                        Divider()
                        Toggle("Evening skincare routine", isOn: $vm.eveningSkincare)
                    }
                    .tint(Theme.accent)
                }
            }
        }
        .onAppear { vm.prepareWaterIfNeeded() }
    }
}
