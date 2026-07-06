//
//  NutritionModels.swift
//  Wellness App
//
//  Food diary entries plus reusable custom foods and recipes.
//

import Foundation

// nonisolated so its `+` operator and `.zero` can be used from nonisolated
// contexts (e.g. passed to reduce), under the project's main-actor-by-default
// isolation. It is a pure value type with no shared state.
nonisolated struct MacroBreakdown: Codable, Equatable {
    var calories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double

    static let zero = MacroBreakdown(calories: 0, proteinG: 0, carbsG: 0, fatG: 0)

    static func + (lhs: MacroBreakdown, rhs: MacroBreakdown) -> MacroBreakdown {
        MacroBreakdown(
            calories: lhs.calories + rhs.calories,
            proteinG: lhs.proteinG + rhs.proteinG,
            carbsG: lhs.carbsG + rhs.carbsG,
            fatG: lhs.fatG + rhs.fatG
        )
    }

    /// Macros multiplied by a factor (e.g. a portion size), rounded sensibly.
    func scaled(_ factor: Double) -> MacroBreakdown {
        MacroBreakdown(
            calories: Int((Double(calories) * factor).rounded()),
            proteinG: (proteinG * factor * 10).rounded() / 10,
            carbsG: (carbsG * factor * 10).rounded() / 10,
            fatG: (fatG * factor * 10).rounded() / 10
        )
    }
}

struct FoodEntry: Codable, Identifiable {
    var id: String
    var name: String
    var mealType: MealType
    var servings: Double
    var calories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var loggedAt: Date
    var source: EntrySource

    init(
        id: String = UUID().uuidString,
        name: String,
        mealType: MealType,
        servings: Double = 1,
        calories: Int,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        loggedAt: Date = Date(),
        source: EntrySource = .manual
    ) {
        self.id = id
        self.name = name
        self.mealType = mealType
        self.servings = servings
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.loggedAt = loggedAt
        self.source = source
    }

    /// Macros scaled by the number of servings.
    var totals: MacroBreakdown {
        MacroBreakdown(
            calories: Int(Double(calories) * servings),
            proteinG: proteinG * servings,
            carbsG: carbsG * servings,
            fatG: fatG * servings
        )
    }
}

/// A saved food the user can reuse (per single serving values).
struct CustomFood: Codable, Identifiable {
    var id: String
    var name: String
    var calories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var isFavorite: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        calories: Int,
        proteinG: Double,
        carbsG: Double,
        fatG: Double,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.isFavorite = isFavorite
    }
}

/// A recipe built from ingredients, loggable as a single item.
struct Recipe: Codable, Identifiable {
    var id: String
    var name: String
    var servings: Int
    var ingredients: [RecipeIngredient]

    init(id: String = UUID().uuidString, name: String, servings: Int = 1, ingredients: [RecipeIngredient] = []) {
        self.id = id
        self.name = name
        self.servings = servings
        self.ingredients = ingredients
    }

    /// Per-serving macros across all ingredients.
    var perServing: MacroBreakdown {
        let total = ingredients.reduce(MacroBreakdown.zero) { $0 + $1.macros }
        let s = max(servings, 1)
        return MacroBreakdown(
            calories: total.calories / s,
            proteinG: total.proteinG / Double(s),
            carbsG: total.carbsG / Double(s),
            fatG: total.fatG / Double(s)
        )
    }
}

struct RecipeIngredient: Codable, Identifiable {
    var id: String
    var name: String
    var macros: MacroBreakdown

    init(id: String = UUID().uuidString, name: String, macros: MacroBreakdown) {
        self.id = id
        self.name = name
        self.macros = macros
    }
}
