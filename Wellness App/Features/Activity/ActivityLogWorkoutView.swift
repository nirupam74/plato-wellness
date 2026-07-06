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
    var swimIntensity: ActivityIntensity = .medium

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
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

    private func swimDetails() -> ActivityDetails? {
        guard isSwim else { return nil }
        let length = Int(poolLengthText)
        return ActivityDetails(swim: SwimDetails(
            poolType: poolType,
            poolLengthM: length.flatMap { $0 > 0 ? $0 : nil },
            laps: nil,
            intensity: swimIntensity
        ))
    }

    func makeEntry() -> ActivityEntry {
        let resolvedName = trimmedName.isEmpty ? type.label : trimmedName
        let distance = showsDistance ? Double(distanceText.replacingOccurrences(of: ",", with: ".")) : nil
        return ActivityEntry(
            type: type,
            name: resolvedName,
            durationMin: durationMin,
            caloriesBurned: max(0, caloriesBurned),
            distanceKm: distance.flatMap { $0 > 0 ? $0 : nil },
            avgHeartRate: Int(heartRateText).flatMap { $0 > 0 ? $0 : nil },
            details: swimDetails()
        )
    }
}

struct ActivityLogWorkoutView: View {
    @Environment(ActivityStore.self) private var activity
    @Environment(UserStore.self) private var user
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ActivityLogWorkoutViewModel()

    private var weightKg: Double { user.profile?.currentWeightKg ?? 70 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    Picker("Type", selection: $viewModel.type) {
                        ForEach(ActivityType.allCases) { type in
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

                if viewModel.showsDistance {
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
                    Section("Swim") {
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
                        Picker("Intensity", selection: $viewModel.swimIntensity) {
                            ForEach(ActivityIntensity.allCases) { level in
                                Text(level.label).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
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
            }
            .navigationTitle("Log workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        activity.add(viewModel.makeEntry())
                        Haptics.success()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
        .tint(Theme.activity)
    }
}

#Preview {
    ActivityLogWorkoutView()
        .withSampleStores()
}
