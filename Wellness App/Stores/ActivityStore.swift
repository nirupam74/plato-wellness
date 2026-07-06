//
//  ActivityStore.swift
//  Wellness App
//
//  Workout entries (Firestore) plus daily step / energy summaries (from HealthKit
//  later; empty in live mode until the HealthKitManager lands). Preview: seeded.
//

import Foundation
import Observation
import FirebaseFirestore

@Observable
final class ActivityStore {
    var entries: [ActivityEntry]
    var dailySummaries: [DailyActivitySummary]

    private let db = Firestore.firestore()
    private var uid: String?
    private var listeners: [ListenerRegistration] = []

    init(seeded: Bool = false) {
        self.entries = seeded ? SampleData.activityEntries() : []
        self.dailySummaries = seeded ? SampleData.dailyActivity() : []
    }

    // MARK: - Firestore binding

    func bind(uid: String?) {
        self.uid = uid
        listeners.forEach { $0.remove() }
        listeners = []

        guard let uid else {
            entries = []; dailySummaries = []
            return
        }
        // Steps and active energy come from HealthKit, wired later.
        dailySummaries = []
        listeners.append(
            db.collection("users/\(uid)/activityEntries").addSnapshotListener { [weak self] snap, _ in
                guard let snap else { return }
                self?.entries = snap.documents.compactMap { try? $0.data(as: ActivityEntry.self) }
            }
        )
    }

    // MARK: - Mutations

    func add(_ entry: ActivityEntry) {
        if let uid {
            try? db.collection("users/\(uid)/activityEntries").document(entry.id).setData(from: entry)
        } else {
            entries.append(entry)
        }
    }

    func remove(_ entry: ActivityEntry) {
        if let uid {
            db.collection("users/\(uid)/activityEntries").document(entry.id).delete()
        } else {
            entries.removeAll { $0.id == entry.id }
        }
    }

    // MARK: - Queries

    func entries(on date: Date = Date()) -> [ActivityEntry] {
        entries.filter { $0.loggedAt.isSameDay(as: date) }
    }

    func summary(on date: Date = Date()) -> DailyActivitySummary? {
        dailySummaries.first { $0.date.isSameDay(as: date) }
    }

    func workoutCalories(on date: Date = Date()) -> Int {
        entries(on: date).reduce(0) { $0 + $1.caloriesBurned }
    }

    func totalCaloriesBurned(on date: Date = Date()) -> Int {
        let s = summary(on: date)
        let base = (s?.activeEnergyKcal ?? 0) + (s?.basalEnergyKcal ?? 0)
        let manual = entries(on: date).filter { !$0.fromHealthKit }.reduce(0) { $0 + $1.caloriesBurned }
        return base + manual
    }

    var todaySteps: Int { summary(on: Date())?.steps ?? 0 }
    var todayActiveEnergy: Int { summary(on: Date())?.activeEnergyKcal ?? 0 }

    // MARK: - Trends

    func activeEnergySeries(lastDays days: Int) -> [(date: Date, kcal: Int)] {
        (0..<days).reversed().map { offset in
            let day = Date().adding(days: -offset)
            let workout = workoutCalories(on: day)
            let hk = summary(on: day)?.activeEnergyKcal ?? 0
            return (day, max(workout, hk))
        }
    }

    func stepSeries(lastDays days: Int) -> [(date: Date, steps: Int)] {
        (0..<days).reversed().map { offset in
            let day = Date().adding(days: -offset)
            return (day, summary(on: day)?.steps ?? 0)
        }
    }

    var weeklyVolumeMinutes: Int {
        let weekAgo = Date().adding(days: -7)
        return entries.filter { $0.loggedAt >= weekAgo }.reduce(0) { $0 + $1.durationMin }
    }

    var mostFrequentActivity: ActivityType? {
        let counts = Dictionary(grouping: entries, by: \.type).mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key
    }

    var personalBests: [(type: ActivityType, distanceKm: Double)] {
        Dictionary(grouping: entries.filter { $0.distanceKm != nil }, by: \.type)
            .compactMap { type, list in
                list.compactMap(\.distanceKm).max().map { (type, $0) }
            }
            .sorted { $0.distanceKm > $1.distanceKm }
    }

    var totalWorkouts: Int { entries.count }
    var lifetimeActiveEnergy: Int { dailySummaries.reduce(0) { $0 + $1.activeEnergyKcal } }
}
