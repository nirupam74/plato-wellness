//
//  NutritionAddFoodView.swift
//  Wellness App
//
//  The quick-add sheet. Segments for manual entry, recents, favorites, and a
//  searchable list over saved custom foods. Barcode scanning is stubbed as a
//  disabled row for now.
//

import SwiftUI

enum NutritionAddFoodMode: String, CaseIterable, Identifiable {
    case manual, recents, favorites, search

    var id: String { rawValue }
    var label: String {
        switch self {
        case .manual:    "Manual"
        case .recents:   "Recents"
        case .favorites: "Favorites"
        case .search:    "Search"
        }
    }
}

@Observable
final class NutritionAddFoodViewModel {
    var mode: NutritionAddFoodMode = .manual

    /// Meal used both by the manual form and the quick-add lists.
    var meal: MealType

    // Manual entry fields, kept as strings so the number pads behave.
    var name = ""
    var servings = 1.0
    var caloriesText = ""
    var proteinText = ""
    var carbsText = ""
    var fatText = ""

    // Servings used when logging from recents, favorites, or search.
    var quickServings = 1.0

    var searchText = ""

    init(meal: MealType) {
        self.meal = meal
    }

    private var calories: Int? { Int(caloriesText) }
    private var protein: Double { Double(proteinText) ?? 0 }
    private var carbs: Double { Double(carbsText) ?? 0 }
    private var fat: Double { Double(fatText) ?? 0 }

    var canSaveManual: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && (calories ?? -1) >= 0
            && servings > 0
    }

    func makeManualEntry() -> FoodEntry? {
        guard canSaveManual, let calories else { return nil }
        return FoodEntry(
            name: name.trimmingCharacters(in: .whitespaces),
            mealType: meal,
            servings: servings,
            calories: calories,
            proteinG: protein,
            carbsG: carbs,
            fatG: fat,
            source: .manual
        )
    }

    /// A new entry cloned from a recent one, logged into the chosen meal now.
    func reAdd(_ recent: FoodEntry) -> FoodEntry {
        FoodEntry(
            name: recent.name,
            mealType: meal,
            servings: quickServings,
            calories: recent.calories,
            proteinG: recent.proteinG,
            carbsG: recent.carbsG,
            fatG: recent.fatG,
            source: recent.source
        )
    }

    func filteredCustomFoods(_ foods: [CustomFood]) -> [CustomFood] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return foods }
        return foods.filter { $0.name.lowercased().contains(query) }
    }
}

struct NutritionAddFoodView: View {
    @Environment(NutritionStore.self) private var nutrition
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: NutritionAddFoodViewModel

    init(initialMeal: MealType = .breakfast) {
        _viewModel = State(initialValue: NutritionAddFoodViewModel(meal: initialMeal))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Source", selection: $viewModel.mode) {
                    ForEach(NutritionAddFoodMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                switch viewModel.mode {
                case .manual:    manualForm
                case .recents:   recentsList
                case .favorites: favoritesList
                case .search:    searchList
                }
            }
            .navigationTitle("Add food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if viewModel.mode == .manual {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { saveManual() }
                            .disabled(!viewModel.canSaveManual)
                    }
                }
            }
        }
        .tint(Theme.nutrition)
    }

    // MARK: - Manual

    private var manualForm: some View {
        Form {
            Section("Food") {
                TextField("Name", text: $viewModel.name)
                Picker("Meal", selection: $viewModel.meal) {
                    ForEach(MealType.allCases) { meal in
                        Label(meal.label, systemImage: meal.systemImage).tag(meal)
                    }
                }
                Stepper(value: $viewModel.servings, in: 0.25...20, step: 0.25) {
                    HStack {
                        Text("Servings")
                        Spacer()
                        Text(NutritionFormat.servings(viewModel.servings))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }

            Section("Per serving") {
                macroField("Calories", text: $viewModel.caloriesText, unit: "cal")
                macroField("Protein", text: $viewModel.proteinText, unit: "g")
                macroField("Carbs", text: $viewModel.carbsText, unit: "g")
                macroField("Fat", text: $viewModel.fatText, unit: "g")
            }

            Section {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scan barcode")
                        Text("Coming in a later update.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "barcode.viewfinder")
                }
                .foregroundStyle(.secondary)
            }
            .disabled(true)
        }
    }

    private func macroField(_ title: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 90)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }

    private func saveManual() {
        guard let entry = viewModel.makeManualEntry() else { return }
        nutrition.add(entry)
        Haptics.success()
        dismiss()
    }

    // MARK: - Quick lists

    private var recentsList: some View {
        let recents = nutrition.recents
        return List {
            mealAndServingsHeader
            if recents.isEmpty {
                emptyState("No recents yet",
                           "Foods you log will show up here for quick re-adding.",
                           systemImage: "clock.arrow.circlepath")
            } else {
                Section("Recently logged") {
                    ForEach(recents) { recent in
                        Button {
                            nutrition.add(viewModel.reAdd(recent))
                            dismiss()
                        } label: {
                            quickRow(name: recent.name,
                                     calories: recent.calories,
                                     protein: recent.proteinG,
                                     carbs: recent.carbsG,
                                     fat: recent.fatG)
                        }
                    }
                }
            }
        }
    }

    private var favoritesList: some View {
        List {
            mealAndServingsHeader
            let favorites = nutrition.favorites
            if favorites.isEmpty {
                emptyState("No favorites yet",
                           "Mark a custom food as a favorite to log it in one tap.",
                           systemImage: "star")
            } else {
                Section("Favorites") {
                    ForEach(favorites) { food in
                        Button {
                            nutrition.logCustomFood(food, meal: viewModel.meal, servings: viewModel.quickServings)
                            dismiss()
                        } label: {
                            quickRow(name: food.name,
                                     calories: food.calories,
                                     protein: food.proteinG,
                                     carbs: food.carbsG,
                                     fat: food.fatG)
                        }
                    }
                }
            }
        }
    }

    private var searchList: some View {
        List {
            mealAndServingsHeader
            let foods = viewModel.filteredCustomFoods(nutrition.customFoods)
            if nutrition.customFoods.isEmpty {
                emptyState("No saved foods",
                           "Create custom foods to build up a searchable library.",
                           systemImage: "magnifyingglass")
            } else if foods.isEmpty {
                emptyState("No matches",
                           "Try a different search.",
                           systemImage: "magnifyingglass")
            } else {
                Section("Saved foods") {
                    ForEach(foods) { food in
                        Button {
                            nutrition.logCustomFood(food, meal: viewModel.meal, servings: viewModel.quickServings)
                            dismiss()
                        } label: {
                            quickRow(name: food.name,
                                     calories: food.calories,
                                     protein: food.proteinG,
                                     carbs: food.carbsG,
                                     fat: food.fatG)
                        }
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search saved foods")
    }

    private var mealAndServingsHeader: some View {
        Section {
            Picker("Meal", selection: $viewModel.meal) {
                ForEach(MealType.allCases) { meal in
                    Label(meal.label, systemImage: meal.systemImage).tag(meal)
                }
            }
            Stepper(value: $viewModel.quickServings, in: 0.25...20, step: 0.25) {
                HStack {
                    Text("Servings")
                    Spacer()
                    Text(NutritionFormat.servings(viewModel.quickServings))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        } header: {
            Text("Log into")
        }
    }

    private func quickRow(name: String, calories: Int, protein: Double, carbs: Double, fat: Double) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .foregroundStyle(.primary)
                Text("\(NutritionFormat.grams(protein)) P, \(NutritionFormat.grams(carbs)) C, \(NutritionFormat.grams(fat)) F")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(NutritionFormat.calories(calories))
                .font(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Image(systemName: "plus.circle")
                .foregroundStyle(Theme.nutrition)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
        .accessibilityHint("Logs \(calories) calories into \(viewModel.meal.label)")
    }

    @ViewBuilder
    private func emptyState(_ title: String, _ message: String, systemImage: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
        .listRowBackground(Color.clear)
    }
}

#Preview {
    NutritionAddFoodView(initialMeal: .lunch)
        .withSampleStores()
}
