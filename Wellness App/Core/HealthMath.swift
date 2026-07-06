//
//  HealthMath.swift
//  Wellness App
//
//  Pure functions for BMR, TDEE, calorie and macro targets, and water.
//  Kept free of side effects so they are trivially unit testable (spec section 5).
//

import Foundation

enum HealthMath {

    // MARK: - Constants

    /// Calories per kilogram of body mass, used to turn a weekly weight-change
    /// rate into a daily calorie delta.
    static let kcalPerKg = 7700.0

    /// Calorie floors below which we warn the user (spec section 5).
    static let calorieFloorFemale = 1200
    static let calorieFloorMale = 1500

    // MARK: - BMR (Mifflin St Jeor)

    /// Basal metabolic rate. Weight in kg, height in cm, age in years.
    static func bmr(weightKg: Double, heightCm: Double, ageYears: Int, sex: BiologicalSex) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(ageYears)
        switch sex {
        case .male:   return base + 5
        case .female: return base - 161
        }
    }

    // MARK: - TDEE

    static func tdee(bmr: Double, activityLevel: ActivityLevel) -> Double {
        bmr * activityLevel.multiplier
    }

    // MARK: - Calorie target

    /// Daily calorie delta implied by a weekly weight-change rate in kg.
    static func dailyCalorieDelta(weeklyRateKg: Double) -> Double {
        weeklyRateKg * kcalPerKg / 7
    }

    /// Raw calorie target for a goal, before applying the safety floor.
    static func calorieTarget(tdee: Double, goal: Goal, weeklyRateKg: Double?) -> Int {
        let rate = weeklyRateKg ?? 0
        switch goal {
        case .maintain: return Int(tdee.rounded())
        case .lose:     return Int((tdee - dailyCalorieDelta(weeklyRateKg: rate)).rounded())
        case .gain:     return Int((tdee + dailyCalorieDelta(weeklyRateKg: rate)).rounded())
        }
    }

    static func calorieFloor(for sex: BiologicalSex) -> Int {
        sex == .female ? calorieFloorFemale : calorieFloorMale
    }

    /// True when a proposed target dips below the safe floor for the sex.
    static func isBelowSafeFloor(_ calories: Int, sex: BiologicalSex) -> Bool {
        calories < calorieFloor(for: sex)
    }

    // MARK: - Macros

    /// Default macro split (all adjustable later by the user).
    /// Protein 1.6 g/kg, fat 25% of calories, carbs fill the remainder.
    static func macroTargets(calories: Int, weightKg: Double) -> (proteinG: Int, carbsG: Int, fatG: Int) {
        let protein = 1.6 * weightKg
        let fatCalories = Double(calories) * 0.25
        let fat = fatCalories / 9
        let remainingCalories = Double(calories) - (protein * 4) - fatCalories
        let carbs = max(0, remainingCalories / 4)
        return (Int(protein.rounded()), Int(carbs.rounded()), Int(fat.rounded()))
    }

    // MARK: - Water

    /// Default daily water target: 35 ml per kg of bodyweight, rounded.
    static func waterTargetMl(weightKg: Double) -> Int {
        Int((35 * weightKg).rounded())
    }

    // MARK: - Convenience: full target computation

    /// Compute a complete DailyTargets from a profile's inputs. Applies the
    /// safety floor to calories. Callers should surface a warning separately
    /// when `isBelowSafeFloor` is true for the requested rate.
    static func dailyTargets(
        weightKg: Double,
        heightCm: Double,
        ageYears: Int,
        sex: BiologicalSex,
        activityLevel: ActivityLevel,
        goal: Goal,
        weeklyRateKg: Double?
    ) -> DailyTargets {
        let bmrValue = bmr(weightKg: weightKg, heightCm: heightCm, ageYears: ageYears, sex: sex)
        let tdeeValue = tdee(bmr: bmrValue, activityLevel: activityLevel)
        let rawCalories = calorieTarget(tdee: tdeeValue, goal: goal, weeklyRateKg: weeklyRateKg)
        let calories = max(rawCalories, calorieFloor(for: sex))
        let macros = macroTargets(calories: calories, weightKg: weightKg)
        return DailyTargets(
            calories: calories,
            proteinG: macros.proteinG,
            carbsG: macros.carbsG,
            fatG: macros.fatG,
            waterMl: waterTargetMl(weightKg: weightKg)
        )
    }

    // MARK: - Activity calorie estimate

    /// Estimated calorie burn from an activity when the user does not supply one.
    /// Uses the MET formula: kcal = MET * 3.5 * weightKg / 200 * minutes.
    static func estimatedBurn(type: ActivityType, minutes: Int, weightKg: Double) -> Int {
        let perMinute = type.metValue * 3.5 * weightKg / 200
        return Int((perMinute * Double(minutes)).rounded())
    }

    /// Calories for a given MET value over a duration.
    static func burn(met: Double, minutes: Int, weightKg: Double) -> Int {
        let perMinute = met * 3.5 * weightKg / 200
        return Int((perMinute * Double(minutes)).rounded())
    }

    /// Sport-specific estimate: the sport's MET scaled by the chosen intensity.
    static func sportBurn(sport: Sport, minutes: Int, weightKg: Double, intensity: ActivityIntensity) -> Int {
        burn(met: sport.met * intensity.multiplier, minutes: minutes, weightKg: weightKg)
    }

    /// Swim estimate. Open water and higher intensity raise the MET.
    static func swimBurn(minutes: Int, weightKg: Double, intensity: ActivityIntensity, openWater: Bool) -> Int {
        let base: Double
        switch intensity {
        case .low:    base = 5.3
        case .medium: base = 7.0
        case .high:   base = 9.8
        }
        return burn(met: base + (openWater ? 0.5 : 0), minutes: minutes, weightKg: weightKg)
    }

    /// Strength-training estimate. Vigorous free-weight work is ~6 MET, moderate
    /// ~4, light ~3.5.
    static func strengthBurn(minutes: Int, weightKg: Double, intensity: ActivityIntensity) -> Int {
        let met: Double
        switch intensity {
        case .low:    met = 3.5
        case .medium: met = 5.0
        case .high:   met = 6.0
        }
        return burn(met: met, minutes: minutes, weightKg: weightKg)
    }
}
