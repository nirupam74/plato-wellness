//
//  MealPlanView.swift
//  Wellness App
//
//  Generates a day or week of meals from the food library based on the user's
//  diet preference, calorie target, meals per day, and an optional intermittent
//  fasting window. Each planned meal can be logged straight into the diary.
//

import SwiftUI

struct MealPlanView: View {
    @Environment(NutritionStore.self) private var nutrition
    @Environment(UserStore.self) private var user
    @Environment(\.dismiss) private var dismiss

    @State private var diet: DietType = .none
    @State private var calories: Int = 2000
    @State private var mealsPerDay: Int = 3
    @State private var weekMode = false
    @State private var fasting = false
    @State private var plan: [DayPlan] = []
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                preferencesSection

                if plan.isEmpty {
                    Section {
                        Text("Set your preferences and generate a plan.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(plan) { day in
                        Section {
                            ForEach(day.meals) { planned in
                                mealRow(planned)
                            }
                        } header: {
                            HStack {
                                Text(weekMode ? "Day \(day.dayIndex + 1)" : "Today")
                                Spacer()
                                Text("\(day.totalCalories) kcal")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Meal plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        generate()
                    } label: {
                        Label("Generate", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .onAppear {
                guard !didLoad else { return }
                diet = user.profile?.dietType ?? .none
                calories = user.profile?.targets.calories ?? 2000
                generate()
                didLoad = true
            }
        }
        .tint(Theme.nutrition)
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Picker("Diet", selection: $diet) {
                ForEach(DietType.allCases) { Text($0.label).tag($0) }
            }
            Stepper(value: $calories, in: 1200...4000, step: 50) {
                LabeledContent("Daily calories", value: "\(calories) kcal")
            }
            Picker("Meals per day", selection: $mealsPerDay) {
                Text("3").tag(3)
                Text("4").tag(4)
            }
            .pickerStyle(.segmented)
            Toggle("Plan a full week", isOn: $weekMode)
            Toggle("Intermittent fasting (skip breakfast)", isOn: $fasting)
        }
    }

    private func mealRow(_ planned: PlannedMeal) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(planned.timeText) · \(planned.slot.label)")
                    .font(.caption).foregroundStyle(.secondary)
                Text(planned.meal.name)
                    .font(.subheadline.weight(.medium))
                Text("\(planned.macros.calories) kcal · \(Int(planned.macros.proteinG))P \(Int(planned.macros.carbsG))C \(Int(planned.macros.fatG))F")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button {
                log(planned)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Theme.nutrition)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Log \(planned.meal.name) into \(planned.slot.label)")
        }
        .accessibilityElement(children: .combine)
    }

    private func generate() {
        plan = weekMode
            ? MealPlanGenerator.week(diet: diet, targetCalories: calories, mealsPerDay: mealsPerDay, fasting: fasting)
            : [MealPlanGenerator.day(dayIndex: 0, diet: diet, targetCalories: calories, mealsPerDay: mealsPerDay, fasting: fasting)]
        Haptics.tap()
    }

    private func log(_ planned: PlannedMeal) {
        let macros = planned.macros
        nutrition.add(FoodEntry(
            name: planned.meal.name,
            mealType: planned.slot,
            servings: 1,
            calories: macros.calories,
            proteinG: macros.proteinG,
            carbsG: macros.carbsG,
            fatG: macros.fatG,
            source: .database
        ))
        Haptics.success()
    }
}

#Preview {
    MealPlanView()
        .withSampleStores()
}
