//
//  ProfileExporter.swift
//  Wellness App
//
//  Serializes the in-memory stores to a JSON or CSV file the user can share.
//  This produces real output from live data. When Firestore lands, the same
//  snapshot can be assembled from the fetched records.
//

import Foundation

// MARK: - Format

enum ProfileExportFormat: String, CaseIterable, Identifiable {
    case json, csv

    var id: String { rawValue }
    var label: String { rawValue.uppercased() }

    var fileExtension: String { rawValue }

    var systemImage: String {
        switch self {
        case .json: "curlybraces"
        case .csv:  "tablecells"
        }
    }

    var detail: String {
        switch self {
        case .json: "Complete structured backup of every record."
        case .csv:  "Spreadsheet-friendly tables, one section per log type."
        }
    }
}

// MARK: - Snapshot (Codable)

/// A single Codable bundle of everything the user has logged. Encoded directly
/// for JSON export.
struct ProfileExportSnapshot: Codable {
    var exportedAt: Date
    var profile: UserProfile?
    var measurements: [BodyMeasurement]
    var foodEntries: [FoodEntry]
    var activityEntries: [ActivityEntry]
    var dailyActivity: [DailyActivitySummary]
    var waterEntries: [WaterEntry]
    var sleepEntries: [SleepEntry]
    var moodEntries: [MoodEntry]
    var restoreSessions: [RestoreSession]
}

// MARK: - Exporter

struct ProfileExporter {
    let user: UserStore
    let nutrition: NutritionStore
    let activity: ActivityStore
    let restore: RestoreStore

    // MARK: Snapshot assembly

    func snapshot() -> ProfileExportSnapshot {
        ProfileExportSnapshot(
            exportedAt: Date(),
            profile: user.profile,
            measurements: user.measurements,
            foodEntries: nutrition.entries,
            activityEntries: activity.entries,
            dailyActivity: activity.dailySummaries,
            waterEntries: restore.waterEntries,
            sleepEntries: restore.sleepEntries,
            moodEntries: restore.moodEntries,
            restoreSessions: restore.sessions
        )
    }

    // MARK: JSON

    func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot())
    }

    // MARK: CSV

    /// A multi-section CSV. Each log type is its own table with a title line and
    /// header row, sections separated by a blank line.
    func csvString() -> String {
        let iso = ISO8601DateFormatter()
        var out = ""

        func section(_ title: String, header: [String], rows: [[String]]) {
            out += "# \(title)\n"
            out += header.map(csvField).joined(separator: ",") + "\n"
            for row in rows {
                out += row.map(csvField).joined(separator: ",") + "\n"
            }
            out += "\n"
        }

        section("Food entries",
                header: ["date", "meal", "name", "servings", "calories", "protein_g", "carbs_g", "fat_g", "source"],
                rows: nutrition.entries.sorted { $0.loggedAt < $1.loggedAt }.map { e in
                    [iso.string(from: e.loggedAt), e.mealType.rawValue, e.name,
                     num(e.servings), "\(e.calories)", num(e.proteinG), num(e.carbsG), num(e.fatG),
                     e.source.rawValue]
                })

        section("Activity entries",
                header: ["date", "type", "name", "duration_min", "calories_burned", "distance_km", "avg_hr", "from_healthkit"],
                rows: activity.entries.sorted { $0.loggedAt < $1.loggedAt }.map { a in
                    [iso.string(from: a.loggedAt), a.type.rawValue, a.name,
                     "\(a.durationMin)", "\(a.caloriesBurned)",
                     a.distanceKm.map(num) ?? "", a.avgHeartRate.map { "\($0)" } ?? "",
                     "\(a.fromHealthKit)"]
                })

        section("Daily activity",
                header: ["date", "steps", "active_kcal", "basal_kcal"],
                rows: activity.dailySummaries.sorted { $0.date < $1.date }.map { s in
                    [iso.string(from: s.date), "\(s.steps)", "\(s.activeEnergyKcal)", "\(s.basalEnergyKcal)"]
                })

        section("Water entries",
                header: ["date", "amount_ml"],
                rows: restore.waterEntries.sorted { $0.loggedAt < $1.loggedAt }.map { w in
                    [iso.string(from: w.loggedAt), "\(w.amountMl)"]
                })

        section("Sleep entries",
                header: ["bedtime", "wake_time", "duration_min", "quality"],
                rows: restore.sleepEntries.sorted { $0.wakeTime < $1.wakeTime }.map { s in
                    [iso.string(from: s.bedtime), iso.string(from: s.wakeTime),
                     "\(s.durationMin)", s.quality.map { "\($0)" } ?? ""]
                })

        section("Mood entries",
                header: ["date", "mood", "stress", "energy", "note"],
                rows: restore.moodEntries.sorted { $0.loggedAt < $1.loggedAt }.map { m in
                    [iso.string(from: m.loggedAt), "\(m.mood)",
                     m.stress.map { "\($0)" } ?? "", m.energy.map { "\($0)" } ?? "", m.note ?? ""]
                })

        section("Mindful sessions",
                header: ["date", "type", "name", "duration_min"],
                rows: restore.sessions.sorted { $0.completedAt < $1.completedAt }.map { s in
                    [iso.string(from: s.completedAt), s.type.rawValue, s.name, "\(s.durationMin)"]
                })

        section("Body measurements",
                header: ["date", "weight_kg", "body_fat_pct", "waist_cm", "hips_cm", "chest_cm", "arm_cm", "thigh_cm", "neck_cm"],
                rows: user.measurements.sorted { $0.recordedAt < $1.recordedAt }.map { m in
                    [iso.string(from: m.recordedAt),
                     m.weightKg.map(num) ?? "", m.bodyFatPercent.map(num) ?? "",
                     m.waistCm.map(num) ?? "", m.hipsCm.map(num) ?? "", m.chestCm.map(num) ?? "",
                     m.armCm.map(num) ?? "", m.thighCm.map(num) ?? "", m.neckCm.map(num) ?? ""]
                })

        return out
    }

    // MARK: File output

    /// Write the chosen format to a temporary file and return its URL, ready for
    /// a `ShareLink`.
    func exportFile(format: ProfileExportFormat) throws -> URL {
        let data: Data
        switch format {
        case .json: data = try jsonData()
        case .csv:  data = Data(csvString().utf8)
        }

        let stamp = Self.stampFormatter.string(from: Date())
        let name = "wellness-export-\(stamp).\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: Helpers

    private func num(_ value: Double) -> String {
        String(format: "%g", value)
    }

    /// Escape a CSV field per RFC 4180 when it contains a comma, quote, or newline.
    private func csvField(_ raw: String) -> String {
        guard raw.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else {
            return raw
        }
        return "\"" + raw.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static let stampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmmss"
        return f
    }()
}
