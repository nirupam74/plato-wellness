//
//  NutritionTrendsView.swift
//  Wellness App
//
//  Average calories and macros over 7, 30, or 90 days with a range control and
//  Swift Charts. Calories as a line vs target, macros as an average bar chart.
//

import SwiftUI
import Charts

enum NutritionTimeRange: Int, CaseIterable, Identifiable {
    case week = 7
    case month = 30
    case quarter = 90

    var id: Int { rawValue }
    var days: Int { rawValue }
    var label: String {
        switch self {
        case .week:    "7D"
        case .month:   "30D"
        case .quarter: "90D"
        }
    }
    var longLabel: String {
        switch self {
        case .week:    "last 7 days"
        case .month:   "last 30 days"
        case .quarter: "last 90 days"
        }
    }
}

@Observable
final class NutritionTrendsViewModel {
    var range: NutritionTimeRange = .week
}

/// One day's calorie total for the line chart.
private struct NutritionCaloriePoint: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
}

struct NutritionTrendsView: View {
    @Environment(NutritionStore.self) private var nutrition
    @Environment(UserStore.self) private var user

    @State private var viewModel = NutritionTrendsViewModel()

    private var targets: DailyTargets {
        user.profile?.targets ?? DailyTargets(calories: 2000, proteinG: 120, carbsG: 220, fatG: 60, waterMl: 2500)
    }

    private var series: [(date: Date, macros: MacroBreakdown)] {
        nutrition.dailyTotals(lastDays: viewModel.range.days)
    }

    private var caloriePoints: [NutritionCaloriePoint] {
        series.map { NutritionCaloriePoint(date: $0.date, calories: $0.macros.calories) }
    }

    private var averageCalories: Int {
        nutrition.averageCalories(lastDays: viewModel.range.days)
    }

    private var averageMacros: [(macro: NutritionMacro, grams: Double)] {
        let days = series.map(\.macros)
        guard !days.isEmpty else { return NutritionMacro.allCases.map { ($0, 0) } }
        let n = Double(days.count)
        let sum = days.reduce(MacroBreakdown.zero, +)
        let avg = MacroBreakdown(calories: 0, proteinG: sum.proteinG / n, carbsG: sum.carbsG / n, fatG: sum.fatG / n)
        return NutritionMacro.allCases.map { ($0, $0.value(in: avg)) }
    }

    private var hasData: Bool { series.contains { $0.macros.calories > 0 } }

    var body: some View {
        List {
            Section {
                Picker("Range", selection: $viewModel.range) {
                    ForEach(NutritionTimeRange.allCases) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            Section("Averages, \(viewModel.range.longLabel)") {
                HStack(spacing: 12) {
                    StatTile(title: "Calories per day", value: "\(averageCalories)", systemImage: "flame", tint: Theme.nutrition)
                    StatTile(title: "Target", value: "\(targets.calories)", systemImage: "target", tint: .secondary)
                }
            }

            Section("Daily calories") {
                if hasData {
                    calorieChart
                        .frame(height: 220)
                        .padding(.vertical, 8)
                } else {
                    ContentUnavailableView("No calories logged",
                                           systemImage: "chart.line.uptrend.xyaxis",
                                           description: Text("Log meals to see your calorie trend over time."))
                }
            }

            Section("Average macros") {
                if hasData {
                    macroChart
                        .frame(height: 200)
                        .padding(.vertical, 8)
                } else {
                    ContentUnavailableView("No macros logged",
                                           systemImage: "chart.bar",
                                           description: Text("Your average macro mix will appear here."))
                }
            }
        }
        .navigationTitle("Trends")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var calorieChart: some View {
        Chart {
            ForEach(caloriePoints) { point in
                LineMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Calories", point.calories)
                )
                .foregroundStyle(Theme.nutrition)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Calories", point.calories)
                )
                .foregroundStyle(Theme.nutrition.opacity(0.12))
                .interpolationMethod(.catmullRom)
            }
            RuleMark(y: .value("Target", targets.calories))
                .foregroundStyle(.secondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                .annotation(position: .top, alignment: .leading) {
                    Text("Target \(targets.calories)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
        }
        .chartYScale(domain: .automatic(includesZero: true))
        .accessibilityLabel("Line chart of daily calories over the \(viewModel.range.longLabel), with your target marked")
    }

    private var macroChart: some View {
        Chart(averageMacros, id: \.macro.id) { item in
            BarMark(
                x: .value("Macro", item.macro.label),
                y: .value("Grams", item.grams)
            )
            .foregroundStyle(item.macro.tint)
            .annotation(position: .top) {
                Text(NutritionFormat.grams(item.grams))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel("Bar chart of average protein, carbs, and fat grams over the \(viewModel.range.longLabel)")
    }
}

#Preview {
    NavigationStack {
        NutritionTrendsView()
    }
    .withSampleStores()
}
