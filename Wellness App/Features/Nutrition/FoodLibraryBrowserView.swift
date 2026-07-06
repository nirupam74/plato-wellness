//
//  FoodLibraryBrowserView.swift
//  Wellness App
//
//  Browse the built-in ingredient and meal catalogues, pick a portion (with a
//  unit and quantity for ingredients, or servings for meals), and hand the
//  scaled macros back to the caller. Used both to log straight into the diary
//  and to add ingredients while building a recipe.
//

import SwiftUI

struct FoodLibraryBrowserView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case ingredients, meals
        var id: String { rawValue }
        var label: String { self == .ingredients ? "Ingredients" : "Meals" }
    }

    var title: String = "Food database"
    /// Called with a portion-labelled name and its scaled macros.
    var onPick: (String, MacroBreakdown) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .ingredients
    @State private var query = ""
    @State private var selectedIngredient: LibraryIngredient?
    @State private var selectedMeal: LibraryMeal?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Type", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                if tab == .ingredients { ingredientList } else { mealList }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search foods")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $selectedIngredient) { ingredient in
                IngredientPortionSheet(ingredient: ingredient) { name, macros in
                    onPick(name, macros)
                    dismiss()
                }
            }
            .sheet(item: $selectedMeal) { meal in
                MealPortionSheet(meal: meal) { name, macros in
                    onPick(name, macros)
                    dismiss()
                }
            }
        }
        .tint(Theme.nutrition)
    }

    private var ingredientList: some View {
        List {
            ForEach(FoodGroup.allCases) { group in
                let items = FoodLibrary.ingredients(in: group).filter(matches)
                if !items.isEmpty {
                    Section(group.label) {
                        ForEach(items) { ingredient in
                            Button { selectedIngredient = ingredient } label: {
                                macroRow(name: ingredient.name,
                                         detail: "per 100 g",
                                         macros: ingredient.per100g)
                            }
                        }
                    }
                }
            }
        }
    }

    private var mealList: some View {
        List {
            ForEach(Cuisine.allCases) { cuisine in
                let items = FoodLibrary.meals(in: cuisine).filter(matches)
                if !items.isEmpty {
                    Section(cuisine.label) {
                        ForEach(items) { meal in
                            Button { selectedMeal = meal } label: {
                                macroRow(name: meal.name,
                                         detail: meal.servingLabel,
                                         macros: meal.perServing)
                            }
                        }
                    }
                }
            }
        }
    }

    private func matches(_ ingredient: LibraryIngredient) -> Bool {
        query.isEmpty || ingredient.name.localizedCaseInsensitiveContains(query)
    }
    private func matches(_ meal: LibraryMeal) -> Bool {
        query.isEmpty || meal.name.localizedCaseInsensitiveContains(query)
    }

    private func macroRow(name: String, detail: String, macros: MacroBreakdown) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).foregroundStyle(.primary)
                Text("\(macros.calories) cal · \(detail)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(macros.calories) calories \(detail)")
    }
}

// MARK: - Ingredient portion sheet

struct IngredientPortionSheet: View {
    let ingredient: LibraryIngredient
    var onAdd: (String, MacroBreakdown) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var quantity: Double
    @State private var unit: PortionUnit

    init(ingredient: LibraryIngredient, onAdd: @escaping (String, MacroBreakdown) -> Void) {
        self.ingredient = ingredient
        self.onAdd = onAdd
        let defaultUnit = ingredient.defaultUnit
        _unit = State(initialValue: defaultUnit)
        _quantity = State(initialValue: defaultUnit == .gram ? 100 : 1)
    }

    private var macros: MacroBreakdown { ingredient.macros(quantity: quantity, unit: unit) }

    private var quantityLabel: String {
        let q = quantity.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(quantity))
            : String(format: "%.2f", quantity)
        return "\(q) \(unit.short)"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Portion") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("Amount", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 90)
                    }
                    Picker("Unit", selection: $unit) {
                        ForEach(ingredient.units) { u in
                            Text(u.label).tag(u)
                        }
                    }
                    Stepper("Quick adjust", value: $quantity,
                            in: 0.25...5000,
                            step: unit == .gram ? 10 : 0.5)
                        .labelsHidden()
                }

                Section("Nutrition") {
                    macroLine("Calories", "\(macros.calories)")
                    macroLine("Protein", String(format: "%.1f g", macros.proteinG))
                    macroLine("Carbs", String(format: "%.1f g", macros.carbsG))
                    macroLine("Fat", String(format: "%.1f g", macros.fatG))
                }
            }
            .navigationTitle(ingredient.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd("\(ingredient.name) (\(quantityLabel))", macros)
                    }
                    .disabled(quantity <= 0)
                }
            }
        }
        .tint(Theme.nutrition)
    }

    private func macroLine(_ title: String, _ value: String) -> some View {
        LabeledContent(title, value: value)
            .monospacedDigit()
    }
}

// MARK: - Meal portion sheet

struct MealPortionSheet: View {
    let meal: LibraryMeal
    var onAdd: (String, MacroBreakdown) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var servings: Double = 1

    private var macros: MacroBreakdown { meal.macros(servings: servings) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Servings") {
                    Stepper(value: $servings, in: 0.5...20, step: 0.5) {
                        LabeledContent("Servings", value: servingsText)
                    }
                    Text("One serving is \(meal.servingLabel).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Nutrition") {
                    LabeledContent("Calories", value: "\(macros.calories)").monospacedDigit()
                    LabeledContent("Protein", value: String(format: "%.1f g", macros.proteinG)).monospacedDigit()
                    LabeledContent("Carbs", value: String(format: "%.1f g", macros.carbsG)).monospacedDigit()
                    LabeledContent("Fat", value: String(format: "%.1f g", macros.fatG)).monospacedDigit()
                }
            }
            .navigationTitle(meal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let name = servings == 1 ? meal.name : "\(meal.name) (\(servingsText))"
                        onAdd(name, macros)
                    }
                }
            }
        }
        .tint(Theme.nutrition)
    }

    private var servingsText: String {
        servings.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(servings))" : String(format: "%.1f", servings)
    }
}
