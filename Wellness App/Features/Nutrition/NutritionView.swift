//
//  NutritionView.swift
//  Wellness App
//
//  Tab 1 root. Daily summary card, food diary grouped by meal with per-meal
//  subtotals and a running total vs target, plus quick add and links into the
//  macro breakdown, trends, and custom foods screens.
//

import SwiftUI

struct NutritionView: View {
    @Environment(NutritionStore.self) private var nutrition
    @Environment(UserStore.self) private var user

    @State private var viewModel = NutritionViewModel()

    /// Falls back to a neutral target set if the profile has not loaded yet.
    private var targets: DailyTargets {
        user.profile?.targets ?? DailyTargets(calories: 2000, proteinG: 120, carbsG: 220, fatG: 60, waterMl: 2500)
    }

    private var dayTotals: MacroBreakdown { nutrition.todaysTotals }

    private var hasAnyEntries: Bool { !nutrition.entries().isEmpty }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NutritionSummaryCard(totals: dayTotals, targets: targets)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                if hasAnyEntries {
                    diarySections
                } else {
                    Section {
                        ContentUnavailableView {
                            Label("No food logged yet", systemImage: "fork.knife")
                        } description: {
                            Text("Tap the plus button to log your first meal of the day.")
                        } actions: {
                            Button("Log food") { viewModel.presentAddFood() }
                                .buttonStyle(.borderedProminent)
                        }
                        .listRowBackground(Color.clear)
                    }
                }

                exploreSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { viewModel.presentAddFood() } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Quick add food")
                }
            }
            .sheet(isPresented: $viewModel.showingAddFood) {
                NutritionAddFoodView(initialMeal: viewModel.quickAddMeal)
            }
        }
        .tint(Theme.nutrition)
    }

    // MARK: - Diary

    @ViewBuilder
    private var diarySections: some View {
        // Running total accumulates meal-by-meal in display order.
        let orderedMeals = MealType.allCases
        ForEach(Array(orderedMeals.enumerated()), id: \.element) { index, meal in
            let entries = nutrition.entries(for: meal)
            let mealCalories = nutrition.totals(for: meal).calories
            let runningTotal = orderedMeals.prefix(index + 1)
                .reduce(0) { $0 + nutrition.totals(for: $1).calories }

            Section {
                if entries.isEmpty {
                    Text("Nothing logged")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entries) { entry in
                        NutritionFoodEntryRow(entry: entry)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    nutrition.remove(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            } header: {
                SectionHeaderRow(title: meal.label) {
                    HStack(spacing: 10) {
                        Text(NutritionFormat.calories(mealCalories))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                        Button {
                            viewModel.presentAddFood(for: meal)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Add to \(meal.label)")
                    }
                }
            } footer: {
                if !entries.isEmpty {
                    Text("Running total: \(runningTotal) of \(targets.calories) cal")
                        .monospacedDigit()
                }
            }
            .textCase(nil)
        }
    }

    // MARK: - Explore

    private var exploreSection: some View {
        Section("Insights and library") {
            NavigationLink {
                NutritionMacroBreakdownView()
            } label: {
                Label("Macro breakdown", systemImage: "chart.pie")
            }
            NavigationLink {
                NutritionTrendsView()
            } label: {
                Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
            }
            NavigationLink {
                NutritionCustomFoodsView()
            } label: {
                Label("Custom foods and recipes", systemImage: "text.badge.plus")
            }
        }
    }
}

#Preview {
    NutritionView()
        .withSampleStores()
}
