//
//  OnboardingViewModel.swift
//  Wellness App
//
//  One observable model that accumulates every onboarding input across the
//  multi step flow and produces the final UserProfile (spec section 4). All
//  physical measurements are stored internally in metric; imperial entry is
//  converted with `Units` at the input edge before it lands here.
//

import SwiftUI
import Observation

/// The ordered steps of onboarding. `rawValue` doubles as the progress index.
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case signIn
    case basics
    case measurements
    case activity
    case goal
    case nutrition
    case wellness
    case targets
    case healthKit
    case notifications
    case companion
    case done

    var id: Int { rawValue }

    /// Short label used by the progress header and accessibility.
    var shortTitle: String {
        switch self {
        case .welcome:       "Welcome"
        case .signIn:        "Sign in"
        case .basics:        "About you"
        case .measurements:  "Measurements"
        case .activity:      "Activity"
        case .goal:          "Goal"
        case .nutrition:     "Nutrition"
        case .wellness:      "Wellness"
        case .targets:       "Targets"
        case .healthKit:     "Health"
        case .notifications: "Reminders"
        case .companion:     "Companion"
        case .done:          "All set"
        }
    }
}

@Observable
final class OnboardingViewModel {

    // MARK: - Navigation

    var step: OnboardingStep = .welcome

    var isFirstStep: Bool { step == OnboardingStep.allCases.first }
    var isLastStep: Bool { step == OnboardingStep.allCases.last }

    var progressFraction: Double {
        let total = Double(OnboardingStep.allCases.count)
        return total > 0 ? Double(step.rawValue + 1) / total : 0
    }

    // MARK: - Sign in (placeholder)

    var didSignIn = false

    // MARK: - Basics

    var firstName: String = ""
    var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    var biologicalSex: BiologicalSex = .female
    var unitSystem: UnitSystem = .metric

    /// Source of truth is always metric. The Basics screen edits these through
    /// the converting bindings below so the on screen value matches the picked
    /// unit system while storage stays metric.
    var heightCm: Double = 170
    var currentWeightKg: Double = 70

    var lengthUnitLabel: String { unitSystem == .metric ? "cm" : "in" }
    var weightUnitLabel: String { unitSystem == .metric ? "kg" : "lb" }

    var heightInput: Binding<Double> {
        Binding(
            get: { self.unitSystem == .metric ? self.heightCm : Units.cmToIn(self.heightCm) },
            set: { self.heightCm = self.unitSystem == .metric ? $0 : Units.inToCm($0) }
        )
    }

    var weightInput: Binding<Double> {
        Binding(
            get: { self.unitSystem == .metric ? self.currentWeightKg : Units.kgToLb(self.currentWeightKg) },
            set: { self.currentWeightKg = self.unitSystem == .metric ? $0 : Units.lbToKg($0) }
        )
    }

    // MARK: - Body measurements (optional, entered as text)

    var waistText = ""
    var hipsText = ""
    var chestText = ""
    var armText = ""
    var thighText = ""
    var neckText = ""
    var bodyFatText = ""

    /// Parse a length field into metric cm, honoring the chosen unit system.
    private func lengthCm(from text: String) -> Double? {
        guard let v = Self.parse(text), v > 0 else { return nil }
        return unitSystem == .metric ? v : Units.inToCm(v)
    }

    var waistCm: Double? { lengthCm(from: waistText) }
    var hipsCm: Double? { lengthCm(from: hipsText) }
    var chestCm: Double? { lengthCm(from: chestText) }
    var armCm: Double? { lengthCm(from: armText) }
    var thighCm: Double? { lengthCm(from: thighText) }
    var neckCm: Double? { lengthCm(from: neckText) }

    var bodyFatPercent: Double? {
        guard let v = Self.parse(bodyFatText), v > 0, v < 100 else { return nil }
        return v
    }

    var hasAnyMeasurement: Bool {
        [waistCm, hipsCm, chestCm, armCm, thighCm, neckCm, bodyFatPercent].contains { $0 != nil }
    }

    // MARK: - Activity

    var activityLevel: ActivityLevel? = nil

    // MARK: - Goal

    var goal: Goal? = nil
    var targetWeightText = ""
    /// Weekly weight change rate in kg (used only for lose or gain goals).
    var weeklyRateKg: Double = 0.5

    var goalNeedsTarget: Bool { goal == .lose || goal == .gain }

    var targetWeightKg: Double? {
        guard let v = Self.parse(targetWeightText), v > 0 else { return nil }
        return unitSystem == .metric ? v : Units.lbToKg(v)
    }

    /// Rate to feed the math, only meaningful for lose or gain.
    var effectiveWeeklyRate: Double? { goalNeedsTarget ? weeklyRateKg : nil }

    // MARK: - Nutrition

    var dietType: DietType = .none
    var allergies: [String] = []
    /// Collected per the spec. UserProfile has no dedicated field yet, so this
    /// stays in the view model for a future schema addition.
    var foodsToAvoid: [String] = []

    // MARK: - Wellness goals

    var sleepHours: Double = 8
    var waterTargetMl: Int = 2500
    var stepGoal: Int = 8000
    var workoutsPerWeek: Int = 3
    var morningSkincare = false
    var eveningSkincare = false
    private var waterPrepared = false

    /// Seed the water target from bodyweight the first time the wellness step
    /// appears, unless the user has already reached it.
    func prepareWaterIfNeeded() {
        guard !waterPrepared else { return }
        waterTargetMl = HealthMath.waterTargetMl(weightKg: currentWeightKg)
        waterPrepared = true
    }

    // MARK: - Daily targets (computed, then editable overrides)

    var caloriesInput = 0
    var proteinInput = 0
    var carbsInput = 0
    var fatInput = 0
    var waterInput = 0
    private(set) var targetsPrepared = false

    var ageYears: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    var bmrValue: Double {
        HealthMath.bmr(weightKg: currentWeightKg, heightCm: heightCm, ageYears: ageYears, sex: biologicalSex)
    }

    var tdeeValue: Double {
        HealthMath.tdee(bmr: bmrValue, activityLevel: activityLevel ?? .moderate)
    }

    /// The raw, unfloored calorie target implied by the current goal and rate.
    var rawCalorieTarget: Int {
        HealthMath.calorieTarget(tdee: tdeeValue, goal: goal ?? .maintain, weeklyRateKg: effectiveWeeklyRate)
    }

    /// True when the requested pace would push calories under the safe floor.
    var requestedRateIsUnsafe: Bool {
        HealthMath.isBelowSafeFloor(rawCalorieTarget, sex: biologicalSex)
    }

    var safeFloor: Int { HealthMath.calorieFloor(for: biologicalSex) }

    /// The recommended targets straight from the health math.
    func computedTargets() -> DailyTargets {
        HealthMath.dailyTargets(
            weightKg: currentWeightKg,
            heightCm: heightCm,
            ageYears: ageYears,
            sex: biologicalSex,
            activityLevel: activityLevel ?? .moderate,
            goal: goal ?? .maintain,
            weeklyRateKg: effectiveWeeklyRate
        )
    }

    /// Populate the editable target fields from the recommendation. Pass
    /// `force: true` for the "use recommended" reset button.
    func prepareTargets(force: Bool = false) {
        guard force || !targetsPrepared else { return }
        let t = computedTargets()
        caloriesInput = t.calories
        proteinInput = t.proteinG
        carbsInput = t.carbsG
        fatInput = t.fatG
        waterInput = waterTargetMl
        targetsPrepared = true
    }

    // MARK: - HealthKit and notifications (placeholders)

    var healthKitRequested = false
    var notificationsEnabled = false
    var mealReminders = true
    var moveReminders = true
    var sleepReminders = true

    // MARK: - Companion consent

    var companionAcknowledged = false
    var companionContextConsent = false

    // MARK: - Validation

    /// Whether the current step's required fields are satisfied.
    var canAdvance: Bool {
        switch step {
        case .welcome:       return true
        case .signIn:        return true
        case .basics:        return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                  && heightCm > 0 && currentWeightKg > 0
        case .measurements:  return true
        case .activity:      return activityLevel != nil
        case .goal:          return goal != nil && (!goalNeedsTarget || targetWeightKg != nil)
        case .nutrition:     return true
        case .wellness:      return true
        case .targets:       return caloriesInput > 0
        case .healthKit:     return true
        case .notifications: return true
        case .companion:     return companionAcknowledged
        case .done:          return true
        }
    }

    // MARK: - Step transitions

    func advance() {
        guard canAdvance, let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        withAnimation(.snappy) { step = next }
    }

    /// Skip an optional step without requiring its fields.
    func skip() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        withAnimation(.snappy) { step = next }
    }

    func goBack() {
        guard let prev = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        withAnimation(.snappy) { step = prev }
    }

    // MARK: - Output

    func makeProfile() -> UserProfile {
        if !targetsPrepared { prepareTargets() }
        let targets = DailyTargets(
            calories: caloriesInput,
            proteinG: proteinInput,
            carbsG: carbsInput,
            fatG: fatInput,
            waterMl: waterInput
        )
        let wellness = WellnessGoals(
            sleepHours: sleepHours,
            stepGoal: stepGoal,
            workoutDaysPerWeek: workoutsPerWeek,
            usesSkincareRoutine: morningSkincare || eveningSkincare
        )
        return UserProfile(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            dateOfBirth: dateOfBirth,
            biologicalSex: biologicalSex,
            heightCm: heightCm,
            currentWeightKg: currentWeightKg,
            unitSystem: unitSystem,
            activityLevel: activityLevel ?? .moderate,
            goal: goal ?? .maintain,
            targetWeightKg: goalNeedsTarget ? targetWeightKg : nil,
            weeklyRateKg: goalNeedsTarget ? weeklyRateKg : nil,
            dietType: dietType,
            allergies: allergies,
            targets: targets,
            wellnessGoals: wellness,
            companionContextConsent: companionContextConsent
        )
    }

    /// An optional starting body measurement if the user supplied any values.
    func makeMeasurement() -> BodyMeasurement? {
        guard hasAnyMeasurement else { return nil }
        return BodyMeasurement(
            bodyFatPercent: bodyFatPercent,
            waistCm: waistCm,
            hipsCm: hipsCm,
            chestCm: chestCm,
            armCm: armCm,
            thighCm: thighCm,
            neckCm: neckCm
        )
    }

    // MARK: - Helpers

    /// Parse a locale friendly decimal string, tolerating a comma separator.
    private static func parse(_ text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }
}
