//
//  UserProfile.swift
//  Wellness App
//
//  The user record plus the computed daily targets and wellness goals.
//  Everything is stored in metric internally, converted only for display.
//

import Foundation

struct UserProfile: Codable, Identifiable {
    var id: String
    var firstName: String
    var dateOfBirth: Date
    var biologicalSex: BiologicalSex
    var heightCm: Double
    var currentWeightKg: Double
    var unitSystem: UnitSystem
    var activityLevel: ActivityLevel
    var goal: Goal
    var targetWeightKg: Double?
    var weeklyRateKg: Double?
    var dietType: DietType
    var allergies: [String]
    // Optional so profiles saved before this field existed still decode.
    var foodsToAvoid: [String]?
    var targets: DailyTargets
    var wellnessGoals: WellnessGoals
    var companionContextConsent: Bool
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        firstName: String,
        dateOfBirth: Date,
        biologicalSex: BiologicalSex,
        heightCm: Double,
        currentWeightKg: Double,
        unitSystem: UnitSystem = .metric,
        activityLevel: ActivityLevel,
        goal: Goal,
        targetWeightKg: Double? = nil,
        weeklyRateKg: Double? = nil,
        dietType: DietType = .none,
        allergies: [String] = [],
        foodsToAvoid: [String]? = nil,
        targets: DailyTargets,
        wellnessGoals: WellnessGoals,
        companionContextConsent: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.dateOfBirth = dateOfBirth
        self.biologicalSex = biologicalSex
        self.heightCm = heightCm
        self.currentWeightKg = currentWeightKg
        self.unitSystem = unitSystem
        self.activityLevel = activityLevel
        self.goal = goal
        self.targetWeightKg = targetWeightKg
        self.weeklyRateKg = weeklyRateKg
        self.dietType = dietType
        self.allergies = allergies
        self.foodsToAvoid = foodsToAvoid
        self.targets = targets
        self.wellnessGoals = wellnessGoals
        self.companionContextConsent = companionContextConsent
        self.createdAt = createdAt
    }

    /// Age in years, derived from date of birth against a reference date.
    func age(asOf reference: Date = Date()) -> Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: reference).year ?? 0
    }
}

struct DailyTargets: Codable, Equatable {
    var calories: Int
    var proteinG: Int
    var carbsG: Int
    var fatG: Int
    var waterMl: Int
}

struct WellnessGoals: Codable, Equatable {
    var sleepHours: Double
    var stepGoal: Int
    var workoutDaysPerWeek: Int
    var usesSkincareRoutine: Bool
}
