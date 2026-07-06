//
//  Enums.swift
//  Wellness App
//
//  Shared enumerations used across models, stores, and views. All are Codable
//  and, where the UI needs to present them, CaseIterable with a display label.
//

import Foundation

enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case male, female
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case metric, imperial
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary, light, moderate, veryActive, extraActive
    var id: String { rawValue }

    var label: String {
        switch self {
        case .sedentary:   "Sedentary"
        case .light:       "Lightly active"
        case .moderate:    "Moderately active"
        case .veryActive:  "Very active"
        case .extraActive: "Extra active"
        }
    }

    var detail: String {
        switch self {
        case .sedentary:   "Little or no exercise, desk job"
        case .light:       "Light exercise 1 to 3 days a week"
        case .moderate:    "Moderate exercise 3 to 5 days a week"
        case .veryActive:  "Hard exercise 6 to 7 days a week"
        case .extraActive: "Very hard exercise or a physical job"
        }
    }

    /// TDEE multiplier (spec section 5).
    var multiplier: Double {
        switch self {
        case .sedentary:   1.2
        case .light:       1.375
        case .moderate:    1.55
        case .veryActive:  1.725
        case .extraActive: 1.9
        }
    }
}

enum Goal: String, Codable, CaseIterable, Identifiable {
    case lose, maintain, gain
    var id: String { rawValue }

    var label: String {
        switch self {
        case .lose:     "Lose weight"
        case .maintain: "Maintain"
        case .gain:     "Gain weight"
        }
    }
}

enum DietType: String, Codable, CaseIterable, Identifiable {
    case none, vegetarian, vegan, pescatarian, keto, other
    var id: String { rawValue }
    var label: String { self == .none ? "No preference" : rawValue.capitalized }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snacks
    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var systemImage: String {
        switch self {
        case .breakfast: "sunrise"
        case .lunch:     "sun.max"
        case .dinner:    "sunset"
        case .snacks:    "carrot"
        }
    }
}

enum EntrySource: String, Codable {
    case manual, database, barcode, favorite, recipe, healthKit
}

enum ActivityType: String, Codable, CaseIterable, Identifiable {
    case run, ride, strength, swim, sport, walk, other
    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var systemImage: String {
        switch self {
        case .run:      "figure.run"
        case .ride:     "bicycle"
        case .strength: "dumbbell"
        case .swim:     "figure.pool.swim"
        case .sport:    "sportscourt"
        case .walk:     "figure.walk"
        case .other:    "figure.mixed.cardio"
        }
    }

    /// Rough MET value for estimating calorie burn when none is supplied.
    var metValue: Double {
        switch self {
        case .run:      9.8
        case .ride:     7.5
        case .strength: 5.0
        case .swim:     8.0
        case .sport:    7.0
        case .walk:     3.5
        case .other:    5.0
        }
    }
}

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case breathing, meditation, yoga, bodyScan
    var id: String { rawValue }

    var label: String {
        switch self {
        case .breathing:  "Breathing"
        case .meditation: "Meditation"
        case .yoga:       "Yoga"
        case .bodyScan:   "Body scan"
        }
    }

    var systemImage: String {
        switch self {
        case .breathing:  "wind"
        case .meditation: "brain.head.profile"
        case .yoga:       "figure.yoga"
        case .bodyScan:   "figure.mind.and.body"
        }
    }
}

enum RoutineTime: String, Codable, CaseIterable, Identifiable {
    case morning, evening
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var systemImage: String { self == .morning ? "sun.max" : "moon.stars" }
}

enum MessageRole: String, Codable {
    case user, assistant
}
