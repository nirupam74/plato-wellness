//
//  RestoreSleepView.swift
//  Wellness App
//
//  Sleep ritual: latest duration vs the user's goal, a 2 week trend chart, and
//  manual logging. HealthKit import is stubbed for a later phase.
//

import SwiftUI
import Charts

struct RestoreSleepView: View {
    @Environment(RestoreStore.self) private var restore
    @Environment(UserStore.self) private var user
    @State private var showingLog = false

    private var goalHours: Double { user.profile?.wellnessGoals.sleepHours ?? 8 }
    private var latest: SleepEntry? { restore.latestSleep }
    private var series: [(date: Date, hours: Double)] { restore.sleepSeries(lastDays: 14) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                trendCard
                importCard
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Sleep")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingLog = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Log sleep")
            }
        }
        .sheet(isPresented: $showingLog) {
            RestoreSleepLogSheet()
        }
        .tint(Theme.restore)
    }

    @ViewBuilder private var summaryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderRow("Last night")
                if let latest {
                    HStack(spacing: 16) {
                        ZStack {
                            MetricRing(progress: latest.durationHours / max(goalHours, 1), tint: Theme.restore)
                                .frame(width: 88, height: 88)
                            VStack(spacing: 0) {
                                Text(String(format: "%.1f", latest.durationHours))
                                    .font(.title2.weight(.bold))
                                Text("hours").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Slept \(String(format: "%.1f", latest.durationHours)) hours of a \(String(format: "%.0f", goalHours)) hour goal")

                        VStack(alignment: .leading, spacing: 10) {
                            StatTile(
                                title: "Goal",
                                value: String(format: "%.0f h", goalHours),
                                systemImage: "target",
                                tint: Theme.restore
                            )
                            if let q = latest.quality {
                                StatTile(
                                    title: "Quality",
                                    value: "\(q) of 5",
                                    systemImage: "star.fill",
                                    tint: Theme.restore
                                )
                            }
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("No sleep logged yet", systemImage: "bed.double")
                    } description: {
                        Text("Log last night's sleep to see how you are tracking toward your goal.")
                    }
                }
            }
        }
    }

    @ViewBuilder private var trendCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderRow("Last 2 weeks")
                if series.contains(where: { $0.hours > 0 }) {
                    Chart {
                        ForEach(series, id: \.date) { point in
                            BarMark(
                                x: .value("Day", point.date, unit: .day),
                                y: .value("Hours", point.hours)
                            )
                            .foregroundStyle(Theme.restore.gradient)
                            .cornerRadius(4)
                            .accessibilityLabel(point.date.formatted(.dateTime.weekday(.wide).month().day()))
                            .accessibilityValue(point.hours > 0 ? String(format: "%.1f hours", point.hours) : "No sleep logged")
                        }
                        RuleMark(y: .value("Goal", goalHours))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(.secondary)
                            .annotation(position: .top, alignment: .leading) {
                                Text("Goal \(String(format: "%.0f h", goalHours))")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                    }
                    .chartYAxisLabel("Hours")
                    .frame(height: 200)
                    .accessibilityLabel("Sleep hours over the last 2 weeks")
                    .accessibilityValue(trendAccessibilityValue)
                } else {
                    ContentUnavailableView {
                        Label("No trend yet", systemImage: "chart.bar")
                    } description: {
                        Text("A couple of nights of sleep will fill in this chart.")
                    }
                }
            }
        }
    }

    @ViewBuilder private var importCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeaderRow("Apple Health")
                Text("Importing sleep from Apple Health is coming in a later update. For now, add nights manually.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    // Stub: HealthKit import wires in during a later phase.
                } label: {
                    Label("Import from Apple Health", systemImage: "heart.text.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(true)
            }
        }
    }

    private var trendAccessibilityValue: String {
        let logged = series.filter { $0.hours > 0 }
        guard !logged.isEmpty else { return "No nights logged" }
        let avg = logged.reduce(0) { $0 + $1.hours } / Double(logged.count)
        return String(format: "Average %.1f hours across %d nights", avg, logged.count)
    }
}

#Preview {
    NavigationStack {
        RestoreSleepView()
    }
    .withSampleStores()
}
