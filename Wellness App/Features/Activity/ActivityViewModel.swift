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
        case workout, sport
        var id: String { rawValue }
    }

    var activeSheet: Sheet?

    func presentWorkout() { activeSheet = .workout }
    func presentSport() { activeSheet = .sport }

    /// Most recent workouts first, capped so the list stays scannable.
    func recentEntries(_ entries: [ActivityEntry], limit: Int = 30) -> [ActivityEntry] {
        Array(entries.sorted { $0.loggedAt > $1.loggedAt }.prefix(limit))
    }
}
