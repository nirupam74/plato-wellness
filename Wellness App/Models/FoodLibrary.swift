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
    case vegetables, fruits, meats, seafood, dairy, grains, legumesNuts
    case saucesCondiments, spicesHerbs, oilsFats, beverages, snacksSweets, pantry
    var id: String { rawValue }
    var label: String {
        switch self {
        case .vegetables:      "Vegetables"
        case .fruits:          "Fruits"
        case .meats:           "Meats & poultry"
        case .seafood:         "Seafood"
        case .dairy:           "Dairy & eggs"
        case .grains:          "Grains & bread"
        case .legumesNuts:     "Legumes & nuts"
        case .saucesCondiments:"Sauces & condiments"
        case .spicesHerbs:     "Spices & herbs"
        case .oilsFats:        "Oils & fats"
        case .beverages:       "Beverages"
        case .snacksSweets:    "Snacks & sweets"
        case .pantry:          "Pantry & baking"
        }
    }
    var systemImage: String {
        switch self {
        case .vegetables:      "carrot.fill"
        case .fruits:          "apple.logo"
        case .meats:           "fork.knife"
        case .seafood:         "fish.fill"
        case .dairy:           "drop.fill"
        case .grains:          "birthday.cake.fill"
        case .legumesNuts:     "leaf.fill"
        case .saucesCondiments:"drop.triangle.fill"
        case .spicesHerbs:     "leaf.circle.fill"
        case .oilsFats:        "drop.fill"
        case .beverages:       "cup.and.saucer.fill"
        case .snacksSweets:    "birthday.cake.fill"
        case .pantry:          "takeoutbag.and.cup.and.straw.fill"
        }
    }
}

enum Cuisine: String, CaseIterable, Identifiable {
    case italian, mexican, american, indian, chinese, japanese, thai
    case greek, mediterranean, french, spanish, korean, vietnamese
    case middleEastern, caribbean, british, asian
    var id: String { rawValue }
    var label: String {
        switch self {
        case .italian:       "Italian"
        case .mexican:       "Mexican"
        case .american:      "American"
        case .indian:        "Indian"
        case .chinese:       "Chinese"
        case .japanese:      "Japanese"
        case .thai:          "Thai"
        case .greek:         "Greek"
        case .mediterranean: "Mediterranean"
        case .french:        "French"
        case .spanish:       "Spanish"
        case .korean:        "Korean"
        case .vietnamese:    "Vietnamese"
        case .middleEastern: "Middle Eastern"
        case .caribbean:     "Caribbean"
        case .british:       "British"
        case .asian:         "Other Asian"
        }
    }
    var systemImage: String {
        switch self {
        case .italian:       "fork.knife"
        case .mexican:       "flame.fill"
        case .american:      "takeoutbag.and.cup.and.straw.fill"
        case .indian:        "cup.and.saucer.fill"
        case .chinese:       "bowl.fill"
        case .japanese:      "fish.fill"
        case .thai:          "leaf.fill"
        case .greek:         "leaf.circle.fill"
        case .mediterranean: "leaf.fill"
        case .french:        "birthday.cake.fill"
        case .spanish:       "flame.fill"
        case .korean:        "bowl.fill"
        case .vietnamese:    "bowl.fill"
        case .middleEastern: "cup.and.saucer.fill"
        case .caribbean:     "sun.max.fill"
        case .british:       "cup.and.saucer.fill"
        case .asian:         "bowl.fill"
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
        .init("Honey", .pantry, 304, 0.3, 82, 0, units: [.tablespoon: 21]),
        .init("Sugar", .pantry, 387, 0, 100, 0, units: [.tablespoon: 12, .teaspoon: 4]),
        .init("Maple syrup", .pantry, 260, 0, 67, 0.1, units: [.tablespoon: 20]),
        .init("Baking flour", .pantry, 364, 10, 76, 1, units: [.cup: 125]),
        .init("Cocoa powder", .pantry, 228, 20, 58, 14, units: [.tablespoon: 5]),

        // More vegetables
        .init("Broccolini", .vegetables, 35, 3, 6, 0.4, units: [.cup: 90]),
        .init("Cauliflower", .vegetables, 25, 1.9, 5, 0.3, units: [.cup: 107]),
        .init("Zucchini", .vegetables, 17, 1.2, 3.1, 0.3, units: [.piece: 196, .cup: 124]),
        .init("Green beans", .vegetables, 31, 1.8, 7, 0.2, units: [.cup: 110]),
        .init("Asparagus", .vegetables, 20, 2.2, 3.9, 0.1, units: [.cup: 134]),
        .init("Kale", .vegetables, 49, 4.3, 9, 0.9, units: [.cup: 67]),
        .init("Celery", .vegetables, 16, 0.7, 3, 0.2, units: [.piece: 40, .cup: 101]),
        .init("Garlic", .vegetables, 149, 6.4, 33, 0.5, units: [.teaspoon: 3]),
        .init("Eggplant", .vegetables, 25, 1, 6, 0.2, units: [.cup: 82]),
        .init("Beetroot", .vegetables, 43, 1.6, 10, 0.2, units: [.cup: 136]),
        // More fruits
        .init("Raspberry", .fruits, 52, 1.2, 12, 0.7, units: [.cup: 123]),
        .init("Blackberry", .fruits, 43, 1.4, 10, 0.5, units: [.cup: 144]),
        .init("Kiwi", .fruits, 61, 1.1, 15, 0.5, units: [.piece: 69]),
        .init("Cherry", .fruits, 63, 1.1, 16, 0.2, units: [.cup: 154]),
        .init("Lemon", .fruits, 29, 1.1, 9, 0.3, units: [.piece: 84]),
        .init("Grapefruit", .fruits, 42, 0.8, 11, 0.1, units: [.piece: 246]),
        .init("Cantaloupe", .fruits, 34, 0.8, 8, 0.2, units: [.cup: 156]),
        .init("Dates", .fruits, 277, 1.8, 75, 0.2, units: [.piece: 24]),
        .init("Raisins", .fruits, 299, 3.1, 79, 0.5, units: [.tablespoon: 9]),
        // Seafood
        .init("Cod", .seafood, 82, 18, 0, 0.7),
        .init("Tilapia", .seafood, 96, 20, 0, 1.7),
        .init("Crab", .seafood, 97, 19, 0, 1.5),
        .init("Lobster", .seafood, 89, 19, 0, 0.9),
        .init("Sardines", .seafood, 208, 25, 0, 11),
        .init("Mackerel", .seafood, 205, 19, 0, 14),
        .init("Scallops", .seafood, 111, 21, 5, 0.8),
        .init("Oysters", .seafood, 81, 9, 5, 2.3),
        // More meats
        .init("Lamb", .meats, 294, 25, 0, 21),
        .init("Ham", .meats, 145, 21, 1.5, 6, units: [.slice: 28]),
        .init("Sausage", .meats, 301, 12, 2, 27, units: [.piece: 75]),
        .init("Ground turkey", .meats, 189, 27, 0, 8),
        .init("Duck", .meats, 337, 19, 0, 28),
        .init("Chicken wing", .meats, 203, 30, 0, 8, units: [.piece: 34]),
        .init("Beef jerky", .meats, 410, 33, 11, 26, units: [.ounce: 28.35]),
        // More dairy
        .init("Parmesan", .dairy, 431, 38, 4, 29, units: [.tablespoon: 5]),
        .init("Feta cheese", .dairy, 264, 14, 4, 21, units: [.ounce: 28.35]),
        .init("Swiss cheese", .dairy, 380, 27, 5, 28, units: [.slice: 28]),
        .init("Sour cream", .dairy, 198, 2.4, 4.6, 19, units: [.tablespoon: 12]),
        .init("Heavy cream", .dairy, 340, 2.8, 2.8, 36, units: [.tablespoon: 15]),
        .init("Ice cream", .snacksSweets, 207, 3.5, 24, 11, units: [.cup: 132]),
        .init("Egg white", .dairy, 52, 11, 0.7, 0.2, units: [.piece: 33]),
        // More grains
        .init("Couscous", .grains, 112, 3.8, 23, 0.2, units: [.cup: 157]),
        .init("Naan bread", .grains, 310, 9, 52, 7, units: [.piece: 90]),
        .init("Croissant", .grains, 406, 8, 46, 21, units: [.piece: 57]),
        .init("Pancake", .grains, 227, 6, 28, 10, units: [.piece: 77]),
        .init("Pita bread", .grains, 275, 9, 55, 1.2, units: [.piece: 60]),
        .init("Cornmeal", .grains, 384, 9, 79, 4, units: [.cup: 122]),
        .init("Ramen noodles", .grains, 436, 10, 63, 16, units: [.piece: 85]),
        // More legumes & nuts
        .init("Cashews", .legumesNuts, 553, 18, 30, 44, units: [.ounce: 28.35]),
        .init("Pistachios", .legumesNuts, 560, 20, 28, 45, units: [.ounce: 28.35]),
        .init("Kidney beans", .legumesNuts, 127, 8.7, 23, 0.5, units: [.cup: 177]),
        .init("Edamame", .legumesNuts, 121, 12, 9, 5, units: [.cup: 155]),
        .init("Chia seeds", .legumesNuts, 486, 17, 42, 31, units: [.tablespoon: 12]),
        .init("Sunflower seeds", .legumesNuts, 584, 21, 20, 51, units: [.ounce: 28.35]),
        // Sauces & condiments
        .init("Ketchup", .saucesCondiments, 101, 1.7, 26, 0.1, units: [.tablespoon: 17]),
        .init("Mayonnaise", .saucesCondiments, 680, 1, 0.6, 75, units: [.tablespoon: 14]),
        .init("Mustard", .saucesCondiments, 66, 4, 5, 4, units: [.teaspoon: 5]),
        .init("Soy sauce", .saucesCondiments, 53, 8, 5, 0.6, units: [.tablespoon: 16]),
        .init("Barbecue sauce", .saucesCondiments, 172, 0.8, 41, 0.6, units: [.tablespoon: 17]),
        .init("Sriracha", .saucesCondiments, 93, 2, 19, 0.9, units: [.teaspoon: 5]),
        .init("Ranch dressing", .saucesCondiments, 430, 1, 6, 45, units: [.tablespoon: 15]),
        .init("Marinara sauce", .saucesCondiments, 56, 1.5, 9, 1.6, units: [.cup: 245]),
        .init("Pesto", .saucesCondiments, 418, 6, 6, 41, units: [.tablespoon: 16]),
        .init("Hot sauce", .saucesCondiments, 11, 0.5, 1.8, 0.4, units: [.teaspoon: 5]),
        .init("Salsa", .saucesCondiments, 36, 1.5, 7, 0.2, units: [.tablespoon: 16]),
        .init("Honey mustard", .saucesCondiments, 340, 2, 30, 24, units: [.tablespoon: 15]),
        // Spices & herbs
        .init("Salt", .spicesHerbs, 0, 0, 0, 0, units: [.teaspoon: 6]),
        .init("Black pepper", .spicesHerbs, 251, 10, 64, 3.3, units: [.teaspoon: 2.3]),
        .init("Cinnamon", .spicesHerbs, 247, 4, 81, 1.2, units: [.teaspoon: 2.6]),
        .init("Paprika", .spicesHerbs, 282, 14, 54, 13, units: [.teaspoon: 2.3]),
        .init("Cumin", .spicesHerbs, 375, 18, 44, 22, units: [.teaspoon: 2.1]),
        .init("Turmeric", .spicesHerbs, 312, 10, 67, 3.3, units: [.teaspoon: 3]),
        .init("Chili powder", .spicesHerbs, 282, 13, 50, 14, units: [.teaspoon: 2.7]),
        .init("Oregano", .spicesHerbs, 265, 9, 69, 4.3, units: [.teaspoon: 1]),
        .init("Basil", .spicesHerbs, 23, 3.2, 2.7, 0.6, units: [.tablespoon: 2.7]),
        .init("Garlic powder", .spicesHerbs, 331, 17, 73, 0.7, units: [.teaspoon: 3.1]),
        .init("Ginger", .spicesHerbs, 80, 1.8, 18, 0.8, units: [.teaspoon: 2.4]),
        // Oils & fats
        .init("Olive oil", .oilsFats, 884, 0, 0, 100, units: [.tablespoon: 14, .teaspoon: 4.5]),
        .init("Vegetable oil", .oilsFats, 884, 0, 0, 100, units: [.tablespoon: 14]),
        .init("Coconut oil", .oilsFats, 862, 0, 0, 100, units: [.tablespoon: 14]),
        .init("Ghee", .oilsFats, 900, 0, 0, 100, units: [.tablespoon: 13]),
        .init("Margarine", .oilsFats, 717, 0.2, 0.7, 81, units: [.tablespoon: 14]),
        // Beverages
        .init("Orange juice", .beverages, 45, 0.7, 10, 0.2, units: [.cup: 248, .milliliter: 1.03]),
        .init("Apple juice", .beverages, 46, 0.1, 11, 0.1, units: [.cup: 248, .milliliter: 1.04]),
        .init("Coca-Cola", .beverages, 42, 0, 11, 0, units: [.cup: 240, .milliliter: 1.03]),
        .init("Beer", .beverages, 43, 0.5, 3.6, 0, units: [.milliliter: 1.01]),
        .init("Red wine", .beverages, 85, 0.1, 2.6, 0, units: [.milliliter: 0.99]),
        .init("Coffee (black)", .beverages, 1, 0.1, 0, 0, units: [.cup: 237, .milliliter: 1]),
        .init("Almond milk", .beverages, 17, 0.6, 0.6, 1.2, units: [.cup: 240, .milliliter: 1.03]),
        .init("Sports drink", .beverages, 26, 0, 6, 0, units: [.milliliter: 1.04]),
        .init("Protein shake", .beverages, 84, 16, 3, 1.5, units: [.milliliter: 1.04]),
        .init("Energy drink", .beverages, 45, 0, 11, 0, units: [.milliliter: 1.04]),
        // Snacks & sweets (incl. common branded)
        .init("Potato chips", .snacksSweets, 536, 7, 53, 35, units: [.ounce: 28.35]),
        .init("Chocolate bar", .snacksSweets, 546, 7.6, 61, 31, units: [.ounce: 28.35]),
        .init("Nutella", .snacksSweets, 539, 6, 57, 31, units: [.tablespoon: 20]),
        .init("Oreo cookie", .snacksSweets, 480, 5, 71, 20, units: [.piece: 11]),
        .init("Granola bar", .snacksSweets, 471, 8, 64, 20, units: [.piece: 42]),
        .init("Popcorn", .snacksSweets, 387, 12, 78, 4.5, units: [.cup: 8]),
        .init("Pretzels", .snacksSweets, 380, 10, 80, 3, units: [.ounce: 28.35]),
        .init("Donut", .snacksSweets, 452, 5, 51, 25, units: [.piece: 60]),
        .init("Muffin", .snacksSweets, 377, 6, 55, 15, units: [.piece: 113]),
        .init("Gummy bears", .snacksSweets, 325, 6.9, 77, 0.2, units: [.ounce: 28.35]),
        .init("Dark chocolate", .snacksSweets, 598, 7.8, 46, 43, units: [.ounce: 28.35]),
        .init("Protein bar", .snacksSweets, 350, 30, 38, 10, units: [.piece: 60]),
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
        .init("Tabbouleh", .mediterranean, "1 bowl", 190, 4, 22, 11),
        // More Italian
        .init("Ravioli", .italian, "1 plate", 500, 20, 60, 20),
        .init("Gnocchi", .italian, "1 plate", 450, 12, 75, 11),
        .init("Chicken parmesan", .italian, "1 serving", 620, 40, 40, 33),
        .init("Minestrone soup", .italian, "1 bowl", 220, 10, 34, 6),
        .init("Bruschetta", .italian, "2 pieces", 200, 5, 27, 8),
        // More American
        .init("Pancakes", .american, "3 pancakes", 350, 8, 55, 10),
        .init("Scrambled eggs", .american, "2 eggs", 180, 12, 2, 14),
        .init("Caesar salad", .american, "1 bowl", 480, 10, 20, 40),
        .init("Buffalo wings", .american, "6 wings", 540, 42, 6, 38),
        .init("Grilled cheese", .american, "1 sandwich", 400, 14, 33, 24),
        .init("Club sandwich", .american, "1 sandwich", 590, 34, 40, 32),
        .init("Meatloaf", .american, "1 slice", 290, 20, 12, 18),
        // Chinese
        .init("Kung pao chicken", .chinese, "1 serving", 430, 27, 20, 27),
        .init("Sweet and sour pork", .chinese, "1 serving", 500, 20, 55, 22),
        .init("Beef and broccoli", .chinese, "1 serving", 420, 30, 20, 24),
        .init("Chow mein", .chinese, "1 plate", 510, 18, 66, 20),
        .init("Spring rolls", .chinese, "2 rolls", 240, 6, 30, 11),
        .init("General Tso's chicken", .chinese, "1 serving", 620, 26, 62, 30),
        .init("Wonton soup", .chinese, "1 bowl", 190, 12, 24, 5),
        // Japanese
        .init("Chicken teriyaki", .japanese, "1 serving", 460, 34, 40, 16),
        .init("Tonkatsu", .japanese, "1 serving", 550, 28, 40, 30),
        .init("Miso soup", .japanese, "1 bowl", 84, 6, 8, 3),
        .init("Udon noodles", .japanese, "1 bowl", 380, 12, 70, 5),
        .init("Sashimi", .japanese, "6 pieces", 175, 30, 0, 6),
        .init("Gyoza", .japanese, "6 pieces", 275, 11, 30, 12),
        // Thai
        .init("Green curry", .thai, "1 bowl", 450, 20, 25, 30),
        .init("Tom yum soup", .thai, "1 bowl", 150, 12, 12, 6),
        .init("Massaman curry", .thai, "1 bowl", 520, 22, 30, 34),
        .init("Thai basil chicken", .thai, "1 serving", 470, 28, 30, 26),
        .init("Mango sticky rice", .thai, "1 serving", 380, 5, 70, 9),
        // Greek
        .init("Moussaka", .greek, "1 piece", 440, 20, 25, 29),
        .init("Souvlaki", .greek, "1 skewer", 300, 25, 5, 20),
        .init("Spanakopita", .greek, "1 piece", 260, 8, 24, 15),
        .init("Dolmades", .greek, "4 pieces", 180, 3, 22, 9),
        // French
        .init("Croissant", .french, "1 pastry", 272, 5.5, 31, 14),
        .init("Quiche lorraine", .french, "1 slice", 350, 13, 20, 25),
        .init("Beef bourguignon", .french, "1 bowl", 490, 35, 15, 28),
        .init("Crepe", .french, "1 crepe", 230, 6, 30, 9),
        .init("French onion soup", .french, "1 bowl", 280, 12, 26, 14),
        // Spanish
        .init("Paella", .spanish, "1 plate", 560, 28, 65, 18),
        .init("Tortilla espanola", .spanish, "1 slice", 240, 8, 20, 14),
        .init("Patatas bravas", .spanish, "1 serving", 320, 5, 40, 16),
        .init("Gazpacho", .spanish, "1 bowl", 120, 3, 15, 6),
        // Korean
        .init("Bibimbap", .korean, "1 bowl", 560, 20, 80, 16),
        .init("Bulgogi", .korean, "1 serving", 430, 30, 20, 24),
        .init("Kimchi fried rice", .korean, "1 plate", 480, 12, 72, 15),
        .init("Korean fried chicken", .korean, "1 serving", 590, 30, 40, 34),
        .init("Japchae", .korean, "1 plate", 410, 9, 62, 14),
        // Vietnamese
        .init("Pho", .vietnamese, "1 bowl", 420, 30, 55, 8),
        .init("Banh mi", .vietnamese, "1 sandwich", 480, 22, 55, 18),
        .init("Vietnamese spring rolls", .vietnamese, "2 rolls", 160, 8, 24, 3),
        .init("Vermicelli bowl", .vietnamese, "1 bowl", 470, 25, 60, 14),
        // Middle Eastern
        .init("Kebab plate", .middleEastern, "1 plate", 650, 40, 45, 34),
        .init("Falafel wrap", .middleEastern, "1 wrap", 520, 16, 62, 24),
        .init("Chicken shawarma plate", .middleEastern, "1 plate", 680, 42, 50, 34),
        .init("Baklava", .middleEastern, "1 piece", 245, 4, 29, 13),
        // Caribbean
        .init("Jerk chicken", .caribbean, "1 serving", 380, 34, 8, 23),
        .init("Rice and peas", .caribbean, "1 bowl", 340, 8, 55, 9),
        .init("Beef patty", .caribbean, "1 patty", 380, 12, 38, 20),
        // British
        .init("Fish and chips", .british, "1 serving", 840, 34, 84, 42),
        .init("Shepherd's pie", .british, "1 serving", 470, 24, 40, 24),
        .init("Full English breakfast", .british, "1 plate", 807, 38, 45, 52),
        .init("Bangers and mash", .british, "1 serving", 560, 24, 50, 30),
        // Indian (more)
        .init("Tandoori chicken", .indian, "1 serving", 300, 38, 6, 14),
        .init("Dal makhani", .indian, "1 bowl", 330, 12, 40, 14),
        .init("Aloo gobi", .indian, "1 bowl", 220, 6, 28, 10),
        .init("Dosa", .indian, "1 dosa", 168, 4, 30, 3),
        // Asian (other)
        .init("Nasi goreng", .asian, "1 plate", 540, 16, 72, 20),
        .init("Laksa", .asian, "1 bowl", 500, 20, 55, 22),
        .init("Satay skewers", .asian, "4 skewers", 320, 28, 12, 18),
    ]
}
