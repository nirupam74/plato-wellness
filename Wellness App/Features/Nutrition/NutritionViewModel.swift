//
//  NutritionViewModel.swift
//  Wellness App
//
//  Presentation state for the diary root: which sheet is up and which meal a
//  quick-add should default to. Derived totals are read from the store in the
//  view, so this stays focused on transient UI state.
//

import Observation

@Observable
final class NutritionViewModel {
    /// Whether the add-food sheet is presented.
    var showingAddFood = false

    /// Meal the add-food sheet should open on (set by the quick-add buttons).
    var quickAddMeal: MealType = .breakfast

    func presentAddFood(for meal: MealType = .breakfast) {
        quickAddMeal = meal
        showingAddFood = true
    }
}
