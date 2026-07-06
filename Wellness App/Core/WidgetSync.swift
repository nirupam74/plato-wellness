//
//  WidgetSync.swift
//  Wellness App
//
//  Bridges today's numbers to the home/lock-screen widgets through the shared
//  App Group, and applies any water the user logged from a widget. The widget
//  target reads the same suite and keys.
//

import Foundation
import WidgetKit

enum WidgetSync {
    static let suiteName = "group.com.platowellness.app"

    enum Key {
        static let waterMl = "w.waterMl"
        static let waterGoal = "w.waterGoal"
        static let calories = "w.calories"
        static let calorieTarget = "w.calorieTarget"
        static let steps = "w.steps"
        static let pendingWaterMl = "w.pendingWaterMl"
        static let updatedAt = "w.updatedAt"
    }

    private static var defaults: UserDefaults? { UserDefaults(suiteName: suiteName) }

    /// Write today's snapshot for the widgets and refresh them.
    static func publish(waterMl: Int, waterGoal: Int, calories: Int, calorieTarget: Int, steps: Int) {
        guard let d = defaults else { return }
        d.set(waterMl, forKey: Key.waterMl)
        d.set(max(1, waterGoal), forKey: Key.waterGoal)
        d.set(calories, forKey: Key.calories)
        d.set(calorieTarget, forKey: Key.calorieTarget)
        d.set(steps, forKey: Key.steps)
        d.set(Date().timeIntervalSince1970, forKey: Key.updatedAt)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Millilitres of water queued by the widget quick-add, cleared on read.
    static func consumePendingWater() -> Int {
        guard let d = defaults else { return 0 }
        let ml = d.integer(forKey: Key.pendingWaterMl)
        if ml != 0 { d.set(0, forKey: Key.pendingWaterMl) }
        return ml
    }
}
