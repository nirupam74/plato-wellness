//
//  ActivityLogWorkoutView.swift
//  Wellness App
//
//  Sheet for logging a structured workout: type, name, duration, calories (with
//  a MET based Estimate), and optional distance and average heart rate.
//

import SwiftUI

@Observable
final class ActivityLogWorkoutViewModel {
    var type: ActivityType = .run
    var name: String = ""
    var durationMin: Int = 30
    var caloriesBurned: Int = 0
    var distanceText: String = ""
    var heartRateText: String = ""

    // Swim specifics, used when type == .swim.
    var poolType: PoolType = .indoorPool
    var poolLengthText: String = ""
    var lapsText: String = ""
    var swimIntensity: ActivityIntensity = .medium

    let feedback = SessionFeedbackDraft()

    // Set when editing an existing entry so Save overwrites it in place.
    private(set) var editingID: String?
    private(set) var editingLoggedAt: Date?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Load an existing (non sport/strength) entry for editing.
    func load(_ entry: ActivityEntry) {
        editingID = entry.id
        editingLoggedAt = entry.loggedAt
        type = entry.type
        name = entry.name
        durationMin = entry.durationMin
        caloriesBurned = entry.caloriesBurned
        distanceText = entry.distanceKm.map { String(format: "%.2f", $0) } ?? ""
        heartRateText = entry.avgHeartRate.map(String.init) ?? ""
        feedback.load(entry.details?.feedback)
        if let swim = entry.details?.swim {
            poolType = swim.poolType
            poolLengthText = swim.poolLengthM.map(String.init) ?? ""
            lapsText = swim.laps.map(String.init) ?? ""
            swimIntensity = swim.intensity
        }
    }

    /// Distance computed from pool length and laps, when both are provided.
    var derivedSwimKm: Double? {
        guard isSwim,
              let length = Int(poolLengthText), length > 0,
              let laps = Int(lapsText), laps > 0 else { return nil }
        return Double(length * laps) / 1000.0
    }

    /// Distance only makes sense for the distance based activities.
    var showsDistance: Bool {
        switch type {
        case .run, .ride, .walk, .swim: true
        default: false
        }
    }

    var isSwim: Bool { type == .swim }

    var canSave: Bool { durationMin > 0 }

    /// Fill calories from the MET estimate for the current type and duration.
    func estimate(weightKg: Double) {
        if isSwim {
            caloriesBurned = HealthMath.swimBurn(
                minutes: durationMin,
                weightKg: weightKg,
                intensity: swimIntensity,
                openWater: poolType == .openWater
            )
        } else {
            caloriesBurned = HealthMath.estimatedBurn(
                type: type,
                minutes: durationMin,
                weightKg: weightKg
            )
        }
    }

    private func details() -> ActivityDetails? {
        let swim: SwimDetails? = isSwim ? SwimDetails(
            poolType: poolType,
            poolLengthM: Int(poolLengthText).flatMap { $0 > 0 ? $0 : nil },
            laps: Int(lapsText).flatMap { $0 > 0 ? $0 : nil },
            intensity: swimIntensity
        ) : nil
        let result = ActivityDetails(swim: swim, feedback: feedback.model())
        return result.isEmpty ? nil : result
    }

    func makeEntry() -> ActivityEntry {
        let resolvedName = trimmedName.isEmpty ? type.label : trimmedName
        // Swim distance derives from pool length x laps when available.
        let manualDistance = showsDistance ? Double(distanceText.replacingOccurrences(of: ",", with: ".")) : nil
        let distance = derivedSwimKm ?? manualDistance
        return ActivityEntry(
            id: editingID ?? UUID().uuidString,
            type: type,
            name: resolvedName,
            durationMin: durationMin,
            caloriesBurned: max(0, caloriesBurned),
            distanceKm: distance.flatMap { $0 > 0 ? $0 : nil },
            avgHeartRate: Int(heartRateText).flatMap { $0 > 0 ? $0 : nil },
            loggedAt: editingLoggedAt ?? Date(),
            details: details()
        )
    }
}

struct ActivityLogWorkoutView: View {
    @Environment(ActivityStore.self) private var activity
    @Environment(UserStore.self) private var user
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ActivityLogWorkoutViewModel()
    @State private var didLoad = false
    @State private var reminder: ActivityAdvisory?

    /// When set, the sheet edits this existing entry instead of creating one.
    var editing: ActivityEntry?

    private var weightKg: Double { user.profile?.currentWeightKg ?? 70 }

    var body: some View {
        NavigationStack {
            Form {
                if let reminder {
                    Section { ActivityAdvisoryBanner(advisory: reminder) }
                }

                Section("Activity") {
                    Picker("Type", selection: $viewModel.type) {
                        ForEach(ActivityType.workoutLoggable) { type in
                            Label(type.label, systemImage: type.systemImage).tag(type)
                        }
                    }
                    TextField("Name", text: $viewModel.name, prompt: Text(viewModel.type.label))
                }

                Section("Effort") {
                    Stepper(value: $viewModel.durationMin, in: 1...600, step: 5) {
                        LabeledContent("Duration", value: "\(viewModel.durationMin) min")
                    }

                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", value: $viewModel.caloriesBurned, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80)
                        Text("kcal").foregroundStyle(.secondary)
                    }

                    Button {
                        viewModel.estimate(weightKg: weightKg)
                    } label: {
                        Label("Estimate from duration", systemImage: "wand.and.stars")
                    }
                }

                if viewModel.showsDistance && !viewModel.isSwim {
                    Section("Distance") {
                        HStack {
                            Text("Distance")
                            Spacer()
                            TextField("0.0", text: $viewModel.distanceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 80)
                            Text("km").foregroundStyle(.secondary)
                        }
                    }
                }

                if viewModel.isSwim {
                    Section {
                        Picker("Water", selection: $viewModel.poolType) {
                            ForEach(PoolType.allCases) { type in
                                Text(type.label).tag(type)
                            }
                        }
                        HStack {
                            Text("Pool length")
                            Spacer()
                            TextField("Optional", text: $viewModel.poolLengthText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 80)
                            Text("m").foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Laps")
                            Spacer()
                            TextField("Optional", text: $viewModel.lapsText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 80)
                        }
                        Picker("Intensity", selection: $viewModel.swimIntensity) {
                            ForEach(ActivityIntensity.allCases) { level in
                                Text(level.label).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Swim")
                    } footer: {
                        if let km = viewModel.derivedSwimKm {
                            Text(String(format: "Distance from laps: %.2f km (%.0f m).", km, km * 1000))
                        } else {
                            Text("Enter pool length and laps and we'll calculate the distance.")
                        }
                    }
                }

                Section("Heart rate") {
                    HStack {
                        Text("Average")
                        Spacer()
                        TextField("Optional", text: $viewModel.heartRateText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 90)
                        Text("bpm").foregroundStyle(.secondary)
                    }
                }

                SessionFeedbackSection(draft: viewModel.feedback)
            }
            .navigationTitle(editing == nil ? "Log workout" : "Edit workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "Save" : "Update") { save() }
                        .disabled(!viewModel.canSave)
                }
            }
            .onAppear {
                if let editing, !didLoad {
                    viewModel.load(editing)
                    didLoad = true
                }
            }
            .onChange(of: viewModel.type, initial: true) { _, newType in
                guard editing == nil else { return }
                if let r = activity.pendingReminder(for: newType) {
                    reminder = r
                    activity.markReminded(r)
                } else if reminder?.activityType != newType {
                    reminder = nil
                }
            }
        }
        .tint(Theme.activity)
    }

    private func save() {
        activity.add(viewModel.makeEntry())
        activity.recordAdvisories(from: viewModel.feedback.model(), activityType: viewModel.type)
        Haptics.success()
        dismiss()
    }
}

#Preview {
    ActivityLogWorkoutView()
        .withSampleStores()
}
