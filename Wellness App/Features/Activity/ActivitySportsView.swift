//
//  ActivitySportsView.swift
//  Wellness App
//
//  Quick logging for recreational sports. Duration plus a low / medium / high
//  intensity picker scales the MET based calorie estimate for ActivityType.sport.
//

import SwiftUI

@Observable
final class ActivitySportsViewModel {
    var name: String = ""
    var durationMin: Int = 45
    var intensity: ActivityIntensity = .medium

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool { durationMin > 0 }

    /// Base sport estimate scaled by the chosen intensity.
    func estimatedBurn(weightKg: Double) -> Int {
        let base = HealthMath.estimatedBurn(type: .sport, minutes: durationMin, weightKg: weightKg)
        return Int((Double(base) * intensity.multiplier).rounded())
    }

    func makeEntry(weightKg: Double) -> ActivityEntry {
        ActivityEntry(
            type: .sport,
            name: trimmedName.isEmpty ? "Sport" : trimmedName,
            durationMin: durationMin,
            caloriesBurned: estimatedBurn(weightKg: weightKg)
        )
    }
}

struct ActivitySportsView: View {
    @Environment(ActivityStore.self) private var activity
    @Environment(UserStore.self) private var user
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ActivitySportsViewModel()

    private var weightKg: Double { user.profile?.currentWeightKg ?? 70 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sport") {
                    TextField("Name", text: $viewModel.name, prompt: Text("Basketball, tennis, soccer..."))
                    Stepper(value: $viewModel.durationMin, in: 1...600, step: 5) {
                        LabeledContent("Duration", value: "\(viewModel.durationMin) min")
                    }
                }

                Section("Intensity") {
                    Picker("Intensity", selection: $viewModel.intensity) {
                        ForEach(ActivityIntensity.allCases) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    HStack {
                        Label("Estimated burn", systemImage: "flame.fill")
                            .foregroundStyle(Theme.activity)
                        Spacer()
                        Text("\(viewModel.estimatedBurn(weightKg: weightKg)) kcal")
                            .font(.headline)
                            .contentTransition(.numericText())
                    }
                } footer: {
                    Text("Estimated from duration and intensity. You can refine it later.")
                }
            }
            .navigationTitle("Log sport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        activity.add(viewModel.makeEntry(weightKg: weightKg))
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
    ActivitySportsView()
        .withSampleStores()
}
