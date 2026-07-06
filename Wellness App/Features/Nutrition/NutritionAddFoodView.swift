//
//  NutritionAddFoodView.swift
//  Wellness App
//
//  The quick-add sheet. Segments for manual entry, recents, favorites, and a
//  searchable "Saved" list over custom foods and recipes. Manual entry also
//  supports scanning a barcode (or typing one) to fill the food from Open Food
//  Facts, and building new custom foods and recipes.
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
        case .search:    "Saved"
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
        // Clamp to non-negative so a stray negative value can never subtract
        // from the day's totals.
        return FoodEntry(
            name: name.trimmingCharacters(in: .whitespaces),
            mealType: meal,
            servings: max(0, servings),
            calories: max(0, calories),
            proteinG: max(0, protein),
            carbsG: max(0, carbs),
            fatG: max(0, fat),
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

    func filteredRecipes(_ recipes: [Recipe]) -> [Recipe] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return recipes }
        return recipes.filter { $0.name.lowercased().contains(query) }
    }

    /// Fill the manual form from a scanned product so the user can confirm and add.
    func prefill(from food: ScannedFood) {
        name = food.name
        servings = 1
        caloriesText = String(food.calories)
        proteinText = String(format: "%.0f", food.proteinG)
        carbsText = String(format: "%.0f", food.carbsG)
        fatText = String(format: "%.0f", food.fatG)
    }
}

struct NutritionAddFoodView: View {
    @Environment(NutritionStore.self) private var nutrition
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: NutritionAddFoodViewModel
    @State private var showScanner = false
    @State private var barcodeText = ""
    @State private var isLookingUp = false
    @State private var scanMessage: String?
    @State private var scanIsError = false
    @State private var showFoodEditor = false
    @State private var showRecipeEditor = false
    @State private var showLibrary = false

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
            .sheet(isPresented: $showScanner) {
                BarcodeScannerSheet { code in
                    showScanner = false
                    lookUp(code)
                }
            }
            .sheet(isPresented: $showFoodEditor) { NutritionCustomFoodEditor() }
            .sheet(isPresented: $showRecipeEditor) { NutritionRecipeEditor() }
            .sheet(isPresented: $showLibrary) {
                FoodLibraryBrowserView { name, macros in
                    nutrition.add(FoodEntry(
                        name: name,
                        mealType: viewModel.meal,
                        servings: 1,
                        calories: macros.calories,
                        proteinG: macros.proteinG,
                        carbsG: macros.carbsG,
                        fatG: macros.fatG,
                        source: .database
                    ))
                    Haptics.success()
                    dismiss()
                }
            }
        }
        .tint(Theme.nutrition)
    }

    // MARK: - Barcode lookup

    private func lookUp(_ code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLookingUp = true
        scanMessage = nil
        scanIsError = false
        Task {
            do {
                if let food = try await FoodDatabase.lookup(barcode: trimmed) {
                    viewModel.prefill(from: food)
                    viewModel.mode = .manual
                    barcodeText = ""
                    scanIsError = false
                    scanMessage = food.per100g
                        ? "Filled from \(food.name). Values are per 100 g — set servings to match what you ate."
                        : "Filled from \(food.name). Check the values and tap Add."
                    Haptics.success()
                } else {
                    scanIsError = true
                    scanMessage = "No product found for that barcode. You can enter it manually."
                }
            } catch {
                scanIsError = true
                scanMessage = "Couldn't reach the food database. Check your connection and try again."
            }
            isLookingUp = false
        }
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
                if BarcodeScannerView.isAvailable {
                    Button {
                        showScanner = true
                    } label: {
                        Label("Scan a barcode", systemImage: "barcode.viewfinder")
                    }
                }
                HStack {
                    Image(systemName: "number")
                        .foregroundStyle(.secondary)
                    TextField("Enter barcode number", text: $barcodeText)
                        .keyboardType(.numberPad)
                    Button("Look up") { lookUp(barcodeText) }
                        .disabled(barcodeText.filter(\.isNumber).count < 6 || isLookingUp)
                }
                if isLookingUp {
                    HStack(spacing: 8) { ProgressView(); Text("Looking up...") }
                        .foregroundStyle(.secondary)
                }
                if let scanMessage {
                    Text(scanMessage)
                        .font(.caption)
                        .foregroundStyle(scanIsError ? .red : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text("Scan a label")
            } footer: {
                Text("Scans look up the free Open Food Facts database. Only the barcode is sent, and you confirm the values before adding.")
            }
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
        let foods = viewModel.filteredCustomFoods(nutrition.customFoods)
        let recipes = viewModel.filteredRecipes(nutrition.recipes)
        return List {
            mealAndServingsHeader

            if nutrition.customFoods.isEmpty && nutrition.recipes.isEmpty {
                emptyState("Nothing saved yet",
                           "Build custom foods and recipes to log them in one tap.",
                           systemImage: "tray")
            }

            if !recipes.isEmpty {
                Section("Recipes") {
                    ForEach(recipes) { recipe in
                        Button {
                            nutrition.logRecipe(recipe, meal: viewModel.meal)
                            Haptics.success()
                            dismiss()
                        } label: {
                            let per = recipe.perServing
                            quickRow(name: recipe.name,
                                     calories: per.calories,
                                     protein: per.proteinG,
                                     carbs: per.carbsG,
                                     fat: per.fatG)
                        }
                    }
                }
            }

            if !foods.isEmpty {
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

            Section {
                Button {
                    showLibrary = true
                } label: {
                    Label("Browse food database", systemImage: "square.grid.2x2")
                }
                Button {
                    showFoodEditor = true
                } label: {
                    Label("New custom food", systemImage: "fork.knife")
                }
                Button {
                    showRecipeEditor = true
                } label: {
                    Label("New recipe from ingredients", systemImage: "list.bullet.rectangle")
                }
            } header: {
                Text("Add & create")
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search foods and recipes")
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
