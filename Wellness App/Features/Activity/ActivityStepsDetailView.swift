//
//  ActivityStepsDetailView.swift
//  Wellness App
//
//  Daily steps versus goal and daily active energy over the last two weeks,
//  drawn with Swift Charts.
//

import SwiftUI
import Charts

struct ActivityStepsDetailView: View {
    @Environment(ActivityStore.self) private var activity
    @Environment(UserStore.self) private var user

    private let days = 14

    private var stepData: [(date: Date, steps: Int)] {
        activity.stepSeries(lastDays: days)
    }
    private var energyData: [(date: Date, kcal: Int)] {
        activity.activeEnergySeries(lastDays: days)
    }
    private var stepGoal: Int { user.profile?.wellnessGoals.stepGoal ?? 10_000 }

    private var averageSteps: Int {
        guard !stepData.isEmpty else { return 0 }
        return stepData.reduce(0) { $0 + $1.steps } / stepData.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                stepsCard
                energyCard
            }
            .padding()
        }
        .navigationTitle("Steps & energy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var stepsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderRow(title: "Steps") {
                    Text("Avg \(averageSteps.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Chart {
                    ForEach(stepData, id: \.date) { item in
                        BarMark(
                            x: .value("Day", item.date, unit: .day),
                            y: .value("Steps", item.steps)
                        )
                        .foregroundStyle(Theme.activity.gradient)
                        .cornerRadius(4)
                    }
                    RuleMark(y: .value("Goal", stepGoal))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        .foregroundStyle(.secondary)
                        .annotation(position: .top, alignment: .leading) {
                            Text("Goal \(stepGoal.formatted())")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(height: 200)
                .chartYAxis { AxisMarks(position: .leading) }
                .accessibilityLabel("Daily steps for the last \(days) days")
                .accessibilityValue("Average \(averageSteps) steps against a goal of \(stepGoal)")
            }
        }
    }

    private var energyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderRow("Active energy")

                Chart {
                    ForEach(energyData, id: \.date) { item in
                        BarMark(
                            x: .value("Day", item.date, unit: .day),
                            y: .value("Active energy", item.kcal)
                        )
                        .foregroundStyle(Theme.activity.opacity(0.7).gradient)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 180)
                .chartYAxis { AxisMarks(position: .leading) }
                .accessibilityLabel("Daily active energy in kilocalories for the last \(days) days")

                Text("Active energy is the higher of your logged workouts and HealthKit for each day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ActivityStepsDetailView()
    }
    .withSampleStores()
}
