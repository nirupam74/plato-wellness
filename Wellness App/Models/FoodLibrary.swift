//
//  FoodLibrary.swift
//  Wellness App
//
//  A built-in catalogue of common ingredients (with per-100g macros and several
//  portion units) and popular prepared meals grouped by cuisine. Ingredients let
//  people build meals from parts and scale macros by portion; meals give a quick
//  one-tap log. All values are approximate reference figures.
//

import Foundation

// MARK: - Groupings

enum FoodGroup: String, CaseIterable, Identifiable {
    case vegetables, fruits, meats, dairy, grains, legumesNuts, pantry
    var id: String { rawValue }
    var label: String {
        switch self {
        case .vegetables: "Vegetables"
        case .fruits:     "Fruits"
        case .meats:      "Meats & protein"
        case .dairy:      "Dairy & eggs"
        case .grains:     "Grains & bread"
        case .legumesNuts:"Legumes & nuts"
        case .pantry:     "Pantry"
        }
    }
    var systemImage: String {
        switch self {
        case .vegetables: "carrot.fill"
        case .fruits:     "apple.logo"
        case .meats:      "fish.fill"
        case .dairy:      "drop.fill"
        case .grains:     "birthday.cake.fill"
        case .legumesNuts:"leaf.fill"
        case .pantry:     "takeoutbag.and.cup.and.straw.fill"
        }
    }
}

enum Cuisine: String, CaseIterable, Identifiable {
    case italian, mexican, american, indian, asian, mediterranean
    var id: String { rawValue }
    var label: String {
        switch self {
        case .italian:       "Italian"
        case .mexican:       "Mexican"
        case .american:      "American"
        case .indian:        "Indian"
        case .asian:         "Asian"
        case .mediterranean: "Mediterranean"
        }
    }
    var systemImage: String {
        switch self {
        case .italian:       "fork.knife"
        case .mexican:       "flame.fill"
        case .american:      "takeoutbag.and.cup.and.straw.fill"
        case .indian:        "cup.and.saucer.fill"
        case .asian:         "bowl.fill"
        case .mediterranean: "leaf.fill"
        }
    }
}

// MARK: - Portion units

enum PortionUnit: String, CaseIterable, Identifiable {
    case gram, ounce, cup, tablespoon, teaspoon, slice, piece, milliliter
    var id: String { rawValue }
    var label: String {
        switch self {
        case .gram:       "grams"
        case .ounce:      "ounces"
        case .cup:        "cups"
        case .tablespoon: "tablespoons"
        case .teaspoon:   "teaspoons"
        case .slice:      "slices"
        case .piece:      "pieces"
        case .milliliter: "millilitres"
        }
    }
    var short: String {
        switch self {
        case .gram:       "g"
        case .ounce:      "oz"
        case .cup:        "cup"
        case .tablespoon: "tbsp"
        case .teaspoon:   "tsp"
        case .slice:      "slice"
        case .piece:      "pc"
        case .milliliter: "ml"
        }
    }
}

// MARK: - Ingredient

struct LibraryIngredient: Identifiable {
    let id: String
    let name: String
    let group: FoodGroup
    let per100g: MacroBreakdown
    /// Grams in one of each supported unit (gram and ounce always included).
    let unitGrams: [PortionUnit: Double]

    init(_ name: String, _ group: FoodGroup, _ kcal: Int, _ p: Double, _ c: Double, _ f: Double,
         units: [PortionUnit: Double] = [:]) {
        self.id = "ing." + name.lowercased().replacingOccurrences(of: " ", with: "-")
        self.name = name
        self.group = group
        self.per100g = MacroBreakdown(calories: kcal, proteinG: p, carbsG: c, fatG: f)
        var u: [PortionUnit: Double] = [.gram: 1, .ounce: 28.3495]
        for (unit, grams) in units { u[unit] = grams }
        self.unitGrams = u
    }

    /// Supported units in a sensible display order.
    var units: [PortionUnit] {
        let order: [PortionUnit] = [.piece, .slice, .cup, .tablespoon, .teaspoon, .gram, .ounce, .milliliter]
        return order.filter { unitGrams[$0] != nil }
    }

    var defaultUnit: PortionUnit {
        if unitGrams[.piece] != nil { return .piece }
        if unitGrams[.slice] != nil { return .slice }
        return .gram
    }

    func macros(quantity: Double, unit: PortionUnit) -> MacroBreakdown {
        let grams = quantity * (unitGrams[unit] ?? 1)
        return per100g.scaled(grams / 100)
    }
}

// MARK: - Meal

struct LibraryMeal: Identifiable {
    let id: String
    let name: String
    let cuisine: Cuisine
    let servingLabel: String
    let perServing: MacroBreakdown

    init(_ name: String, _ cuisine: Cuisine, _ serving: String, _ kcal: Int, _ p: Double, _ c: Double, _ f: Double) {
        self.id = "meal." + name.lowercased().replacingOccurrences(of: " ", with: "-")
        self.name = name
        self.cuisine = cuisine
        self.servingLabel = serving
        self.perServing = MacroBreakdown(calories: kcal, proteinG: p, carbsG: c, fatG: f)
    }

    func macros(servings: Double) -> MacroBreakdown { perServing.scaled(servings) }
}

// MARK: - Data

enum FoodLibrary {
    static func ingredients(in group: FoodGroup) -> [LibraryIngredient] {
        ingredients.filter { $0.group == group }
    }
    static func meals(in cuisine: Cuisine) -> [LibraryMeal] {
        meals.filter { $0.cuisine == cuisine }
    }

    // Per-100g macros. Piece/cup/slice grams are typical portions.
    static let ingredients: [LibraryIngredient] = [
        // Vegetables
        .init("Broccoli", .vegetables, 34, 2.8, 7, 0.4, units: [.cup: 91]),
        .init("Carrot", .vegetables, 41, 0.9, 10, 0.2, units: [.piece: 61, .cup: 128]),
        .init("Spinach", .vegetables, 23, 2.9, 3.6, 0.4, units: [.cup: 30]),
        .init("Tomato", .vegetables, 18, 0.9, 3.9, 0.2, units: [.piece: 123, .cup: 180]),
        .init("Potato", .vegetables, 77, 2, 17, 0.1, units: [.piece: 173, .cup: 150]),
        .init("Sweet potato", .vegetables, 86, 1.6, 20, 0.1, units: [.piece: 130, .cup: 200]),
        .init("Onion", .vegetables, 40, 1.1, 9, 0.1, units: [.piece: 110, .cup: 160]),
        .init("Bell pepper", .vegetables, 31, 1, 6, 0.3, units: [.piece: 119, .cup: 149]),
        .init("Cucumber", .vegetables, 15, 0.7, 3.6, 0.1, units: [.cup: 119]),
        .init("Lettuce", .vegetables, 15, 1.4, 2.9, 0.2, units: [.cup: 47]),
        .init("Corn", .vegetables, 86, 3.3, 19, 1.4, units: [.cup: 145]),
        .init("Green peas", .vegetables, 81, 5.4, 14, 0.4, units: [.cup: 145]),
        .init("Mushroom", .vegetables, 22, 3.1, 3.3, 0.3, units: [.cup: 70]),
        // Fruits
        .init("Apple", .fruits, 52, 0.3, 14, 0.2, units: [.piece: 182, .cup: 125]),
        .init("Banana", .fruits, 89, 1.1, 23, 0.3, units: [.piece: 118]),
        .init("Orange", .fruits, 47, 0.9, 12, 0.1, units: [.piece: 131]),
        .init("Strawberry", .fruits, 32, 0.7, 7.7, 0.3, units: [.cup: 152]),
        .init("Blueberry", .fruits, 57, 0.7, 14, 0.3, units: [.cup: 148]),
        .init("Grapes", .fruits, 69, 0.7, 18, 0.2, units: [.cup: 151]),
        .init("Mango", .fruits, 60, 0.8, 15, 0.4, units: [.cup: 165, .piece: 200]),
        .init("Pineapple", .fruits, 50, 0.5, 13, 0.1, units: [.cup: 165]),
        .init("Watermelon", .fruits, 30, 0.6, 8, 0.2, units: [.cup: 152]),
        .init("Avocado", .fruits, 160, 2, 9, 15, units: [.piece: 150, .cup: 150]),
        .init("Pear", .fruits, 57, 0.4, 15, 0.1, units: [.piece: 178]),
        .init("Peach", .fruits, 39, 0.9, 10, 0.2, units: [.piece: 150]),
        // Meats & protein
        .init("Chicken breast", .meats, 165, 31, 0, 3.6, units: [.piece: 120]),
        .init("Chicken thigh", .meats, 209, 26, 0, 10.9, units: [.piece: 90]),
        .init("Ground beef", .meats, 250, 26, 0, 15),
        .init("Steak", .meats, 271, 25, 0, 18),
        .init("Pork chop", .meats, 231, 26, 0, 14),
        .init("Salmon", .meats, 208, 20, 0, 13),
        .init("Tuna", .meats, 132, 28, 0, 1.3),
        .init("Shrimp", .meats, 99, 24, 0.2, 0.3),
        .init("Egg", .dairy, 155, 13, 1.1, 11, units: [.piece: 50]),
        .init("Turkey breast", .meats, 135, 30, 0, 1),
        .init("Bacon", .meats, 541, 37, 1.4, 42, units: [.slice: 8]),
        .init("Tofu", .meats, 76, 8, 1.9, 4.8),
        // Dairy
        .init("Whole milk", .dairy, 61, 3.2, 4.8, 3.3, units: [.cup: 244, .milliliter: 1.03]),
        .init("Skim milk", .dairy, 34, 3.4, 5, 0.1, units: [.cup: 245, .milliliter: 1.03]),
        .init("Cheddar cheese", .dairy, 403, 25, 1.3, 33, units: [.slice: 28]),
        .init("Mozzarella", .dairy, 300, 22, 2.2, 22, units: [.slice: 28]),
        .init("Greek yogurt", .dairy, 59, 10, 3.6, 0.4, units: [.cup: 245]),
        .init("Butter", .dairy, 717, 0.9, 0.1, 81, units: [.tablespoon: 14]),
        .init("Cream cheese", .dairy, 342, 6, 4, 34, units: [.tablespoon: 15]),
        .init("Cottage cheese", .dairy, 98, 11, 3.4, 4.3, units: [.cup: 226]),
        // Grains & bread
        .init("White rice", .grains, 130, 2.7, 28, 0.3, units: [.cup: 158]),
        .init("Brown rice", .grains, 123, 2.7, 26, 1, units: [.cup: 195]),
        .init("White bread", .grains, 265, 9, 49, 3.2, units: [.slice: 28]),
        .init("Whole wheat bread", .grains, 247, 13, 41, 3.4, units: [.slice: 28]),
        .init("Pasta", .grains, 131, 5, 25, 1.1, units: [.cup: 140]),
        .init("Oats", .grains, 389, 17, 66, 7, units: [.cup: 81]),
        .init("Quinoa", .grains, 120, 4.4, 21, 1.9, units: [.cup: 185]),
        .init("Flour", .grains, 364, 10, 76, 1, units: [.cup: 125]),
        .init("Tortilla", .grains, 218, 5.7, 36, 5, units: [.piece: 49]),
        .init("Bagel", .grains, 250, 10, 49, 1.5, units: [.piece: 99]),
        .init("Corn flakes", .grains, 357, 7, 84, 0.4, units: [.cup: 28]),
        // Legumes & nuts
        .init("Almonds", .legumesNuts, 579, 21, 22, 50, units: [.cup: 143]),
        .init("Peanut butter", .legumesNuts, 588, 25, 20, 50, units: [.tablespoon: 16]),
        .init("Black beans", .legumesNuts, 132, 8.9, 24, 0.5, units: [.cup: 172]),
        .init("Chickpeas", .legumesNuts, 164, 8.9, 27, 2.6, units: [.cup: 164]),
        .init("Lentils", .legumesNuts, 116, 9, 20, 0.4, units: [.cup: 198]),
        .init("Walnuts", .legumesNuts, 654, 15, 14, 65, units: [.cup: 117]),
        // Pantry
        .init("Olive oil", .pantry, 884, 0, 0, 100, units: [.tablespoon: 14, .teaspoon: 4.5]),
        .init("Honey", .pantry, 304, 0.3, 82, 0, units: [.tablespoon: 21]),
        .init("Sugar", .pantry, 387, 0, 100, 0, units: [.tablespoon: 12, .teaspoon: 4]),
    ]

    static let meals: [LibraryMeal] = [
        // Italian
        .init("Cheese pizza", .italian, "1 slice", 285, 12, 36, 10),
        .init("Pepperoni pizza", .italian, "1 slice", 313, 13, 36, 13),
        .init("Margherita pizza", .italian, "1 slice", 270, 11, 33, 9),
        .init("Spaghetti bolognese", .italian, "1 plate", 670, 28, 80, 25),
        .init("Lasagna", .italian, "1 piece", 408, 26, 30, 20),
        .init("Fettuccine alfredo", .italian, "1 plate", 800, 20, 90, 38),
        .init("Risotto", .italian, "1 bowl", 430, 10, 60, 15),
        // Mexican
        .init("Beef taco", .mexican, "1 taco", 210, 9, 15, 12),
        .init("Chicken burrito", .mexican, "1 burrito", 580, 30, 60, 22),
        .init("Quesadilla", .mexican, "1 quesadilla", 500, 22, 40, 26),
        .init("Nachos", .mexican, "1 plate", 560, 15, 60, 30),
        .init("Beef enchiladas", .mexican, "2 pieces", 640, 25, 50, 35),
        .init("Guacamole", .mexican, "1/2 cup", 200, 3, 10, 18),
        // American
        .init("Cheeseburger", .american, "1 burger", 303, 15, 32, 14),
        .init("Double cheeseburger", .american, "1 burger", 445, 25, 34, 25),
        .init("Hot dog", .american, "1 hot dog", 290, 10, 23, 18),
        .init("French fries", .american, "medium", 365, 4, 48, 17),
        .init("Mac and cheese", .american, "1 cup", 310, 11, 44, 12),
        .init("Fried chicken", .american, "1 piece", 320, 21, 8, 20),
        .init("BBQ ribs", .american, "1 serving", 500, 30, 15, 35),
        // Indian
        .init("Butter chicken", .indian, "1 bowl", 490, 30, 15, 33),
        .init("Chicken biryani", .indian, "1 plate", 600, 25, 80, 20),
        .init("Naan", .indian, "1 piece", 260, 9, 45, 5),
        .init("Samosa", .indian, "1 piece", 260, 4, 30, 14),
        .init("Palak paneer", .indian, "1 bowl", 350, 14, 15, 27),
        .init("Chana masala", .indian, "1 bowl", 300, 12, 45, 8),
        // Asian
        .init("Fried rice", .asian, "1 plate", 530, 12, 80, 18),
        .init("Pad thai", .asian, "1 plate", 600, 20, 75, 25),
        .init("Sushi roll", .asian, "6 pieces", 255, 9, 38, 7),
        .init("Ramen", .asian, "1 bowl", 500, 20, 60, 20),
        .init("Orange chicken", .asian, "1 serving", 490, 20, 50, 24),
        .init("Dumplings", .asian, "6 pieces", 300, 12, 35, 12),
        // Mediterranean
        .init("Greek salad", .mediterranean, "1 bowl", 230, 6, 12, 18),
        .init("Falafel", .mediterranean, "4 pieces", 340, 13, 32, 18),
        .init("Hummus", .mediterranean, "1/4 cup", 100, 3, 8, 6),
        .init("Shawarma wrap", .mediterranean, "1 wrap", 620, 35, 50, 30),
        .init("Gyro", .mediterranean, "1 gyro", 590, 30, 45, 32),
    ]
}
