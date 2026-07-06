//
//  RestoreMoodView.swift
//  Wellness App
//
//  Mood and stress ritual: today's check in state plus a 2 week mood trend.
//

import SwiftUI
import Charts

struct RestoreMoodView: View {
    @Environment(RestoreStore.self) private var restore
    @State private var showingCheckIn = false

    private var today: MoodEntry? { restore.todayMood }
    private var series: [(date: Date, mood: Int)] { restore.moodSeries(lastDays: 14) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                todayCard
                trendCard
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Mood and stress")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCheckIn = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New mood check in")
            }
        }
        .sheet(isPresented: $showingCheckIn) {
            RestoreMoodCheckInSheet()
        }
        .tint(Theme.restore)
    }

    @ViewBuilder private var todayCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderRow("Today")
                if let today {
                    HStack(spacing: 12) {
                        RestoreMoodStat(title: "Mood", value: today.mood, symbol: "face.smiling")
                        if let s = today.stress {
                            RestoreMoodStat(title: "Stress", value: s, symbol: "wind")
                        }
                        if let e = today.energy {
                            RestoreMoodStat(title: "Energy", value: e, symbol: "bolt.fill")
                        }
                    }
                    if let note = today.note, !note.isEmpty {
                        Text("\u{201C}\(note)\u{201D}")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Button {
                        showingCheckIn = true
                    } label: {
                        Label("Update check in", systemImage: "square.and.pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else {
                    ContentUnavailableView {
                        Label("No check in yet today", systemImage: "face.dashed")
                    } description: {
                        Text("A quick check in helps you notice how you are really doing.")
                    } actions: {
                        Button("Check in now") { showingCheckIn = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }

    @ViewBuilder private var trendCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderRow("Last 2 weeks")
                if series.count >= 2 {
                    Chart {
                        ForEach(series, id: \.date) { point in
                            LineMark(
                                x: .value("Day", point.date, unit: .day),
                                y: .value("Mood", point.mood)
                            )
                            .foregroundStyle(Theme.restore)
                            .interpolationMethod(.catmullRom)
                            PointMark(
                                x: .value("Day", point.date, unit: .day),
                                y: .value("Mood", point.mood)
                            )
                            .foregroundStyle(Theme.restore)
                            .accessibilityLabel(point.date.formatted(.dateTime.weekday(.wide).month().day()))
                            .accessibilityValue("Mood \(point.mood) of 5")
                        }
                    }
                    .chartYScale(domain: 1...5)
                    .chartYAxisLabel("Mood")
                    .frame(height: 200)
                    .accessibilityLabel("Mood over the last 2 weeks")
                    .accessibilityValue(trendAccessibilityValue)
                } else {
                    ContentUnavailableView {
                        Label("Not enough check ins", systemImage: "chart.line.uptrend.xyaxis")
                    } description: {
                        Text("Check in a few days in a row to see your mood trend.")
                    }
                }
            }
        }
    }

    private var trendAccessibilityValue: String {
        guard !series.isEmpty else { return "No check ins" }
        let avg = Double(series.reduce(0) { $0 + $1.mood }) / Double(series.count)
        return String(format: "Average mood %.1f of 5 across %d days", avg, series.count)
    }
}

/// A compact mood/stress/energy value tile with a 1 to 5 readout.
struct RestoreMoodStat: View {
    var title: String
    var value: Int
    var symbol: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Theme.restore)
            Text("\(value)")
                .font(.title2.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.restore.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value) of 5")
    }
}

#Preview {
    NavigationStack {
        RestoreMoodView()
    }
    .withSampleStores()
}
