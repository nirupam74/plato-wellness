//
//  RestoreStore.swift
//  Wellness App
//
//  Self-care rituals: water, sleep, mood, sessions, skincare. Live: Firestore
//  under users/{uid}. Preview: seeded in-memory data (uid nil).
//

import Foundation
import Observation
import FirebaseFirestore

@Observable
final class RestoreStore {
    var waterEntries: [WaterEntry]
    var sleepEntries: [SleepEntry]
    var moodEntries: [MoodEntry]
    var sessions: [RestoreSession]
    var skincareSteps: [SkincareStep]
    var skincareLogs: [SkincareLog]

    weak var healthKit: HealthKitManager?

    private let db = Firestore.firestore()
    private var uid: String?
    private var listeners: [ListenerRegistration] = []

    init(seeded: Bool = false) {
        self.waterEntries = seeded ? SampleData.waterEntries() : []
        self.sleepEntries = seeded ? SampleData.sleepEntries() : []
        self.moodEntries = seeded ? SampleData.moodEntries() : []
        self.sessions = seeded ? SampleData.restoreSessions() : []
        self.skincareSteps = seeded ? SampleData.skincareSteps() : []
        self.skincareLogs = []
    }

    // MARK: - Firestore binding

    func bind(uid: String?) {
        self.uid = uid
        listeners.forEach { $0.remove() }
        listeners = []

        guard let uid else {
            waterEntries = []; sleepEntries = []; moodEntries = []
            sessions = []; skincareSteps = []; skincareLogs = []
            return
        }
        func col(_ name: String) -> CollectionReference { db.collection("users/\(uid)/\(name)") }

        listeners.append(col("waterEntries").order(by: "loggedAt", descending: true).limit(to: 800).addSnapshotListener { [weak self] snap, _ in
            self?.waterEntries = snap?.documents.compactMap { try? $0.data(as: WaterEntry.self) } ?? []
        })
        listeners.append(col("sleepEntries").order(by: "wakeTime", descending: true).limit(to: 400).addSnapshotListener { [weak self] snap, _ in
            self?.sleepEntries = snap?.documents.compactMap { try? $0.data(as: SleepEntry.self) } ?? []
        })
        listeners.append(col("moodEntries").order(by: "loggedAt", descending: true).limit(to: 400).addSnapshotListener { [weak self] snap, _ in
            self?.moodEntries = snap?.documents.compactMap { try? $0.data(as: MoodEntry.self) } ?? []
        })
        listeners.append(col("restoreSessions").order(by: "completedAt", descending: true).limit(to: 400).addSnapshotListener { [weak self] snap, _ in
            self?.sessions = snap?.documents.compactMap { try? $0.data(as: RestoreSession.self) } ?? []
        })
        listeners.append(col("skincareRoutine").addSnapshotListener { [weak self] snap, _ in
            self?.skincareSteps = snap?.documents.compactMap { try? $0.data(as: SkincareStep.self) } ?? []
        })
        listeners.append(col("skincareLogs").addSnapshotListener { [weak self] snap, _ in
            self?.skincareLogs = snap?.documents.compactMap { try? $0.data(as: SkincareLog.self) } ?? []
        })
    }

    private func doc(_ collection: String, _ id: String) -> DocumentReference? {
        guard let uid else { return nil }
        return db.collection("users/\(uid)/\(collection)").document(id)
    }

    // MARK: - Water

    func addWater(ml: Int, at date: Date = Date()) {
        let entry = WaterEntry(amountMl: ml, loggedAt: date)
        if let ref = doc("waterEntries", entry.id) {
            try? ref.setData(from: entry)
            healthKit?.saveWater(ml: ml, date: date)
        } else {
            waterEntries.append(entry)
        }
    }

    /// Write nights imported from Apple Health. Deterministic ids mean repeated
    /// imports overwrite rather than duplicate.
    func importHealthKitSleep(_ entries: [SleepEntry]) {
        guard uid != nil else { return }
        for entry in entries {
            if let ref = doc("sleepEntries", entry.id) {
                try? ref.setData(from: entry)
            }
        }
    }

    func waterTotal(on date: Date = Date()) -> Int {
        waterEntries.filter { $0.loggedAt.isSameDay(as: date) }.reduce(0) { $0 + $1.amountMl }
    }

    var todayWaterMl: Int { waterTotal(on: Date()) }

    // MARK: - Sleep

    func addSleep(_ entry: SleepEntry) {
        if let ref = doc("sleepEntries", entry.id) {
            try? ref.setData(from: entry)
        } else {
            sleepEntries.append(entry)
        }
    }

    func removeSleep(_ entry: SleepEntry) {
        if let ref = doc("sleepEntries", entry.id) {
            ref.delete()
        } else {
            sleepEntries.removeAll { $0.id == entry.id }
        }
    }

    var latestSleep: SleepEntry? { sleepEntries.sorted { $0.wakeTime > $1.wakeTime }.first }

    func sleepSeries(lastDays days: Int) -> [(date: Date, hours: Double)] {
        (0..<days).reversed().map { offset in
            let day = Date().adding(days: -offset)
            let entry = sleepEntries.first { $0.wakeTime.isSameDay(as: day) }
            return (day, entry?.durationHours ?? 0)
        }
    }

    // MARK: - Mood

    func addMood(_ entry: MoodEntry) {
        if let ref = doc("moodEntries", entry.id) {
            try? ref.setData(from: entry)
        } else {
            moodEntries.append(entry)
        }
    }

    func removeMood(_ entry: MoodEntry) {
        if let ref = doc("moodEntries", entry.id) {
            ref.delete()
        } else {
            moodEntries.removeAll { $0.id == entry.id }
        }
    }

    var todayMood: MoodEntry? { moodEntries.first { $0.loggedAt.isSameDay(as: Date()) } }

    func moodSeries(lastDays days: Int) -> [(date: Date, mood: Int)] {
        (0..<days).reversed().compactMap { offset in
            let day = Date().adding(days: -offset)
            guard let entry = moodEntries.first(where: { $0.loggedAt.isSameDay(as: day) }) else { return nil }
            return (day, entry.mood)
        }
    }

    // MARK: - Sessions

    func addSession(_ session: RestoreSession) {
        if let ref = doc("restoreSessions", session.id) {
            try? ref.setData(from: session)
            if session.writesMindfulMinutes {
                healthKit?.saveMindful(minutes: session.durationMin, date: session.completedAt)
            }
        } else {
            sessions.append(session)
        }
    }

    var totalMindfulMinutes: Int {
        sessions.filter(\.writesMindfulMinutes).reduce(0) { $0 + $1.durationMin }
    }

    func didSessionToday() -> Bool {
        sessions.contains { $0.completedAt.isSameDay(as: Date()) }
    }

    // MARK: - Skincare

    func steps(for time: RoutineTime) -> [SkincareStep] {
        skincareSteps.filter { $0.timeOfDay == time }.sorted { $0.order < $1.order }
    }

    func addStep(_ step: SkincareStep) {
        if let ref = doc("skincareRoutine", step.id) {
            try? ref.setData(from: step)
        } else {
            skincareSteps.append(step)
        }
    }

    func removeStep(_ step: SkincareStep) {
        if let ref = doc("skincareRoutine", step.id) {
            ref.delete()
        } else {
            skincareSteps.removeAll { $0.id == step.id }
        }
    }

    func log(for time: RoutineTime, on date: Date = Date()) -> SkincareLog? {
        skincareLogs.first { $0.timeOfDay == time && $0.date.isSameDay(as: date) }
    }

    func toggleStep(_ stepId: String, time: RoutineTime, on date: Date = Date()) {
        var entry = log(for: time, on: date) ?? SkincareLog(date: date, timeOfDay: time, completedStepIds: [])
        if let j = entry.completedStepIds.firstIndex(of: stepId) {
            entry.completedStepIds.remove(at: j)
        } else {
            entry.completedStepIds.append(stepId)
        }
        if let ref = doc("skincareLogs", entry.id) {
            try? ref.setData(from: entry)
        } else {
            skincareLogs.removeAll { $0.id == entry.id }
            skincareLogs.append(entry)
        }
    }

    func isStepComplete(_ stepId: String, time: RoutineTime, on date: Date = Date()) -> Bool {
        log(for: time, on: date)?.completedStepIds.contains(stepId) ?? false
    }

    var skincareStreak: Int {
        var streak = 0
        var day = Date()
        while true {
            let done = [RoutineTime.morning, .evening].allSatisfy { time in
                let defined = steps(for: time)
                guard !defined.isEmpty else { return true }
                let completed = log(for: time, on: day)?.completedStepIds ?? []
                return defined.allSatisfy { completed.contains($0.id) }
            }
            if done && (log(for: .morning, on: day) != nil || log(for: .evening, on: day) != nil) {
                streak += 1
                day = day.adding(days: -1)
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Today's rituals

    var todayRituals: [(name: String, done: Bool)] {
        let waterGoalMet = todayWaterMl > 0
        let moodDone = todayMood != nil
        let sessionDone = didSessionToday()
        let skincareDone = (log(for: .morning) != nil) || (log(for: .evening) != nil)
        return [
            ("Water", waterGoalMet),
            ("Mood check in", moodDone),
            ("Breathe or move", sessionDone),
            ("Skincare", skincareDone),
        ]
    }

    // MARK: - Correlations

    func moodSleepInsight() -> String? {
        let paired: [(sleep: Double, mood: Int)] = moodEntries.compactMap { mood in
            guard let sleep = sleepEntries.first(where: { $0.wakeTime.isSameDay(as: mood.loggedAt) }) else { return nil }
            return (sleep.durationHours, mood.mood)
        }
        guard paired.count >= 5 else { return nil }
        let longSleepMoods = paired.filter { $0.sleep >= 7 }.map(\.mood)
        let shortSleepMoods = paired.filter { $0.sleep < 7 }.map(\.mood)
        guard !longSleepMoods.isEmpty, !shortSleepMoods.isEmpty else { return nil }
        let longAvg = Double(longSleepMoods.reduce(0, +)) / Double(longSleepMoods.count)
        let shortAvg = Double(shortSleepMoods.reduce(0, +)) / Double(shortSleepMoods.count)
        if longAvg - shortAvg >= 0.5 {
            return "Your mood tends to be higher on days after 7 or more hours of sleep."
        }
        return nil
    }
}
