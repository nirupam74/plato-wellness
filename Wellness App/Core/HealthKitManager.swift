//
//  HealthKitManager.swift
//  Wellness App
//
//  Reads device-measured metrics (steps, active and basal energy, sleep) and
//  writes user logs back to Apple Health (dietary energy and macros, water,
//  body mass, mindful minutes). Degrades gracefully when HealthKit is
//  unavailable or permission is denied: every read returns empty, every write
//  is a no-op, and the app keeps working on manual entry.
//

import Foundation
import Observation
import HealthKit

@Observable
final class HealthKitManager {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    var didRequestAuthorization = false

    // MARK: - Types

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        for id in [HKQuantityTypeIdentifier.stepCount, .activeEnergyBurned, .basalEnergyBurned,
                   .bodyMass, .bodyFatPercentage, .heartRate, .restingHeartRate] {
            if let t = HKQuantityType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        types.insert(HKObjectType.workoutType())
        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()
        for id in [HKQuantityTypeIdentifier.dietaryEnergyConsumed, .dietaryProtein,
                   .dietaryCarbohydrates, .dietaryFatTotal, .dietaryWater, .bodyMass] {
            if let t = HKQuantityType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        if let mindful = HKCategoryType.categoryType(forIdentifier: .mindfulSession) { types.insert(mindful) }
        return types
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isAvailable else { return }
        didRequestAuthorization = true
        try? await store.requestAuthorization(toShare: writeTypes, read: readTypes)
    }

    // MARK: - Reads

    /// Daily steps, active energy, and basal energy for the last `days` days.
    func loadActivitySummaries(days: Int) async -> [DailyActivitySummary] {
        guard isAvailable else { return [] }
        async let steps = dailySums(.stepCount, unit: .count(), days: days)
        async let active = dailySums(.activeEnergyBurned, unit: .kilocalorie(), days: days)
        async let basal = dailySums(.basalEnergyBurned, unit: .kilocalorie(), days: days)
        let (s, a, b) = await (steps, active, basal)

        let cal = Calendar.current
        return (0..<days).map { offset in
            let day = cal.startOfDay(for: Date().adding(days: -offset))
            return DailyActivitySummary(
                date: day,
                steps: Int(s[day] ?? 0),
                activeEnergyKcal: Int(a[day] ?? 0),
                basalEnergyKcal: Int(b[day] ?? 0)
            )
        }
    }

    private func dailySums(_ id: HKQuantityTypeIdentifier, unit: HKUnit, days: Int) async -> [Date: Double] {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return [:] }
        let cal = Calendar.current
        let end = Date()
        let anchor = cal.startOfDay(for: end.adding(days: -(days - 1)))

        return await withCheckedContinuation { cont in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: nil,
                options: .cumulativeSum,
                anchorDate: anchor,
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, results, _ in
                var map: [Date: Double] = [:]
                results?.enumerateStatistics(from: anchor, to: end) { stat, _ in
                    if let sum = stat.sumQuantity() {
                        map[cal.startOfDay(for: stat.startDate)] = sum.doubleValue(for: unit)
                    }
                }
                cont.resume(returning: map)
            }
            store.execute(query)
        }
    }

    /// Sleep nights for the last `days` days, with deterministic ids so repeated
    /// imports overwrite rather than duplicate.
    func loadSleep(days: Int) async -> [SleepEntry] {
        guard isAvailable, let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let start = Calendar.current.startOfDay(for: Date().adding(days: -days))
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())

        let samples: [HKCategorySample] = await withCheckedContinuation { cont in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, results, _ in
                cont.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
        ]
        let asleep = samples.filter { asleepValues.contains($0.value) }

        let cal = Calendar.current
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]

        var byNight: [Date: [HKCategorySample]] = [:]
        for sample in asleep {
            byNight[cal.startOfDay(for: sample.endDate), default: []].append(sample)
        }

        return byNight.compactMap { day, night in
            guard let bedtime = night.map(\.startDate).min(),
                  let wake = night.map(\.endDate).max() else { return nil }
            let minutes = night.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } / 60
            return SleepEntry(
                id: "hk-\(iso.string(from: day))",
                bedtime: bedtime,
                wakeTime: wake,
                durationMin: Int(minutes),
                quality: nil,
                fromHealthKit: true
            )
        }
    }

    // MARK: - Writes

    func saveDietary(_ entry: FoodEntry) {
        guard isAvailable else { return }
        var samples: [HKSample] = []
        func add(_ id: HKQuantityTypeIdentifier, _ unit: HKUnit, _ value: Double) {
            guard value > 0, let type = HKQuantityType.quantityType(forIdentifier: id) else { return }
            let quantity = HKQuantity(unit: unit, doubleValue: value)
            samples.append(HKQuantitySample(type: type, quantity: quantity, start: entry.loggedAt, end: entry.loggedAt))
        }
        let totals = entry.totals
        add(.dietaryEnergyConsumed, .kilocalorie(), Double(totals.calories))
        add(.dietaryProtein, .gram(), totals.proteinG)
        add(.dietaryCarbohydrates, .gram(), totals.carbsG)
        add(.dietaryFatTotal, .gram(), totals.fatG)
        guard !samples.isEmpty else { return }
        store.save(samples) { _, _ in }
    }

    func saveWater(ml: Int, date: Date) {
        guard isAvailable, let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: Double(ml))
        store.save(HKQuantitySample(type: type, quantity: quantity, start: date, end: date)) { _, _ in }
    }

    func saveMindful(minutes: Int, date: Date) {
        guard isAvailable, minutes > 0, let type = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return }
        let end = date
        let start = date.addingTimeInterval(-Double(minutes) * 60)
        let sample = HKCategorySample(type: type, value: HKCategoryValue.notApplicable.rawValue, start: start, end: end)
        store.save(sample) { _, _ in }
    }

    func saveWeight(kg: Double, date: Date) {
        guard isAvailable, let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        store.save(HKQuantitySample(type: type, quantity: quantity, start: date, end: date)) { _, _ in }
    }
}
