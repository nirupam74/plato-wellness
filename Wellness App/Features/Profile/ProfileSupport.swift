//
//  ProfileSupport.swift
//  Wellness App
//
//  Small shared helpers for the Profile feature: profile bindings into the
//  store, unit-aware display and edit conversions, and the appearance setting.
//  These live in the Profile folder and only extend, never modify, the shared
//  foundation.
//

import SwiftUI

// MARK: - Profile bindings

extension UserStore {
    /// A two-way binding into a field of the user profile that persists through
    /// `update`, so edits flow back into the store. Falls back to `defaultValue`
    /// while the profile is still nil (pre-onboarding).
    func profileBinding<Value>(
        _ keyPath: WritableKeyPath<UserProfile, Value>,
        default defaultValue: Value
    ) -> Binding<Value> {
        Binding(
            get: { self.profile?[keyPath: keyPath] ?? defaultValue },
            set: { newValue in self.update { $0[keyPath: keyPath] = newValue } }
        )
    }
}

// MARK: - Unit-aware formatting

/// Presentation helpers that convert the internally-metric values to whatever
/// unit system the user prefers, for both display and editing.
enum ProfileFormat {

    // Weight

    static func weightDisplayValue(kg: Double, system: UnitSystem) -> Double {
        system == .metric ? kg : Units.kgToLb(kg)
    }

    static func kg(fromDisplayWeight value: Double, system: UnitSystem) -> Double {
        system == .metric ? value : Units.lbToKg(value)
    }

    static func weightUnitLabel(_ system: UnitSystem) -> String {
        system == .metric ? "kg" : "lb"
    }

    // Length (waist, hips, etc.)

    static func lengthDisplayValue(cm: Double, system: UnitSystem) -> Double {
        system == .metric ? cm : Units.cmToIn(cm)
    }

    static func cm(fromDisplayLength value: Double, system: UnitSystem) -> Double {
        system == .metric ? value : Units.inToCm(value)
    }

    static func lengthUnitLabel(_ system: UnitSystem) -> String {
        system == .metric ? "cm" : "in"
    }

    /// A compact number style for editable fields (up to one decimal place).
    static let decimal: FloatingPointFormatStyle<Double> = .number.precision(.fractionLength(0...1))
}

// MARK: - Appearance

/// Local appearance preference, stored via `@AppStorage("appearance")`.
enum ProfileAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light:  "Light"
        case .dark:   "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light:  "sun.max"
        case .dark:   "moon.stars"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}

// MARK: - Body metrics (for progress charts)

/// A single trackable body metric, used to drive the body-data charts and the
/// measurement editor. Values are read in metric and converted for display.
enum ProfileBodyMetric: String, CaseIterable, Identifiable {
    case weight, bodyFat, waist, hips, chest, arm, thigh, neck

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weight:  "Weight"
        case .bodyFat: "Body fat"
        case .waist:   "Waist"
        case .hips:    "Hips"
        case .chest:   "Chest"
        case .arm:     "Arm"
        case .thigh:   "Thigh"
        case .neck:    "Neck"
        }
    }

    var systemImage: String {
        switch self {
        case .weight:  "scalemass"
        case .bodyFat: "percent"
        case .waist:   "figure"
        case .hips:    "figure.walk"
        case .chest:   "lungs"
        case .arm:     "figure.strengthtraining.traditional"
        case .thigh:   "figure.run"
        case .neck:    "person.bust"
        }
    }

    /// The raw stored value (kg, percent, or cm) for this metric.
    func rawValue(from m: BodyMeasurement) -> Double? {
        switch self {
        case .weight:  m.weightKg
        case .bodyFat: m.bodyFatPercent
        case .waist:   m.waistCm
        case .hips:    m.hipsCm
        case .chest:   m.chestCm
        case .arm:     m.armCm
        case .thigh:   m.thighCm
        case .neck:    m.neckCm
        }
    }

    /// The display value in the user's unit system.
    func displayValue(from m: BodyMeasurement, system: UnitSystem) -> Double? {
        guard let raw = rawValue(from: m) else { return nil }
        switch self {
        case .weight:  return ProfileFormat.weightDisplayValue(kg: raw, system: system)
        case .bodyFat: return raw
        default:       return ProfileFormat.lengthDisplayValue(cm: raw, system: system)
        }
    }

    func unitLabel(_ system: UnitSystem) -> String {
        switch self {
        case .weight:  return ProfileFormat.weightUnitLabel(system)
        case .bodyFat: return "%"
        default:       return ProfileFormat.lengthUnitLabel(system)
        }
    }

    var tint: Color {
        switch self {
        case .weight, .bodyFat: return Theme.accent
        default:                return Theme.activity
        }
    }
}
