//
//  ProfileViewModel.swift
//  Wellness App
//
//  Aggregates cross-store figures for the Profile header and all-time stats.
//  The stores are read from the environment by the views and passed in, so the
//  view model stays free of the environment plumbing and easy to test.
//

import Foundation
import Observation

@Observable
final class ProfileViewModel {

    // MARK: - Logged days

    /// Every distinct calendar day on which the user logged anything across the
    /// four pillars: food, activity, water, sleep, or mood.
    func loggedDays(
        nutrition: NutritionStore,
        activity: ActivityStore,
        restore: RestoreStore
    ) -> Set<Date> {
        var days: Set<Date> = []
        nutrition.entries.forEach { days.insert($0.loggedAt.startOfDay) }
        activity.entries.forEach { days.insert($0.loggedAt.startOfDay) }
        restore.waterEntries.forEach { days.insert($0.loggedAt.startOfDay) }
        restore.sleepEntries.forEach { days.insert($0.wakeTime.startOfDay) }
        restore.moodEntries.forEach { days.insert($0.loggedAt.startOfDay) }
        restore.sessions.forEach { days.insert($0.completedAt.startOfDay) }
        return days
    }

    /// Total distinct days the user has logged anything.
    func totalDaysLogged(
        nutrition: NutritionStore,
        activity: ActivityStore,
        restore: RestoreStore
    ) -> Int {
        loggedDays(nutrition: nutrition, activity: activity, restore: restore).count
    }

    /// Current logging streak: consecutive days ending today (or yesterday, so a
    /// streak survives until the end of the day) with at least one log.
    func currentStreak(
        nutrition: NutritionStore,
        activity: ActivityStore,
        restore: RestoreStore
    ) -> Int {
        let days = loggedDays(nutrition: nutrition, activity: activity, restore: restore)
        guard !days.isEmpty else { return 0 }

        // Anchor on today if logged, otherwise yesterday, so the count does not
        // reset the moment midnight passes before the user logs.
        var cursor = Date().startOfDay
        if !days.contains(cursor) {
            cursor = cursor.adding(days: -1)
            guard days.contains(cursor) else { return 0 }
        }

        var streak = 0
        while days.contains(cursor) {
            streak += 1
            cursor = cursor.adding(days: -1)
        }
        return streak
    }

    /// The longest run of consecutive logged days in the whole history.
    func longestStreak(
        nutrition: NutritionStore,
        activity: ActivityStore,
        restore: RestoreStore
    ) -> Int {
        let days = loggedDays(nutrition: nutrition, activity: activity, restore: restore).sorted()
        guard !days.isEmpty else { return 0 }

        var longest = 1
        var run = 1
        for i in 1..<days.count {
            if days[i] == days[i - 1].adding(days: 1) {
                run += 1
                longest = max(longest, run)
            } else {
                run = 1
            }
        }
        return longest
    }
}
