//
//  RestoreModels.swift
//  Wellness App
//
//  Self-care and mental-health data: sleep, mood, water, sessions, skincare.
//

import Foundation

struct WaterEntry: Codable, Identifiable {
    var id: String
    var amountMl: Int
    var loggedAt: Date

    init(id: String = UUID().uuidString, amountMl: Int, loggedAt: Date = Date()) {
        self.id = id
        self.amountMl = amountMl
        self.loggedAt = loggedAt
    }
}

struct SleepEntry: Codable, Identifiable {
    var id: String
    var bedtime: Date
    var wakeTime: Date
    var durationMin: Int
    var quality: Int?          // 1 to 5, self rated
    var fromHealthKit: Bool

    init(
        id: String = UUID().uuidString,
        bedtime: Date,
        wakeTime: Date,
        durationMin: Int? = nil,
        quality: Int? = nil,
        fromHealthKit: Bool = false
    ) {
        self.id = id
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.durationMin = durationMin ?? max(0, Int(wakeTime.timeIntervalSince(bedtime) / 60))
        self.quality = quality
        self.fromHealthKit = fromHealthKit
    }

    var durationHours: Double { Double(durationMin) / 60 }
}

struct MoodEntry: Codable, Identifiable {
    var id: String
    var mood: Int              // 1 to 5
    var stress: Int?           // 1 to 5
    var energy: Int?           // 1 to 5
    var note: String?
    var loggedAt: Date

    init(
        id: String = UUID().uuidString,
        mood: Int,
        stress: Int? = nil,
        energy: Int? = nil,
        note: String? = nil,
        loggedAt: Date = Date()
    ) {
        self.id = id
        self.mood = mood
        self.stress = stress
        self.energy = energy
        self.note = note
        self.loggedAt = loggedAt
    }
}

struct RestoreSession: Codable, Identifiable {
    var id: String
    var type: SessionType
    var name: String
    var durationMin: Int
    var completedAt: Date
    var writesMindfulMinutes: Bool

    init(
        id: String = UUID().uuidString,
        type: SessionType,
        name: String,
        durationMin: Int,
        completedAt: Date = Date(),
        writesMindfulMinutes: Bool = true
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.durationMin = durationMin
        self.completedAt = completedAt
        self.writesMindfulMinutes = writesMindfulMinutes
    }
}

struct SkincareStep: Codable, Identifiable {
    var id: String
    var name: String               // cleanser, toner, serum, moisturizer, SPF
    var timeOfDay: RoutineTime
    var order: Int

    init(id: String = UUID().uuidString, name: String, timeOfDay: RoutineTime, order: Int) {
        self.id = id
        self.name = name
        self.timeOfDay = timeOfDay
        self.order = order
    }
}

struct SkincareLog: Codable, Identifiable {
    var id: String
    var date: Date
    var timeOfDay: RoutineTime
    var completedStepIds: [String]

    init(id: String = UUID().uuidString, date: Date = Date(), timeOfDay: RoutineTime, completedStepIds: [String] = []) {
        self.id = id
        self.date = date
        self.timeOfDay = timeOfDay
        self.completedStepIds = completedStepIds
    }
}
