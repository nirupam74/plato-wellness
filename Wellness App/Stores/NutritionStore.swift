//
//  NutritionStore.swift
//  Wellness App
//
//  Food diary, custom foods, and recipes. Live: Firestore under users/{uid}.
//  Preview: in-memory sample data when seeded (uid nil).
//

import Foundation
import Observation
import FirebaseFirestore

@Observable
final class NutritionStore {
    var entries: [FoodEntry]
    var customFoods: [CustomFood]
    var recipes: [Recipe]

    weak var healthKit: HealthKitManager?

    private let db = Firestore.firestore()
    private var uid: String?
    private var listeners: [ListenerRegistration] = []

    init(seeded: Bool = false) {
        self.entries = seeded ? SampleData.foodEntries() : []
        self.customFoods = seeded ? SampleData.customFoods() : []
        self.recipes = []
    }

    // MARK: - Firestore binding

    func bind(uid: String?) {
        self.uid = uid
        listeners.forEach { $0.remove() }
        listeners = []

        guard let uid else {
            entries = []; customFoods = []; recipes = []
            return
        }
        listeners.append(
            db.collection("users/\(uid)/foodEntries").addSnapshotListener { [weak self] snap, _ in
                guard let snap else { return }
                self?.entries = snap.documents.compactMap { try? $0.data(as: FoodEntry.self) }
            }
        )
        listeners.append(
            db.collection("users/\(uid)/customFoods").addSnapshotListener { [weak self] snap, _ in
                guard let snap else { return }
                self?.customFoods = snap.documents.compactMap { try? $0.data(as: CustomFood.self) }
            }
        )
        listeners.append(
            db.collection("users/\(uid)/recipes").addSnapshotListener { [weak self] snap, _ in
                guard let snap else { return }
                self?.recipes = snap.documents.compactMap { try? $0.data(as: Recipe.self) }
            }
        )
    }

    // MARK: - Mutations

    func add(_ entry: FoodEntry) {
        if let uid {
            try? db.collection("users/\(uid)/foodEntries").document(entry.id).setData(from: entry)
            healthKit?.saveDietary(entry)
        } else {
            entries.append(entry)
        }
    }

    func remove(_ entry: FoodEntry) {
        if let uid {
            db.collection("users/\(uid)/foodEntries").document(entry.id).delete()
        } else {
            entries.removeAll { $0.id == entry.id }
        }
    }

    func logCustomFood(_ food: CustomFood, meal: MealType, servings: Double = 1, at date: Date = Date()) {
        add(FoodEntry(
            name: food.name,
            mealType: meal,
            servings: servings,
            calories: food.calories,
            proteinG: food.proteinG,
            carbsG: food.carbsG,
            fatG: food.fatG,
            loggedAt: date,
            source: .favorite
        ))
    }

    func logRecipe(_ recipe: Recipe, meal: MealType, at date: Date = Date()) {
        let m = recipe.perServing
        add(FoodEntry(
            name: recipe.name,
            mealType: meal,
            calories: m.calories,
            proteinG: m.proteinG,
            carbsG: m.carbsG,
            fatG: m.fatG,
            loggedAt: date,
            source: .recipe
        ))
    }

    func saveCustomFood(_ food: CustomFood) {
        if let uid {
            try? db.collection("users/\(uid)/customFoods").document(food.id).setData(from: food)
        } else {
            customFoods.append(food)
        }
    }

    func saveRecipe(_ recipe: Recipe) {
        if let uid {
            try? db.collection("users/\(uid)/recipes").document(recipe.id).setData(from: recipe)
        } else {
            recipes.append(recipe)
        }
    }

    func toggleFavorite(_ food: CustomFood) {
        guard let i = customFoods.firstIndex(where: { $0.id == food.id }) else { return }
        var updated = customFoods[i]
        updated.isFavorite.toggle()
        if let uid {
            try? db.collection("users/\(uid)/customFoods").document(updated.id).setData(from: updated)
        } else {
            customFoods[i] = updated
        }
    }

    // MARK: - Queries

    func entries(on date: Date = Date()) -> [FoodEntry] {
        entries.filter { $0.loggedAt.isSameDay(as: date) }
    }

    func entries(for meal: MealType, on date: Date = Date()) -> [FoodEntry] {
        entries(on: date).filter { $0.mealType == meal }
    }

    func totals(on date: Date = Date()) -> MacroBreakdown {
        entries(on: date).reduce(.zero) { $0 + $1.totals }
    }

    func totals(for meal: MealType, on date: Date = Date()) -> MacroBreakdown {
        entries(for: meal, on: date).reduce(.zero) { $0 + $1.totals }
    }

    var todaysTotals: MacroBreakdown { totals(on: Date()) }

    var favorites: [CustomFood] { customFoods.filter(\.isFavorite) }

    var recents: [FoodEntry] {
        Array(entries.sorted { $0.loggedAt > $1.loggedAt }.prefix(10))
    }

    func dailyTotals(lastDays days: Int) -> [(date: Date, macros: MacroBreakdown)] {
        (0..<days).reversed().map { offset in
            let day = Date().adding(days: -offset)
            return (day, totals(on: day))
        }
    }

    func averageCalories(lastDays days: Int) -> Int {
        let totals = dailyTotals(lastDays: days).map(\.macros.calories)
        guard !totals.isEmpty else { return 0 }
        return totals.reduce(0, +) / totals.count
    }
}
