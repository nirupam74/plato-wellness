//
//  RestoreViewModel.swift
//  Wellness App
//
//  Drives the Restore tab root: quick-add routing and small derived state for
//  the today rituals header. The heavy lifting lives in RestoreStore; this view
//  model only owns transient UI state.
//

import Observation

/// The sheets the nav-bar "+" quick-add can present.
enum RestoreQuickAdd: String, Identifiable, CaseIterable {
    case water, mood, sleep

    var id: String { rawValue }

    var label: String {
        switch self {
        case .water: "Log water"
        case .mood:  "Mood check in"
        case .sleep: "Log sleep"
        }
    }

    var systemImage: String {
        switch self {
        case .water: "drop.fill"
        case .mood:  "face.smiling"
        case .sleep: "bed.double.fill"
        }
    }
}

@Observable
final class RestoreViewModel {
    /// Currently presented quick-add sheet, if any.
    var activeQuickAdd: RestoreQuickAdd?

    func present(_ sheet: RestoreQuickAdd) { activeQuickAdd = sheet }

    /// Fraction of today's rituals that are done, for the header progress bar.
    func ritualProgress(_ rituals: [(name: String, done: Bool)]) -> Double {
        guard !rituals.isEmpty else { return 0 }
        let done = rituals.filter(\.done).count
        return Double(done) / Double(rituals.count)
    }

    func doneCount(_ rituals: [(name: String, done: Bool)]) -> Int {
        rituals.filter(\.done).count
    }
}
