//
//  BodyMeasurement.swift
//  Wellness App
//
//  Point-in-time body composition record used for progress tracking.
//

import Foundation

struct BodyMeasurement: Codable, Identifiable {
    var id: String
    var weightKg: Double?
    var bodyFatPercent: Double?
    var waistCm: Double?
    var hipsCm: Double?
    var chestCm: Double?
    var armCm: Double?
    var thighCm: Double?
    var neckCm: Double?
    var photoURL: String?
    var recordedAt: Date

    init(
        id: String = UUID().uuidString,
        weightKg: Double? = nil,
        bodyFatPercent: Double? = nil,
        waistCm: Double? = nil,
        hipsCm: Double? = nil,
        chestCm: Double? = nil,
        armCm: Double? = nil,
        thighCm: Double? = nil,
        neckCm: Double? = nil,
        photoURL: String? = nil,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.weightKg = weightKg
        self.bodyFatPercent = bodyFatPercent
        self.waistCm = waistCm
        self.hipsCm = hipsCm
        self.chestCm = chestCm
        self.armCm = armCm
        self.thighCm = thighCm
        self.neckCm = neckCm
        self.photoURL = photoURL
        self.recordedAt = recordedAt
    }
}
