//
//  NutritionMacroBreakdownView.swift
//  Wellness App
//
//  Today's macros vs target as rings and bars, plus a seven-day average and a
//  grouped Swift Chart of daily macro grams.
//

import SwiftUI
import Charts

/// One day's macro grams flattened for charting.
private struct NutritionMacroPoint: Identifiable {
    let id = UUID()
    let date: Date
    let macro: NutritionMacro
    let grams: Double
}

struct NutritionMacroBreakdownView: View {
    @Environment(NutritionStore.self) private var nutrition
    @Environment(UserStore.self) private var user

    private var targets: DailyTargets {
        user.profile?.targets ?? DailyTargets(calories: 2000, proteinG: 120, carbsG: 220, fatG: 60, waterMl: 2500)
    }

    private var week: [(date: Date, macros: MacroBreakdown)] {
        nutrition.dailyTotals(lastDays: 7)
    }

    private var weeklyAverage: MacroBreakdown {
        let days = week.map(\.macros)
        guard !days.isEmpty else { return .zero }
        let sum = days.reduce(MacroBreakdown.zero, +)
        let n = Double(days.count)
        return MacroBreakdown(
            calories: sum.calories / days.count,
            proteinG: sum.proteinG / n,
            carbsG: sum.carbsG / n,
            fatG: sum.fatG / n
        )
    }

    private var points: [NutritionMacroPoint] {
        week.flatMap { day in
            NutritionMacro.allCases.map { macro in
                NutritionMacroPoint(date: day.date, macro: macro, grams: macro.value(in: day.macros))
            }
        }
    }

    private var hasData: Bool { week.contains { $0.macros.calories > 0 } }

    var body: some View {
        List {
            Section("Today vs target") {
                NutritionMacroRingsRow(totals: nutrition.todaysTotals, targets: targets)
                    .padding(.vertical, 8)
                    .listRowSeparator(.hidden)
                ForEach(NutritionMacro.allCases) { macro in
                    NutritionMacroBar(macro: macro,
                                      value: macro.value(in: nutrition.todaysTotals),
                                      target: macro.target(in: targets))
                    .padding(.vertical, 2)
                }
            }

            Section("Seven-day average") {
                HStack(spacing: 12) {
                    StatTile(title: "Calories", value: "\(weeklyAverage.calories)", systemImage: "flame", tint: Theme.nutrition)
                    StatTile(title: "Protein", value: NutritionFormat.grams(weeklyAverage.proteinG), systemImage: "circle.grid.cross", tint: NutritionMacro.protein.tint)
                }
                HStack(spacing: 12) {
                    StatTile(title: "Carbs", value: NutritionFormat.grams(weeklyAverage.carbsG), systemImage: "leaf", tint: NutritionMacro.carbs.tint)
                    StatTile(title: "Fat", value: NutritionFormat.grams(weeklyAverage.fatG), systemImage: "drop", tint: NutritionMacro.fat.tint)
                }
            }

            Section("Daily macros, last 7 days") {
                if hasData {
                    macroChart
                        .frame(height: 240)
                        .padding(.vertical, 8)
                } else {
                    ContentUnavailableView("No macros yet",
                                           systemImage: "chart.bar",
                                           description: Text("Log meals this week to see your macro mix here."))
                }
            }
        }
        .navigationTitle("Macro breakdown")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var macroChart: some View {
        Chart(points) { point in
            BarMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Grams", point.grams)
            )
            .foregroundStyle(by: .value("Macro", point.macro.label))
            .position(by: .value("Macro", point.macro.label))
        }
        .chartForegroundStyleScale([
            NutritionMacro.protein.label: NutritionMacro.protein.tint,
            NutritionMacro.carbs.label: NutritionMacro.carbs.tint,
            NutritionMacro.fat.label: NutritionMacro.fat.tint,
        ])
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
            }
        }
        .chartLegend(position: .bottom)
        .accessibilityLabel("Grouped bar chart of protein, carbs, and fat grams for each of the last seven days")
    }
}

#Preview {
    NavigationStack {
        NutritionMacroBreakdownView()
    }
    .withSampleStores()
}
