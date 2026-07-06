//
//  ActivityTrendsView.swift
//  Wellness App
//
//  History and trends: weekly training volume, most frequent activity, personal
//  bests, and an active energy chart over a selectable week or month range.
//

import SwiftUI
import Charts

/// Selectable window for the trends chart.
enum ActivityTimeRange: String, CaseIterable, Identifiable {
    case week, month
    var id: String { rawValue }
    var label: String { self == .week ? "Week" : "Month" }
    var days: Int { self == .week ? 7 : 30 }
}

@Observable
final class ActivityTrendsViewModel {
    var range: ActivityTimeRange = .week
}

struct ActivityTrendsView: View {
    @Environment(ActivityStore.self) private var activity
    @State private var viewModel = ActivityTrendsViewModel()

    private var energyData: [(date: Date, kcal: Int)] {
        activity.activeEnergySeries(lastDays: viewModel.range.days)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                rangePicker
                highlightsCard
                energyCard
                mostFrequentCard
                personalBestsCard
            }
            .padding()
        }
        .navigationTitle("History & trends")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var rangePicker: some View {
        Picker("Range", selection: $viewModel.range) {
            ForEach(ActivityTimeRange.allCases) { range in
                Text(range.label).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private var highlightsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderRow("This week")
                HStack(spacing: 12) {
                    StatTile(
                        title: "Training volume",
                        value: "\(activity.weeklyVolumeMinutes) min",
                        systemImage: "clock.fill",
                        tint: Theme.activity
                    )
                    StatTile(
                        title: "Total workouts",
                        value: "\(activity.totalWorkouts)",
                        systemImage: "list.bullet",
                        tint: Theme.activity
                    )
                }
            }
        }
    }

    private var energyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderRow(title: "Active energy") {
                    Text(viewModel.range.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Chart {
                    ForEach(energyData, id: \.date) { item in
                        LineMark(
                            x: .value("Day", item.date, unit: .day),
                            y: .value("Active energy", item.kcal)
                        )
                        .foregroundStyle(Theme.activity)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Day", item.date, unit: .day),
                            y: .value("Active energy", item.kcal)
                        )
                        .foregroundStyle(Theme.activity.opacity(0.15).gradient)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .chartYAxis { AxisMarks(position: .leading) }
                .accessibilityLabel("Active energy in kilocalories over the last \(viewModel.range.days) days")
            }
        }
    }

    private var mostFrequentCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderRow("Most frequent")
                if let type = activity.mostFrequentActivity {
                    HStack(spacing: 12) {
                        Image(systemName: type.systemImage)
                            .font(.title2)
                            .foregroundStyle(Theme.activity)
                            .frame(width: 44, height: 44)
                            .background(Theme.activity.opacity(0.15), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.label).font(.body.weight(.semibold))
                            Text("Your go-to activity").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                } else {
                    Text("Log a few workouts to see your favorite.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var personalBestsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderRow("Personal bests")
                let bests = activity.personalBests
                if bests.isEmpty {
                    ContentUnavailableView {
                        Label("No distances yet", systemImage: "trophy")
                    } description: {
                        Text("Log a run, ride, walk, or swim with a distance to set a best.")
                    }
                } else {
                    ForEach(bests, id: \.type) { best in
                        HStack {
                            Label(best.type.label, systemImage: best.type.systemImage)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(String(format: "%.1f km", best.distanceKm))
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Theme.activity)
                        }
                        .accessibilityElement(children: .combine)
                        if best.type != bests.last?.type {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ActivityTrendsView()
    }
    .withSampleStores()
}
