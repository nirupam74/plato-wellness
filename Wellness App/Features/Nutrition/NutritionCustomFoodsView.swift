//
//  NutritionCustomFoodsView.swift
//  Wellness App
//
//  Library of saved custom foods and recipes. Create a CustomFood, build a
//  Recipe from ingredients, and log either into a meal.
//

import SwiftUI

struct NutritionCustomFoodsView: View {
    @Environment(NutritionStore.self) private var nutrition

    @State private var showingFoodEditor = false
    @State private var showingRecipeEditor = false

    var body: some View {
        List {
            customFoodsSection
            recipesSection
        }
        .navigationTitle("Foods and recipes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingFoodEditor = true
                    } label: {
                        Label("New custom food", systemImage: "fork.knife")
                    }
                    Button {
                        showingRecipeEditor = true
                    } label: {
                        Label("New recipe", systemImage: "list.bullet.rectangle")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add food or recipe")
            }
        }
        .sheet(isPresented: $showingFoodEditor) {
            NutritionCustomFoodEditor()
        }
        .sheet(isPresented: $showingRecipeEditor) {
            NutritionRecipeEditor()
        }
    }

    // MARK: - Custom foods

    private var customFoodsSection: some View {
        Section("Custom foods") {
            if nutrition.customFoods.isEmpty {
                ContentUnavailableView("No custom foods",
                                       systemImage: "fork.knife",
                                       description: Text("Save foods you eat often to log them faster."))
            } else {
                ForEach(nutrition.customFoods) { food in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(food.name)
                            Text("\(NutritionFormat.calories(food.calories)), \(NutritionFormat.grams(food.proteinG)) P, \(NutritionFormat.grams(food.carbsG)) C, \(NutritionFormat.grams(food.fatG)) F")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Button {
                            nutrition.toggleFavorite(food)
                        } label: {
                            Image(systemName: food.isFavorite ? "star.fill" : "star")
                                .foregroundStyle(food.isFavorite ? Color.yellow : Color.secondary)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(food.isFavorite ? "Remove \(food.name) from favorites" : "Add \(food.name) to favorites")

                        logMealMenu { meal in
                            nutrition.logCustomFood(food, meal: meal)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recipes

    private var recipesSection: some View {
        Section("Recipes") {
            if nutrition.recipes.isEmpty {
                ContentUnavailableView("No recipes",
                                       systemImage: "list.bullet.rectangle",
                                       description: Text("Build a recipe from ingredients to log it in one tap."))
            } else {
                ForEach(nutrition.recipes) { recipe in
                    let per = recipe.perServing
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(recipe.name)
                            Text("\(recipe.servings) servings, \(NutritionFormat.calories(per.calories)) each")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        logMealMenu { meal in
                            nutrition.logRecipe(recipe, meal: meal)
                        }
                    }
                }
            }
        }
    }

    /// A compact menu that logs the item into a chosen meal.
    private func logMealMenu(_ action: @escaping (MealType) -> Void) -> some View {
        Menu {
            ForEach(MealType.allCases) { meal in
                Button {
                    action(meal)
                } label: {
                    Label(meal.label, systemImage: meal.systemImage)
                }
            }
        } label: {
            Image(systemName: "plus.circle")
                .foregroundStyle(Theme.nutrition)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Log into a meal")
    }
}

// MARK: - Custom food editor

@Observable
final class NutritionCustomFoodEditorViewModel {
    var name = ""
    var caloriesText = ""
    var proteinText = ""
    var carbsText = ""
    var fatText = ""
    var isFavorite = false

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && Int(caloriesText) != nil
    }

    func makeFood() -> CustomFood? {
        guard let calories = Int(caloriesText),
              !name.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return CustomFood(
            name: name.trimmingCharacters(in: .whitespaces),
            calories: calories,
            proteinG: Double(proteinText) ?? 0,
            carbsG: Double(carbsText) ?? 0,
            fatG: Double(fatText) ?? 0,
            isFavorite: isFavorite
        )
    }
}

struct NutritionCustomFoodEditor: View {
    @Environment(NutritionStore.self) private var nutrition
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = NutritionCustomFoodEditorViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Name", text: $viewModel.name)
                    Toggle("Favorite", isOn: $viewModel.isFavorite)
                }
                Section("Per serving") {
                    NutritionNumberField(title: "Calories", text: $viewModel.caloriesText, unit: "cal")
                    NutritionNumberField(title: "Protein", text: $viewModel.proteinText, unit: "g")
                    NutritionNumberField(title: "Carbs", text: $viewModel.carbsText, unit: "g")
                    NutritionNumberField(title: "Fat", text: $viewModel.fatText, unit: "g")
                }
            }
            .navigationTitle("New custom food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let food = viewModel.makeFood() {
                            nutrition.saveCustomFood(food)
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
        .tint(Theme.nutrition)
    }
}

// MARK: - Recipe editor

@Observable
final class NutritionRecipeBuilderViewModel {
    var name = ""
    var servings = 1
    var ingredients: [RecipeIngredient] = []

    // Draft ingredient fields.
    var ingName = ""
    var ingCaloriesText = ""
    var ingProteinText = ""
    var ingCarbsText = ""
    var ingFatText = ""

    var canAddIngredient: Bool {
        !ingName.trimmingCharacters(in: .whitespaces).isEmpty && Int(ingCaloriesText) != nil
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !ingredients.isEmpty
    }

    func addIngredient() {
        guard let calories = Int(ingCaloriesText),
              !ingName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let macros = MacroBreakdown(
            calories: calories,
            proteinG: Double(ingProteinText) ?? 0,
            carbsG: Double(ingCarbsText) ?? 0,
            fatG: Double(ingFatText) ?? 0
        )
        ingredients.append(RecipeIngredient(name: ingName.trimmingCharacters(in: .whitespaces), macros: macros))
        ingName = ""
        ingCaloriesText = ""
        ingProteinText = ""
        ingCarbsText = ""
        ingFatText = ""
    }

    func removeIngredients(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }

    /// Live per-serving preview using the same math the model uses.
    var perServingPreview: MacroBreakdown {
        Recipe(name: name, servings: servings, ingredients: ingredients).perServing
    }

    func makeRecipe() -> Recipe? {
        guard canSave else { return nil }
        return Recipe(name: name.trimmingCharacters(in: .whitespaces),
                      servings: max(servings, 1),
                      ingredients: ingredients)
    }
}

struct NutritionRecipeEditor: View {
    @Environment(NutritionStore.self) private var nutrition
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = NutritionRecipeBuilderViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe") {
                    TextField("Name", text: $viewModel.name)
                    Stepper(value: $viewModel.servings, in: 1...50) {
                        HStack {
                            Text("Servings")
                            Spacer()
                            Text("\(viewModel.servings)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }

                Section("Ingredients") {
                    if viewModel.ingredients.isEmpty {
                        Text("Add at least one ingredient below.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.ingredients) { ingredient in
                            HStack {
                                Text(ingredient.name)
                                Spacer()
                                Text(NutritionFormat.calories(ingredient.macros.calories))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        .onDelete { viewModel.removeIngredients(at: $0) }
                    }
                }

                Section("Add ingredient") {
                    TextField("Ingredient name", text: $viewModel.ingName)
                    NutritionNumberField(title: "Calories", text: $viewModel.ingCaloriesText, unit: "cal")
                    NutritionNumberField(title: "Protein", text: $viewModel.ingProteinText, unit: "g")
                    NutritionNumberField(title: "Carbs", text: $viewModel.ingCarbsText, unit: "g")
                    NutritionNumberField(title: "Fat", text: $viewModel.ingFatText, unit: "g")
                    Button {
                        viewModel.addIngredient()
                    } label: {
                        Label("Add ingredient", systemImage: "plus")
                    }
                    .disabled(!viewModel.canAddIngredient)
                }

                if !viewModel.ingredients.isEmpty {
                    Section("Per serving") {
                        let per = viewModel.perServingPreview
                        LabeledContent("Calories", value: NutritionFormat.calories(per.calories))
                        LabeledContent("Protein", value: NutritionFormat.grams(per.proteinG))
                        LabeledContent("Carbs", value: NutritionFormat.grams(per.carbsG))
                        LabeledContent("Fat", value: NutritionFormat.grams(per.fatG))
                    }
                }
            }
            .navigationTitle("New recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let recipe = viewModel.makeRecipe() {
                            nutrition.saveRecipe(recipe)
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
        .tint(Theme.nutrition)
    }
}

// MARK: - Shared field

/// A trailing-aligned numeric entry row used by the editors.
struct NutritionNumberField: View {
    var title: String
    @Binding var text: String
    var unit: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 90)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        NutritionCustomFoodsView()
    }
    .withSampleStores()
}
