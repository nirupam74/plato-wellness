//
//  ActivityViewModel.swift
//  Wellness App
//
//  Drives the Activity tab root: which logging sheet is open and how the recent
//  workout list is ordered. Store access stays in the view via the environment.
//

import Foundation
import Observation

@Observable
final class ActivityViewModel {
    /// The log sheet currently presented, if any.
    enum Sheet: String, Identifiable {
        case workout, sport, strength
        var id: String { rawValue }
    }

    var activeSheet: Sheet?

    func presentWorkout() { activeSheet = .workout }
    func presentSport() { activeSheet = .sport }
    func presentStrength() { activeSheet = .strength }

    /// Most recent workouts first, capped so the list stays scannable.
    func recentEntries(_ entries: [ActivityEntry], limit: Int = 30) -> [ActivityEntry] {
        Array(entries.sorted { $0.loggedAt > $1.loggedAt }.prefix(limit))
    }

    /// Today's entries, newest first. The main list resets each day; older
    /// workouts stay available in the history view.
    func todayEntries(_ entries: [ActivityEntry]) -> [ActivityEntry] {
        entries.filter { $0.loggedAt.isSameDay(as: Date()) }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    /// All entries grouped by day, most recent day first, for the history view.
    func entriesByDay(_ entries: [ActivityEntry]) -> [(day: Date, entries: [ActivityEntry])] {
        let groups = Dictionary(grouping: entries) { $0.loggedAt.startOfDay }
        return groups.keys.sorted(by: >).map { day in
            (day, groups[day]!.sorted { $0.loggedAt > $1.loggedAt })
        }
    }
}
