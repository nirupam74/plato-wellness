//
//  ProfileStatsView.swift
//  Wellness App
//
//  Lifetime totals across the four pillars, presented as a grid of stat tiles.
//

import SwiftUI

struct ProfileStatsView: View {
    @Environment(NutritionStore.self) private var nutrition
    @Environment(ActivityStore.self) private var activity
    @Environment(RestoreStore.self) private var restore
    @Environment(UserStore.self) private var user

    @State private var viewModel = ProfileViewModel()

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(tiles) { tile in
                    Card {
                        StatTile(title: tile.title,
                                 value: tile.value,
                                 systemImage: tile.systemImage,
                                 tint: tile.tint)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(tile.title): \(tile.value)")
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("All-time stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var tiles: [ProfileStatTile] {
        [
            ProfileStatTile(title: "Days logged",
                            value: "\(viewModel.totalDaysLogged(nutrition: nutrition, activity: activity, restore: restore))",
                            systemImage: "calendar",
                            tint: Theme.accent),
            ProfileStatTile(title: "Longest streak",
                            value: "\(viewModel.longestStreak(nutrition: nutrition, activity: activity, restore: restore)) days",
                            systemImage: "flame.fill",
                            tint: Theme.nutrition),
            ProfileStatTile(title: "Total workouts",
                            value: "\(activity.totalWorkouts)",
                            systemImage: "figure.run",
                            tint: Theme.activity),
            ProfileStatTile(title: "Active energy",
                            value: "\(energy) kcal",
                            systemImage: "bolt.fill",
                            tint: Theme.activity),
            ProfileStatTile(title: "Mindful minutes",
                            value: "\(restore.totalMindfulMinutes)",
                            systemImage: "brain.head.profile",
                            tint: Theme.restore),
            ProfileStatTile(title: "Meals logged",
                            value: "\(nutrition.entries.count)",
                            systemImage: "fork.knife",
                            tint: Theme.nutrition),
            ProfileStatTile(title: "Measurements",
                            value: "\(user.measurements.count)",
                            systemImage: "ruler",
                            tint: Theme.accent),
            ProfileStatTile(title: "Nights of sleep",
                            value: "\(restore.sleepEntries.count)",
                            systemImage: "bed.double.fill",
                            tint: Theme.restore),
        ]
    }

    private var energy: String {
        energyFormatter.string(from: NSNumber(value: activity.lifetimeActiveEnergy)) ?? "\(activity.lifetimeActiveEnergy)"
    }

    private let energyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()
}

private struct ProfileStatTile: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
}

#Preview {
    NavigationStack {
        ProfileStatsView()
    }
    .withSampleStores()
}
