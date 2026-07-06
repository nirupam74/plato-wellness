//
//  NutritionComponents.swift
//  Wellness App
//
//  Shared, Nutrition-scoped building blocks used across the pillar's screens.
//  All new helper types are prefixed with `Nutrition` to avoid collisions.
//

import SwiftUI

/// The three tracked macros, with a stable color and accessors that read a
/// MacroBreakdown value and a DailyTargets target. Colors stay inside the app
/// palette so charts and rings read as one system.
enum NutritionMacro: String, CaseIterable, Identifiable {
    case protein, carbs, fat

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var shortLabel: String {
        switch self {
        case .protein: "P"
        case .carbs:   "C"
        case .fat:     "F"
        }
    }

    var tint: Color {
        switch self {
        case .protein: Theme.nutrition
        case .carbs:   Theme.activity
        case .fat:     Theme.restore
        }
    }

    /// Grams logged for this macro in the given breakdown.
    func value(in macros: MacroBreakdown) -> Double {
        switch self {
        case .protein: macros.proteinG
        case .carbs:   macros.carbsG
        case .fat:     macros.fatG
        }
    }

    /// Gram target for this macro in the given daily targets.
    func target(in targets: DailyTargets) -> Double {
        switch self {
        case .protein: Double(targets.proteinG)
        case .carbs:   Double(targets.carbsG)
        case .fat:     Double(targets.fatG)
        }
    }
}

/// Small formatting helpers so copy stays consistent across screens.
enum NutritionFormat {
    static func grams(_ g: Double) -> String { "\(Int(g.rounded())) g" }
    static func calories(_ c: Int) -> String { "\(c) cal" }

    static func servings(_ s: Double) -> String {
        let rounded = (s * 100).rounded() / 100
        if rounded == rounded.rounded() {
            return "\(Int(rounded))"
        }
        return String(format: "%.2f", rounded)
    }
}

// MARK: - Summary card

/// Top-of-screen daily summary: a big calories-remaining ring plus the three
/// macro progress bars against target. Reused on the diary root.
struct NutritionSummaryCard: View {
    var totals: MacroBreakdown
    var targets: DailyTargets

    private var caloriesRemaining: Int { targets.calories - totals.calories }
    private var calorieProgress: Double {
        guard targets.calories > 0 else { return 0 }
        return Double(totals.calories) / Double(targets.calories)
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 18) {
                    ZStack {
                        MetricRing(progress: calorieProgress, tint: Theme.nutrition, lineWidth: 12)
                            .frame(width: 96, height: 96)
                        VStack(spacing: 0) {
                            Text("\(max(caloriesRemaining, 0))")
                                .font(.title2.weight(.bold))
                                .contentTransition(.numericText())
                            Text("left")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Calories")
                    .accessibilityValue(caloriesRemaining >= 0
                        ? "\(caloriesRemaining) calories remaining of \(targets.calories)"
                        : "\(-caloriesRemaining) calories over your \(targets.calories) target")

                    VStack(alignment: .leading, spacing: 6) {
                        Text(caloriesRemaining >= 0 ? "Calories remaining" : "Calories over")
                            .font(.subheadline.weight(.semibold))
                        Text("\(totals.calories) eaten, \(targets.calories) target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }

                VStack(spacing: 10) {
                    ForEach(NutritionMacro.allCases) { macro in
                        NutritionMacroBar(macro: macro,
                                          value: macro.value(in: totals),
                                          target: macro.target(in: targets))
                    }
                }
            }
        }
    }
}

/// A single labeled macro progress bar with grams and target.
struct NutritionMacroBar: View {
    var macro: NutritionMacro
    var value: Double
    var target: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(macro.label)
                    .font(.caption.weight(.medium))
                Spacer()
                Text("\(NutritionFormat.grams(value)) / \(NutritionFormat.grams(target))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            LabeledProgressBar(value: value, target: target, tint: macro.tint)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(macro.label)
        .accessibilityValue("\(NutritionFormat.grams(value)) of \(NutritionFormat.grams(target))")
    }
}

// MARK: - Macro rings

/// Three compact rings for protein, carbs, and fat vs target.
struct NutritionMacroRingsRow: View {
    var totals: MacroBreakdown
    var targets: DailyTargets

    var body: some View {
        HStack(spacing: 12) {
            ForEach(NutritionMacro.allCases) { macro in
                let value = macro.value(in: totals)
                let target = macro.target(in: targets)
                let progress = target > 0 ? value / target : 0
                VStack(spacing: 8) {
                    ZStack {
                        MetricRing(progress: progress, tint: macro.tint, lineWidth: 8)
                            .frame(width: 64, height: 64)
                        Text(macro.shortLabel)
                            .font(.headline)
                            .foregroundStyle(macro.tint)
                    }
                    Text(macro.label)
                        .font(.caption.weight(.medium))
                    Text("\(NutritionFormat.grams(value)) / \(NutritionFormat.grams(target))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(macro.label) ring")
                .accessibilityValue("\(NutritionFormat.grams(value)) of \(NutritionFormat.grams(target))")
            }
        }
    }
}

// MARK: - Food row

/// A single food diary entry row, showing name, servings, and calories.
struct NutritionFoodEntryRow: View {
    var entry: FoodEntry

    var body: some View {
        let totals = entry.totals
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.body)
                Text("\(NutritionFormat.grams(totals.proteinG)) P, \(NutritionFormat.grams(totals.carbsG)) C, \(NutritionFormat.grams(totals.fatG)) F")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(NutritionFormat.calories(totals.calories))
                .font(.callout.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.name)
        .accessibilityValue("\(totals.calories) calories, \(NutritionFormat.grams(totals.proteinG)) protein, \(NutritionFormat.grams(totals.carbsG)) carbs, \(NutritionFormat.grams(totals.fatG)) fat")
    }
}
