//
//  ActivityModels.swift
//  Wellness App
//
//  Workout and step data. HealthKit sourced entries are flagged so the user
//  never double logs.
//

import Foundation

struct ActivityEntry: Codable, Identifiable {
    var id: String
    var type: ActivityType
    var name: String
    var durationMin: Int
    var caloriesBurned: Int
    var distanceKm: Double?
    var avgHeartRate: Int?
    var loggedAt: Date
    var fromHealthKit: Bool
    // Optional so entries saved before rich detail existed still decode.
    var details: ActivityDetails?

    init(
        id: String = UUID().uuidString,
        type: ActivityType,
        name: String,
        durationMin: Int,
        caloriesBurned: Int,
        distanceKm: Double? = nil,
        avgHeartRate: Int? = nil,
        loggedAt: Date = Date(),
        fromHealthKit: Bool = false,
        details: ActivityDetails? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.durationMin = durationMin
        self.caloriesBurned = caloriesBurned
        self.distanceKm = distanceKm
        self.avgHeartRate = avgHeartRate
        self.loggedAt = loggedAt
        self.fromHealthKit = fromHealthKit
        self.details = details
    }
}

/// A single day of step and active-energy data, sourced from HealthKit.
struct DailyActivitySummary: Codable, Identifiable {
    var id: String { ISO8601DateFormatter().string(from: date) }
    var date: Date
    var steps: Int
    var activeEnergyKcal: Int
    var basalEnergyKcal: Int

    var totalEnergyKcal: Int { activeEnergyKcal + basalEnergyKcal }
}
