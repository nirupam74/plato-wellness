//
//  SampleData.swift
//  Wellness App
//
//  In-memory seed data so every screen has something to show before Firebase
//  and HealthKit are connected. Replace these providers with live data sources
//  in later phases. All dates are relative to now so the trends look current.
//

import Foundation

enum SampleData {

    // MARK: - Profile

    static func profile() -> UserProfile {
        let dob = Calendar.current.date(from: DateComponents(year: 1990, month: 6, day: 15)) ?? Date()
        let targets = HealthMath.dailyTargets(
            weightKg: 74,
            heightCm: 178,
            ageYears: 35,
            sex: .male,
            activityLevel: .moderate,
            goal: .lose,
            weeklyRateKg: 0.5
        )
        return UserProfile(
            firstName: "Nirupam",
            dateOfBirth: dob,
            biologicalSex: .male,
            heightCm: 178,
            currentWeightKg: 74,
            unitSystem: .metric,
            activityLevel: .moderate,
            goal: .lose,
            targetWeightKg: 70,
            weeklyRateKg: 0.5,
            dietType: .none,
            allergies: [],
            targets: targets,
            wellnessGoals: WellnessGoals(sleepHours: 8, stepGoal: 10000, workoutDaysPerWeek: 4, usesSkincareRoutine: true),
            companionContextConsent: false
        )
    }

    static func measurements() -> [BodyMeasurement] {
        (0..<8).map { i in
            BodyMeasurement(
                weightKg: 76 - Double(i) * 0.25,
                bodyFatPercent: 20 - Double(i) * 0.2,
                waistCm: 86 - Double(i) * 0.3,
                recordedAt: Date().adding(days: -i * 7)
            )
        }
    }

    // MARK: - Nutrition

    static func foodEntries() -> [FoodEntry] {
        [
            FoodEntry(name: "Greek yogurt with berries", mealType: .breakfast, calories: 220, proteinG: 18, carbsG: 24, fatG: 6),
            FoodEntry(name: "Oatmeal", mealType: .breakfast, calories: 180, proteinG: 6, carbsG: 32, fatG: 4),
            FoodEntry(name: "Chicken salad", mealType: .lunch, calories: 430, proteinG: 38, carbsG: 20, fatG: 22),
            FoodEntry(name: "Apple", mealType: .snacks, calories: 95, proteinG: 0, carbsG: 25, fatG: 0),
            FoodEntry(name: "Salmon with rice", mealType: .dinner, calories: 560, proteinG: 40, carbsG: 45, fatG: 24),
        ]
    }

    static func customFoods() -> [CustomFood] {
        [
            CustomFood(name: "Protein shake", calories: 160, proteinG: 30, carbsG: 5, fatG: 2, isFavorite: true),
            CustomFood(name: "Avocado toast", calories: 290, proteinG: 8, carbsG: 30, fatG: 16, isFavorite: true),
            CustomFood(name: "Banana", calories: 105, proteinG: 1, carbsG: 27, fatG: 0),
        ]
    }

    // MARK: - Activity

    static func activityEntries() -> [ActivityEntry] {
        [
            ActivityEntry(type: .run, name: "Morning run", durationMin: 32, caloriesBurned: 340, distanceKm: 5.2, avgHeartRate: 152, loggedAt: Date().adding(days: -0)),
            ActivityEntry(type: .strength, name: "Upper body", durationMin: 45, caloriesBurned: 260, loggedAt: Date().adding(days: -1)),
            ActivityEntry(type: .ride, name: "Evening ride", durationMin: 50, caloriesBurned: 420, distanceKm: 18, loggedAt: Date().adding(days: -2)),
            ActivityEntry(type: .sport, name: "Basketball", durationMin: 60, caloriesBurned: 500, loggedAt: Date().adding(days: -3)),
        ]
    }

    static func dailyActivity() -> [DailyActivitySummary] {
        (0..<14).map { i in
            DailyActivitySummary(
                date: Date().adding(days: -i),
                steps: 6000 + (i * 977) % 7000,
                activeEnergyKcal: 300 + (i * 137) % 500,
                basalEnergyKcal: 1650
            )
        }
    }

    // MARK: - Restore

    static func waterEntries() -> [WaterEntry] {
        [
            WaterEntry(amountMl: 250, loggedAt: Date().adding(days: 0)),
            WaterEntry(amountMl: 500, loggedAt: Date().adding(days: 0)),
            WaterEntry(amountMl: 250, loggedAt: Date().adding(days: 0)),
        ]
    }

    static func sleepEntries() -> [SleepEntry] {
        (0..<14).map { i in
            let wake = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date().adding(days: -i)) ?? Date()
            let hours = 6.5 + Double((i * 3) % 4) * 0.4
            let bed = wake.addingTimeInterval(-hours * 3600)
            return SleepEntry(bedtime: bed, wakeTime: wake, quality: 3 + (i % 3), fromHealthKit: false)
        }
    }

    static func moodEntries() -> [MoodEntry] {
        (0..<14).map { i in
            MoodEntry(mood: 3 + (i % 3), stress: 2 + (i % 3), energy: 3 + ((i + 1) % 3), loggedAt: Date().adding(days: -i))
        }
    }

    static func restoreSessions() -> [RestoreSession] {
        [
            RestoreSession(type: .breathing, name: "Box breathing", durationMin: 5, completedAt: Date().adding(days: 0)),
            RestoreSession(type: .yoga, name: "Wind down", durationMin: 15, completedAt: Date().adding(days: -1)),
            RestoreSession(type: .meditation, name: "Focus", durationMin: 10, completedAt: Date().adding(days: -2)),
        ]
    }

    static func skincareSteps() -> [SkincareStep] {
        [
            SkincareStep(name: "Cleanser", timeOfDay: .morning, order: 0),
            SkincareStep(name: "Serum", timeOfDay: .morning, order: 1),
            SkincareStep(name: "Moisturizer", timeOfDay: .morning, order: 2),
            SkincareStep(name: "SPF", timeOfDay: .morning, order: 3),
            SkincareStep(name: "Cleanser", timeOfDay: .evening, order: 0),
            SkincareStep(name: "Toner", timeOfDay: .evening, order: 1),
            SkincareStep(name: "Moisturizer", timeOfDay: .evening, order: 2),
        ]
    }

    // MARK: - Companion

    static func companionMessages() -> [CompanionMessage] {
        [
            CompanionMessage(role: .assistant, text: "Hi Nirupam. I am here whenever you want to talk, reflect, or just check in. How are you feeling today?", createdAt: Date().adding(days: 0))
        ]
    }

    static func crisisResources() -> [CrisisResource] {
        [
            CrisisResource(name: "988 Suicide and Crisis Lifeline", detail: "Call or text 988, 24/7 (US and Canada)", callNumber: "988", textNumber: "988"),
            CrisisResource(name: "Emergency services", detail: "If you are in immediate danger", callNumber: "911", textNumber: nil),
        ]
    }
}
