//
//  ActivityStrengthView.swift
//  Wellness App
//
//  Full strength-training logging: add exercises from a grouped catalogue, then
//  record each set's reps, weight, and rest. Weight is shown in the user's unit
//  and stored in kg. The session can be saved as a template to repeat.
//

import SwiftUI

@Observable
final class ActivityStrengthViewModel {
    var exercises: [StrengthEntry] = []
    var durationMin: Int = 45
    var intensity: ActivityIntensity = .medium
    let feedback = SessionFeedbackDraft()
    var saveAsTemplate = false

    /// Set when editing an existing entry so Save overwrites it in place.
    private(set) var editingID: String?
    private(set) var editingLoggedAt: Date?

    /// Load an existing strength entry for editing.
    func load(_ entry: ActivityEntry) {
        editingID = entry.id
        editingLoggedAt = entry.loggedAt
        durationMin = entry.durationMin
        exercises = entry.details?.strength ?? []
        feedback.load(entry.details?.feedback)
    }

    var canSave: Bool { durationMin > 0 && !exercises.isEmpty }

    func addExercise(_ exercise: GymExercise) {
        exercises.append(StrengthEntry(exercise: exercise))
    }

    func addSet(toExerciseAt index: Int) {
        guard exercises.indices.contains(index) else { return }
        let last = exercises[index].sets.last
        exercises[index].sets.append(StrengthSet(
            reps: last?.reps ?? 10,
            weightKg: last?.weightKg ?? 0,
            restSec: last?.restSec ?? 90
        ))
    }

    func estimatedBurn(weightKg: Double) -> Int {
        HealthMath.strengthBurn(exercises: exercises, minutes: durationMin, weightKg: weightKg, intensity: intensity)
    }

    var totalVolumeKg: Double { exercises.reduce(0) { $0 + $1.volumeKg } }
    var totalSets: Int { exercises.reduce(0) { $0 + $1.sets.count } }

    var sessionName: String {
        let groups = Set(exercises.map { $0.exercise.group.label })
        if groups.count == 1, let only = groups.first { return "\(only) strength" }
        return "Strength training"
    }

    private func details() -> ActivityDetails {
        ActivityDetails(strength: exercises, feedback: feedback.model())
    }

    func makeEntry(weightKg: Double) -> ActivityEntry {
        ActivityEntry(
            id: editingID ?? UUID().uuidString,
            type: .strength,
            name: sessionName,
            durationMin: durationMin,
            caloriesBurned: estimatedBurn(weightKg: weightKg),
            loggedAt: editingLoggedAt ?? Date(),
            details: details()
        )
    }

    func makeTemplate() -> ActivityTemplate {
        ActivityTemplate(name: sessionName, type: .strength, durationMin: durationMin,
                         details: ActivityDetails(strength: exercises))
    }

    func apply(_ template: ActivityTemplate) {
        durationMin = template.durationMin
        exercises = template.details?.strength ?? []
    }
}

struct ActivityStrengthView: View {
    @Environment(ActivityStore.self) private var activity
    @Environment(UserStore.self) private var user
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ActivityStrengthViewModel()
    @State private var showingExercisePicker = false
    @State private var didLoad = false
    @State private var reminder: ActivityAdvisory?

    /// When set, the sheet edits this existing entry instead of creating one.
    var editing: ActivityEntry?

    private var system: UnitSystem { user.profile?.unitSystem ?? .metric }
    private var weightKg: Double { user.profile?.currentWeightKg ?? 70 }
    private var savedStrength: [ActivityTemplate] { activity.templates.filter { $0.type == .strength } }

    var body: some View {
        NavigationStack {
            Form {
                if let reminder {
                    Section { ActivityAdvisoryBanner(advisory: reminder) }
                }

                if !savedStrength.isEmpty {
                    Section("Saved workouts") {
                        ForEach(savedStrength) { template in
                            Button {
                                viewModel.apply(template)
                                Haptics.tap()
                            } label: {
                                Label("\(template.name) · \(template.durationMin) min", systemImage: "dumbbell")
                            }
                        }
                        .onDelete { offsets in
                            offsets.map { savedStrength[$0] }.forEach(activity.removeTemplate)
                        }
                    }
                }

                Section("Session") {
                    Stepper(value: $viewModel.durationMin, in: 1...300, step: 5) {
                        LabeledContent("Duration", value: "\(viewModel.durationMin) min")
                    }
                    Picker("Intensity", selection: $viewModel.intensity) {
                        ForEach(ActivityIntensity.allCases) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                ForEach($viewModel.exercises) { $entry in
                    Section {
                        ForEach(Array($entry.sets.enumerated()), id: \.element.id) { index, $set in
                            setRow(number: index + 1, set: $set)
                        }
                        .onDelete { offsets in
                            $entry.sets.wrappedValue.remove(atOffsets: offsets)
                        }

                        Button {
                            if let i = viewModel.exercises.firstIndex(where: { $0.id == entry.id }) {
                                viewModel.addSet(toExerciseAt: i)
                            }
                        } label: {
                            Label("Add set", systemImage: "plus.circle")
                        }
                    } header: {
                        HStack {
                            Text(entry.exercise.label)
                            Spacer()
                            Text(entry.exercise.group.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    viewModel.exercises.remove(atOffsets: offsets)
                }

                Section {
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add exercise", systemImage: "plus")
                    }
                }

                SessionFeedbackSection(draft: viewModel.feedback)

                Section {
                    HStack {
                        Label("Estimated burn", systemImage: "flame.fill")
                            .foregroundStyle(Theme.activity)
                        Spacer()
                        Text("\(viewModel.estimatedBurn(weightKg: weightKg)) kcal")
                            .font(.headline)
                            .contentTransition(.numericText())
                    }
                    if !viewModel.exercises.isEmpty {
                        LabeledContent("Total volume",
                                       value: "\(ProfileFormat.decimal.format(ProfileFormat.weightDisplayValue(kg: viewModel.totalVolumeKg, system: system))) \(ProfileFormat.weightUnitLabel(system)) · \(viewModel.totalSets) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Toggle("Save this workout to reuse", isOn: $viewModel.saveAsTemplate)
                } footer: {
                    Text("The estimate is the sum of your session time, total volume (weight times reps), and total reps, so every set you add changes it.")
                }
            }
            .navigationTitle(editing == nil ? "Log strength" : "Edit strength")
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
            .sheet(isPresented: $showingExercisePicker) {
                GymExercisePicker { exercise in
                    viewModel.addExercise(exercise)
                }
            }
            .onAppear {
                if let editing, !didLoad {
                    viewModel.load(editing)
                    didLoad = true
                }
                if reminder == nil, editing == nil, let r = activity.pendingReminder(for: .strength) {
                    reminder = r
                    activity.markReminded(r)
                }
            }
        }
        .tint(Theme.activity)
    }

    private func setRow(number: Int, set: Binding<StrengthSet>) -> some View {
        HStack(spacing: 10) {
            Text("Set \(number)")
                .font(.subheadline.weight(.medium))
                .frame(width: 52, alignment: .leading)

            VStack(spacing: 2) {
                TextField("0", value: set.reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                Text("reps").font(.caption2).foregroundStyle(.secondary)
            }

            VStack(spacing: 2) {
                TextField("0", value: weightBinding(set), format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                Text(ProfileFormat.weightUnitLabel(system)).font(.caption2).foregroundStyle(.secondary)
            }

            VStack(spacing: 2) {
                TextField("0", value: set.restSec, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                Text("rest s").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Set \(number)")
        .accessibilityValue("\(set.wrappedValue.reps) reps at \(Int(set.wrappedValue.weightKg)) kilograms, \(set.wrappedValue.restSec) seconds rest")
    }

    /// Shows and edits set weight in the user's unit while storing kilograms.
    private func weightBinding(_ set: Binding<StrengthSet>) -> Binding<Double> {
        Binding(
            get: { ProfileFormat.weightDisplayValue(kg: set.wrappedValue.weightKg, system: system) },
            set: { set.wrappedValue.weightKg = max(0, ProfileFormat.kg(fromDisplayWeight: $0, system: system)) }
        )
    }

    private func save() {
        activity.add(viewModel.makeEntry(weightKg: weightKg))
        if viewModel.saveAsTemplate {
            activity.saveTemplate(viewModel.makeTemplate())
        }
        activity.recordAdvisories(from: viewModel.feedback.model(), activityType: .strength)
        Haptics.success()
        dismiss()
    }
}

// MARK: - Exercise picker

struct GymExercisePicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    var onPick: (GymExercise) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(MuscleGroup.allCases) { group in
                    let items = GymExercise.inGroup(group).filter {
                        query.isEmpty || $0.label.localizedCaseInsensitiveContains(query)
                    }
                    if !items.isEmpty {
                        Section(group.label) {
                            ForEach(items) { exercise in
                                Button {
                                    onPick(exercise)
                                    Haptics.tap()
                                    dismiss()
                                } label: {
                                    Text(exercise.label)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search exercises")
            .navigationTitle("Add exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .tint(Theme.activity)
    }
}

#Preview {
    ActivityStrengthView()
        .withSampleStores()
}
