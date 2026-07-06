//
//  Wellness_Widget.swift
//  Wellness Widget
//
//  Home and lock screen widgets for Plato Wellness: a water tracker with a
//  one-tap quick-add and a today summary. Data comes from the shared App Group
//  the app writes to.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared App Group keys (must match the app's WidgetSync)

enum WidgetShared {
    static let suiteName = "group.com.platowellness.app"
    enum Key {
        static let waterMl = "w.waterMl"
        static let waterGoal = "w.waterGoal"
        static let calories = "w.calories"
        static let calorieTarget = "w.calorieTarget"
        static let steps = "w.steps"
        static let pendingWaterMl = "w.pendingWaterMl"
    }
}

private let accent = Color(red: 0.184, green: 0.42, blue: 1.0) // 0x2F6BFF

// MARK: - Entry & provider

struct WellnessEntry: TimelineEntry {
    let date: Date
    let waterMl: Int
    let waterGoal: Int
    let calories: Int
    let calorieTarget: Int
    let steps: Int

    var waterFraction: Double { min(1, Double(waterMl) / Double(max(1, waterGoal))) }
    var calorieFraction: Double { calorieTarget > 0 ? min(1, Double(calories) / Double(calorieTarget)) : 0 }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WellnessEntry {
        WellnessEntry(date: Date(), waterMl: 750, waterGoal: 2000, calories: 1200, calorieTarget: 2000, steps: 6200)
    }

    func getSnapshot(in context: Context, completion: @escaping (WellnessEntry) -> Void) {
        completion(read())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WellnessEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [read()], policy: .after(next)))
    }

    private func read() -> WellnessEntry {
        let d = UserDefaults(suiteName: WidgetShared.suiteName)
        return WellnessEntry(
            date: Date(),
            waterMl: d?.integer(forKey: WidgetShared.Key.waterMl) ?? 0,
            waterGoal: max(1, d?.integer(forKey: WidgetShared.Key.waterGoal) ?? 2000),
            calories: d?.integer(forKey: WidgetShared.Key.calories) ?? 0,
            calorieTarget: d?.integer(forKey: WidgetShared.Key.calorieTarget) ?? 0,
            steps: d?.integer(forKey: WidgetShared.Key.steps) ?? 0
        )
    }
}

// MARK: - Water widget

struct WaterWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PlatoWater", provider: Provider()) { entry in
            WaterWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Water")
        .description("Track water and add a glass in one tap.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct WaterWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WellnessEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: entry.waterFraction) {
                Image(systemName: "drop.fill")
            }
            .gaugeStyle(.accessoryCircularCapacity)

        default:
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Water", systemImage: "drop.fill").font(.caption.weight(.semibold)).foregroundStyle(accent)
                    Spacer()
                }
                Gauge(value: entry.waterFraction) {
                    EmptyView()
                } currentValueLabel: {
                    Text("\(entry.waterMl)")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .minimumScaleFactor(0.6)
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(accent)
                .frame(maxWidth: .infinity)

                Text("of \(entry.waterGoal) ml").font(.caption2).foregroundStyle(.secondary)

                Button(intent: LogWaterIntent()) {
                    Label("Glass", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
            }
        }
    }
}

// MARK: - Summary widget

struct SummaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PlatoSummary", provider: Provider()) { entry in
            SummaryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("Calories, steps, and water at a glance.")
        .supportedFamilies([.systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct SummaryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WellnessEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("\(entry.calories) kcal · \(entry.steps) steps")

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Today").font(.headline)
                Text("\(entry.calories) kcal · \(entry.steps) steps")
                Text("\(entry.waterMl) / \(entry.waterGoal) ml water").foregroundStyle(.secondary)
            }

        default:
            HStack(spacing: 14) {
                metric("Calories", "\(entry.calories)", entry.calorieTarget > 0 ? "of \(entry.calorieTarget)" : "kcal", "flame.fill")
                Divider()
                metric("Steps", entry.steps.formatted(), "today", "shoeprints.fill")
                Divider()
                metric("Water", "\(entry.waterMl)", "of \(entry.waterGoal) ml", "drop.fill")
            }
            .padding(4)
        }
    }

    private func metric(_ title: String, _ value: String, _ sub: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: symbol).font(.caption2.weight(.semibold)).foregroundStyle(accent)
            Text(value).font(.system(.title3, design: .rounded).weight(.bold)).minimumScaleFactor(0.6)
            Text(sub).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
