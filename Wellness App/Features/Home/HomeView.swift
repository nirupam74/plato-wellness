//
//  HomeView.swift
//  Wellness App
//
//  The first tab: a warm welcome and a single-glance summary of everything the
//  user has done today across Nutrition, Activity, and Restore. Each card taps
//  through to its tab.
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(UserStore.self) private var user
    @Environment(NutritionStore.self) private var nutrition
    @Environment(ActivityStore.self) private var activity
    @Environment(RestoreStore.self) private var restore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    nutritionCard
                    activityCard
                    restoreCard
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Home")
        }
    }

    // MARK: - Header

    private var header: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.title2.weight(.bold))
                Text(summaryLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var greeting: String {
        let name = user.profile?.firstName ?? ""
        let hour = Calendar.current.component(.hour, from: Date())
        let part = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        return name.isEmpty ? part : "\(part), \(name)"
    }

    private var summaryLine: String {
        var done: [String] = []
        let meals = nutrition.entries(on: Date()).count
        if meals > 0 { done.append("\(meals) \(meals == 1 ? "item" : "items") logged") }
        let workouts = activity.entries(on: Date()).count
        if workouts > 0 { done.append("\(workouts) \(workouts == 1 ? "workout" : "workouts")") }
        if restore.todayWaterMl > 0 { done.append("\(restore.todayWaterMl) ml water") }
        if restore.todayMood != nil { done.append("mood checked in") }
        if done.isEmpty { return "Here's your day. Log something to get started." }
        return "Today so far: " + done.joined(separator: " · ") + "."
    }

    // MARK: - Nutrition

    private var nutritionCard: some View {
        let totals = nutrition.totals(on: Date())
        let targets = user.profile?.targets
        return Button {
            appState.selectedTab = .nutrition
        } label: {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    cardHeader("Nutrition", systemImage: "fork.knife", tint: Theme.nutrition)
                    if let targets, targets.calories > 0 {
                        LabeledContent("Calories", value: "\(totals.calories) / \(targets.calories) kcal")
                            .font(.subheadline)
                        LabeledProgressBar(value: Double(totals.calories), target: Double(targets.calories), tint: Theme.nutrition)
                        HStack(spacing: 12) {
                            macroTile("Protein", totals.proteinG, targets.proteinG)
                            macroTile("Carbs", totals.carbsG, targets.carbsG)
                            macroTile("Fat", totals.fatG, targets.fatG)
                        }
                    } else {
                        Text("\(totals.calories) kcal logged today")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func macroTile(_ title: String, _ value: Double, _ target: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(target > 0 ? "\(Int(value))/\(target) g" : "\(Int(value)) g")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Activity

    private var activityCard: some View {
        let steps = activity.todaySteps
        let stepGoal = user.profile?.wellnessGoals.stepGoal ?? 0
        let workoutCals = activity.workoutCalories(on: Date())
        return Button {
            appState.selectedTab = .activity
        } label: {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    cardHeader("Activity", systemImage: "figure.run", tint: Theme.activity)
                    HStack(spacing: 12) {
                        StatTile(title: "Steps", value: steps.formatted(), systemImage: "shoeprints.fill", tint: Theme.activity)
                        StatTile(title: "Workout kcal", value: "\(workoutCals)", systemImage: "flame.fill", tint: Theme.activity)
                        StatTile(title: "Active kcal", value: "\(activity.todayActiveEnergy)", systemImage: "bolt.fill", tint: Theme.activity)
                    }
                    if stepGoal > 0 {
                        LabeledProgressBar(value: Double(steps), target: Double(stepGoal), tint: Theme.activity)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Restore

    private var restoreCard: some View {
        let water = restore.todayWaterMl
        let waterGoal = user.profile?.targets.waterMl ?? 0
        let sleep = restore.latestSleep
        let mindful = todayMindfulMinutes
        return Button {
            appState.selectedTab = .restore
        } label: {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    cardHeader("Restore", systemImage: "moon.stars.fill", tint: Theme.restore)
                    HStack(spacing: 12) {
                        StatTile(title: "Water", value: "\(water) ml", systemImage: "drop.fill", tint: Theme.restore)
                        StatTile(title: "Last sleep",
                                 value: sleep.map { String(format: "%.1f h", $0.durationHours) } ?? "--",
                                 systemImage: "bed.double.fill", tint: Theme.restore)
                        StatTile(title: "Mood",
                                 value: restore.todayMood.map { "\($0.mood)/5" } ?? "--",
                                 systemImage: "face.smiling", tint: Theme.restore)
                    }
                    if waterGoal > 0 {
                        LabeledProgressBar(value: Double(water), target: Double(waterGoal), tint: Theme.restore)
                    }
                    if mindful > 0 {
                        Text("\(mindful) mindful minutes today")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var todayMindfulMinutes: Int {
        restore.sessions
            .filter { $0.writesMindfulMinutes && $0.completedAt.isSameDay(as: Date()) }
            .reduce(0) { $0 + $1.durationMin }
    }

    // MARK: - Shared

    private func cardHeader(_ title: String, systemImage: String, tint: Color) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    HomeView()
        .withSampleStores()
}
