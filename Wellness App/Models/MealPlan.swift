//
//  MealPlan.swift
//  Wellness App
//
//  Generates day and week meal plans from the built-in meal library, filtered
//  by the user's diet preference and aimed at a calorie target, with meal times
//  and an optional intermittent-fasting window. Suggestions are approximate and
//  a starting point, not medical or dietetic advice.
//

import Foundation

// MARK: - Diet suitability

extension LibraryMeal {
    /// A best-effort check of whether a library meal fits a diet, using the
    /// dish name plus, for keto, its carbohydrate load.
    func suits(_ diet: DietType) -> Bool {
        let n = name.lowercased()
        let contains: ([String]) -> Bool = { words in words.contains { n.contains($0) } }

        let meat = ["chicken", "beef", "pork", "lamb", "bacon", "ham", "sausage",
                    "steak", "turkey", "duck", "rib", "meatloaf", "burger", "gyro",
                    "kebab", "shawarma", "bolognese", "pepperoni", "jerk", "banger",
                    "tonkatsu", "bulgogi", "teriyaki", "wing", "kung pao", "tso",
                    "hot dog", "banh mi", "carne", "parmesan chicken", "buffalo",
                    "meat", "tandoori", "biryani", "moussaka", "souvlaki", "bourguignon"]
        let fish = ["fish", "salmon", "tuna", "shrimp", "sushi", "sashimi",
                    "seafood", "paella", "laksa", "pho"]
        let dairyEgg = ["cheese", "alfredo", "parmesan", "butter", "cream", "paneer",
                        "yogurt", "milk", "quiche", "mac and cheese", "pizza",
                        "lasagna", "risotto", "gnocchi", "crepe", "pancake", "donut",
                        "muffin", "ice cream", "omelet", "egg", "quesadilla",
                        "nachos", "gratin", "baklava"]

        let hasMeat = contains(meat)
        let hasFish = contains(fish)
        let hasDairyEgg = contains(dairyEgg)

        switch diet {
        case .none, .other:
            return true
        case .vegetarian:
            return !hasMeat && !hasFish
        case .pescatarian:
            return !hasMeat
        case .vegan:
            return !hasMeat && !hasFish && !hasDairyEgg
        case .keto:
            return perServing.carbsG <= 20
        }
    }
}

// MARK: - Plan models

struct PlannedMeal: Identifiable {
    let id = UUID()
    let slot: MealType
    let time: DateComponents   // hour/minute of day
    let meal: LibraryMeal
    let servings: Double

    var macros: MacroBreakdown { meal.macros(servings: servings) }

    var timeText: String {
        let h = time.hour ?? 0, m = time.minute ?? 0
        let period = h < 12 ? "AM" : "PM"
        let hour12 = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", hour12, m, period)
    }
}

struct DayPlan: Identifiable {
    let id = UUID()
    let dayIndex: Int          // 0 = today / day 1
    var meals: [PlannedMeal]

    var totalCalories: Int { meals.reduce(0) { $0 + $1.macros.calories } }
    var totalMacros: MacroBreakdown { meals.reduce(.zero) { $0 + $1.macros } }
}

// MARK: - Generator

enum MealPlanGenerator {
    /// Slot definitions: meal type, share of the day's calories, and default time.
    private struct Slot {
        let type: MealType
        let share: Double
        let hour: Int
        let minute: Int
    }

    private static func slots(mealsPerDay: Int, fasting: Bool) -> [Slot] {
        if mealsPerDay >= 4 {
            return fasting
                ? [Slot(type: .lunch, share: 0.35, hour: 12, minute: 0),
                   Slot(type: .snacks, share: 0.15, hour: 15, minute: 0),
                   Slot(type: .dinner, share: 0.35, hour: 18, minute: 30),
                   Slot(type: .snacks, share: 0.15, hour: 20, minute: 0)]
                : [Slot(type: .breakfast, share: 0.25, hour: 8, minute: 0),
                   Slot(type: .lunch, share: 0.30, hour: 12, minute: 30),
                   Slot(type: .snacks, share: 0.15, hour: 16, minute: 0),
                   Slot(type: .dinner, share: 0.30, hour: 19, minute: 0)]
        }
        return fasting
            ? [Slot(type: .lunch, share: 0.40, hour: 12, minute: 0),
               Slot(type: .snacks, share: 0.20, hour: 16, minute: 0),
               Slot(type: .dinner, share: 0.40, hour: 19, minute: 30)]
            : [Slot(type: .breakfast, share: 0.30, hour: 8, minute: 0),
               Slot(type: .lunch, share: 0.35, hour: 12, minute: 30),
               Slot(type: .dinner, share: 0.35, hour: 19, minute: 0)]
    }

    /// Breakfast-appropriate library meals, so plans don't suggest curry at 8am.
    private static func breakfastPool(_ pool: [LibraryMeal]) -> [LibraryMeal] {
        let breakfasty = ["pancake", "egg", "croissant", "bagel", "oat", "toast",
                          "breakfast", "muffin", "crepe", "smoothie", "yogurt"]
        let filtered = pool.filter { m in breakfasty.contains { m.name.lowercased().contains($0) } }
        return filtered.isEmpty ? pool : filtered
    }

    static func day(dayIndex: Int, diet: DietType, targetCalories: Int, mealsPerDay: Int, fasting: Bool) -> DayPlan {
        let pool = FoodLibrary.meals.filter { $0.suits(diet) }
        let usable = pool.isEmpty ? FoodLibrary.meals : pool
        let calorieTarget = max(1000, targetCalories)

        var meals: [PlannedMeal] = []
        for slot in slots(mealsPerDay: mealsPerDay, fasting: fasting) {
            let slotCalories = calorieTarget * Int(slot.share * 100) / 100
            let candidates = slot.type == .breakfast ? breakfastPool(usable) : usable
            guard let meal = pick(from: candidates, near: slotCalories) else { continue }
            // Scale servings toward the slot calorie goal (0.5x–2x).
            let base = max(1, meal.perServing.calories)
            let servings = min(2.0, max(0.5, (Double(slotCalories) / Double(base)).rounded(toPlaces: 1)))
            meals.append(PlannedMeal(
                slot: slot.type,
                time: DateComponents(hour: slot.hour, minute: slot.minute),
                meal: meal,
                servings: servings
            ))
        }
        return DayPlan(dayIndex: dayIndex, meals: meals)
    }

    static func week(diet: DietType, targetCalories: Int, mealsPerDay: Int, fasting: Bool) -> [DayPlan] {
        (0..<7).map { day(dayIndex: $0, diet: diet, targetCalories: targetCalories, mealsPerDay: mealsPerDay, fasting: fasting) }
    }

    /// Pick a meal whose calories are reasonably close to the target, with some
    /// variety so regenerating gives a different plan.
    private static func pick(from pool: [LibraryMeal], near calories: Int) -> LibraryMeal? {
        guard !pool.isEmpty else { return nil }
        let ranked = pool.sorted { abs($0.perServing.calories - calories) < abs($1.perServing.calories - calories) }
        let top = Array(ranked.prefix(6))
        return top.randomElement()
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let p = pow(10.0, Double(places))
        return (self * p).rounded() / p
    }
}
