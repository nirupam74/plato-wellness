//
//  ProfileMeasurementSheets.swift
//  Wellness App
//
//  Sheets for logging a new weight and a full body measurement. Inputs are shown
//  in the user's unit system and converted back to metric before hitting the
//  store, which stores everything in metric.
//

import SwiftUI

// MARK: - Log weight

struct ProfileLogWeightView: View {
    @Environment(UserStore.self) private var user
    @Environment(\.dismiss) private var dismiss

    @State private var weight: Double = 70
    @State private var date = Date()

    private var system: UnitSystem { user.profile?.unitSystem ?? .metric }

    /// Weight in kg. A sane range keeps a fat-fingered entry (e.g. 700 for 70)
    /// from feeding a nonsensical value into the BMR and calorie targets.
    private var weightKg: Double { ProfileFormat.kg(fromDisplayWeight: weight, system: system) }
    private var isWeightSane: Bool { (20...500).contains(weightKg) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weight") {
                    HStack {
                        TextField("Weight", value: $weight, format: ProfileFormat.decimal)
                            .keyboardType(.decimalPad)
                        Text(ProfileFormat.weightUnitLabel(system))
                            .foregroundStyle(.secondary)
                    }
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                    if weightKg > 0 && !isWeightSane {
                        Text("Enter a realistic body weight.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if let current = user.profile?.currentWeightKg {
                    Section {
                        Text("Current: " + Units.displayWeight(kg: current, system: system))
                            .foregroundStyle(.secondary)
                    } footer: {
                        Text("Logging a weight updates your current weight. Review your targets afterward in Goals.")
                    }
                }
            }
            .navigationTitle("Log weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isWeightSane)
                }
            }
            .onAppear {
                if let current = user.profile?.currentWeightKg {
                    weight = ProfileFormat.weightDisplayValue(kg: current, system: system)
                }
            }
        }
    }

    private func save() {
        let kg = ProfileFormat.kg(fromDisplayWeight: weight, system: system)
        user.logWeight(kg, at: date)
        dismiss()
    }
}

// MARK: - Log measurement

struct ProfileLogMeasurementView: View {
    @Environment(UserStore.self) private var user
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var weight = ""
    @State private var bodyFat = ""
    @State private var waist = ""
    @State private var hips = ""
    @State private var chest = ""
    @State private var arm = ""
    @State private var thigh = ""
    @State private var neck = ""

    private var system: UnitSystem { user.profile?.unitSystem ?? .metric }
    private var weightUnit: String { ProfileFormat.weightUnitLabel(system) }
    private var lengthUnit: String { ProfileFormat.lengthUnitLabel(system) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                }

                Section("Body composition") {
                    field("Weight", text: $weight, unit: weightUnit)
                    field("Body fat", text: $bodyFat, unit: "%")
                }

                Section("Measurements") {
                    field("Waist", text: $waist, unit: lengthUnit)
                    field("Hips", text: $hips, unit: lengthUnit)
                    field("Chest", text: $chest, unit: lengthUnit)
                    field("Arm", text: $arm, unit: lengthUnit)
                    field("Thigh", text: $thigh, unit: lengthUnit)
                    field("Neck", text: $neck, unit: lengthUnit)
                }
            }
            .navigationTitle("Log measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!hasAnyValue)
                }
            }
        }
    }

    private func field(_ title: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 90)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .leading)
        }
    }

    private var hasAnyValue: Bool {
        [weight, bodyFat, waist, hips, chest, arm, thigh, neck]
            .contains { Double($0) != nil }
    }

    private func save() {
        func weightKg(_ s: String) -> Double? {
            Double(s).map { ProfileFormat.kg(fromDisplayWeight: $0, system: system) }
        }
        func lengthCm(_ s: String) -> Double? {
            Double(s).map { ProfileFormat.cm(fromDisplayLength: $0, system: system) }
        }

        let measurement = BodyMeasurement(
            weightKg: weightKg(weight),
            bodyFatPercent: Double(bodyFat),
            waistCm: lengthCm(waist),
            hipsCm: lengthCm(hips),
            chestCm: lengthCm(chest),
            armCm: lengthCm(arm),
            thighCm: lengthCm(thigh),
            neckCm: lengthCm(neck),
            recordedAt: date
        )
        user.addMeasurement(measurement)
        dismiss()
    }
}

#Preview("Log weight") {
    ProfileLogWeightView()
        .withSampleStores()
}

#Preview("Log measurement") {
    ProfileLogMeasurementView()
        .withSampleStores()
}
