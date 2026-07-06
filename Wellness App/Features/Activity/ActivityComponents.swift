//
//  ActivityComponents.swift
//  Wellness App
//
//  Reusable pieces for the Activity tab: workout rows, the HealthKit badge,
//  the top summary and calories cards, and the sports intensity model. Built on
//  the shared design system (Card, MetricRing, StatTile, LabeledProgressBar).
//

import SwiftUI

// MARK: - Sports intensity

/// Recreational sport effort level. Scales the MET based calorie estimate so a
/// casual kickabout and a hard match log different burns for the same minutes.
enum ActivityIntensity: String, Codable, CaseIterable, Identifiable {
    case low, medium, high
    var id: String { rawValue }

    var label: String {
        switch self {
        case .low:    "Low"
        case .medium: "Medium"
        case .high:   "High"
        }
    }

    /// Multiplier applied to the base sport estimate.
    var multiplier: Double {
        switch self {
        case .low:    0.8
        case .medium: 1.0
        case .high:   1.25
        }
    }
}

// MARK: - HealthKit badge

/// Small marker so HealthKit sourced entries are visibly distinct from manual
/// logs and the user never double counts them.
struct ActivityHealthKitBadge: View {
    var body: some View {
        Label("Health", systemImage: "heart.fill")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.pink.opacity(0.15), in: Capsule())
            .foregroundStyle(.pink)
            .accessibilityLabel("Imported from Apple Health")
    }
}

// MARK: - Workout row

/// One workout in a list. Shows type icon, name, a HealthKit badge when
/// relevant, and calories plus duration on the trailing edge.
struct ActivityWorkoutRow: View {
    let entry: ActivityEntry

    private var subtitle: String {
        var parts: [String] = [entry.type.label]
        if let km = entry.distanceKm {
            parts.append(String(format: "%.1f km", km))
        }
        if let hr = entry.avgHeartRate {
            parts.append("\(hr) bpm")
        }
        return parts.joined(separator: " . ")
    }

    /// A short second line describing rich detail when present.
    private var detailSummary: String? {
        guard let details = entry.details else { return nil }
        if let s = details.sport {
            var parts = [s.intensity.label.lowercased()]
            parts.append(s.isOutdoor ? "outdoor \(s.venue.label.lowercased())" : "indoor \(s.venue.label.lowercased())")
            if s.participants > 0 { parts.append("\(s.participants) players") }
            if !s.position.isEmpty { parts.append(s.position) }
            return parts.joined(separator: " . ")
        }
        if let s = details.swim {
            var parts = [s.poolType.label]
            if let len = s.poolLengthM { parts.append("\(len) m") }
            parts.append(s.intensity.label.lowercased())
            return parts.joined(separator: " . ")
        }
        if let lifts = details.strength, !lifts.isEmpty {
            let sets = lifts.reduce(0) { $0 + $1.sets.count }
            return "\(lifts.count) exercises . \(sets) sets"
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.type.systemImage)
                .font(.title3)
                .foregroundStyle(Theme.activity)
                .frame(width: 40, height: 40)
                .background(Theme.activity.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.name)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                    if entry.fromHealthKit {
                        ActivityHealthKitBadge()
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let detailSummary {
                    Text(detailSummary)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.caloriesBurned) kcal")
                    .font(.subheadline.weight(.semibold))
                Text("\(entry.durationMin) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(entry.name), \(entry.type.label), \(entry.durationMin) minutes, \(entry.caloriesBurned) calories"
            + (entry.fromHealthKit ? ", from Apple Health" : "")
        )
    }
}

// MARK: - Today summary card

/// Steps toward goal plus active energy for today. Reads the stores directly so
/// it stays in sync wherever it is placed.
struct ActivitySummaryCard: View {
    @Environment(ActivityStore.self) private var activity
    @Environment(UserStore.self) private var user

    private var steps: Int { activity.todaySteps }
    private var stepGoal: Int { user.profile?.wellnessGoals.stepGoal ?? 10_000 }
    private var progress: Double {
        stepGoal > 0 ? Double(steps) / Double(stepGoal) : 0
    }
    private var remaining: Int { max(0, stepGoal - steps) }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderRow("Today's movement")

                HStack(spacing: 20) {
                    ZStack {
                        MetricRing(progress: progress, tint: Theme.activity, lineWidth: 12)
                            .frame(width: 96, height: 96)
                        VStack(spacing: 0) {
                            Text(steps.formatted())
                                .font(.title3.weight(.bold))
                                .contentTransition(.numericText())
                            Text("steps")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Steps")
                    .accessibilityValue("\(steps) of \(stepGoal) goal")

                    VStack(alignment: .leading, spacing: 12) {
                        StatTile(
                            title: "Active energy",
                            value: "\(activity.todayActiveEnergy) kcal",
                            systemImage: "flame.fill",
                            tint: Theme.activity
                        )
                        StatTile(
                            title: "Step goal",
                            value: stepGoal.formatted(),
                            systemImage: "target",
                            tint: Theme.activity
                        )
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    LabeledProgressBar(
                        value: Double(steps),
                        target: Double(stepGoal),
                        tint: Theme.activity
                    )
                    Text(remaining > 0
                         ? "\(remaining.formatted()) steps to go"
                         : "Step goal reached. Nice work.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Calories burned card

/// Total calories burned today, broken into the active energy and logged
/// workout contributions.
struct ActivityCaloriesCard: View {
    @Environment(ActivityStore.self) private var activity

    private var total: Int { activity.totalCaloriesBurned() }
    private var workouts: Int { activity.workoutCalories() }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeaderRow("Calories burned")

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Theme.activity)
                    Text("\(total)")
                        .font(.largeTitle.weight(.bold))
                        .contentTransition(.numericText())
                    Text("kcal today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    StatTile(
                        title: "Active energy",
                        value: "\(activity.todayActiveEnergy) kcal",
                        systemImage: "bolt.fill",
                        tint: Theme.activity
                    )
                    StatTile(
                        title: "Workouts",
                        value: "\(workouts) kcal",
                        systemImage: "figure.run",
                        tint: Theme.activity
                    )
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Calories burned today, \(total) kilocalories")
    }
}

#Preview("Cards") {
    ScrollView {
        VStack(spacing: 16) {
            ActivitySummaryCard()
            ActivityCaloriesCard()
        }
        .padding()
    }
    .withSampleStores()
}
