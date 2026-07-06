//
//  ActivitySportsView.swift
//  Wellness App
//
//  Rich sport logging: pick from a broad sport catalogue, capture the context
//  that affects effort (intensity, venue, indoor/outdoor, who you played with,
//  and position where it applies), see a live MET based estimate, and optionally
//  save the setup as a template to reuse next time.
//

import SwiftUI

@Observable
final class ActivitySportsViewModel {
    var sport: Sport = .soccer
    var durationMin: Int = 45
    var intensity: ActivityIntensity = .medium
    var venue: SportVenue = .field
    var isOutdoor: Bool = true
    var participants: Int = 0
    var position: String = ""
    var saveAsTemplate = false

    private(set) var editingID: String?
    private(set) var editingLoggedAt: Date?

    func load(_ entry: ActivityEntry) {
        editingID = entry.id
        editingLoggedAt = entry.loggedAt
        durationMin = entry.durationMin
        guard let s = entry.details?.sport else { return }
        sport = s.sport
        intensity = s.intensity
        venue = s.venue
        isOutdoor = s.isOutdoor
        participants = s.participants
        position = s.position
    }

    var canSave: Bool { durationMin > 0 }

    func estimatedBurn(weightKg: Double) -> Int {
        HealthMath.sportBurn(sport: sport, minutes: durationMin, weightKg: weightKg, intensity: intensity)
    }

    private func details() -> ActivityDetails {
        ActivityDetails(sport: SportDetails(
            sport: sport,
            intensity: intensity,
            venue: venue,
            isOutdoor: isOutdoor,
            participants: max(0, participants),
            position: position.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
    }

    func makeEntry(weightKg: Double) -> ActivityEntry {
        ActivityEntry(
            id: editingID ?? UUID().uuidString,
            type: .sport,
            name: sport.label,
            durationMin: durationMin,
            caloriesBurned: estimatedBurn(weightKg: weightKg),
            loggedAt: editingLoggedAt ?? Date(),
            details: details()
        )
    }

    func makeTemplate() -> ActivityTemplate {
        ActivityTemplate(name: sport.label, type: .sport, durationMin: durationMin, details: details())
    }

    func apply(_ template: ActivityTemplate) {
        durationMin = template.durationMin
        guard let s = template.details?.sport else { return }
        sport = s.sport
        intensity = s.intensity
        venue = s.venue
        isOutdoor = s.isOutdoor
        participants = s.participants
        position = s.position
    }
}

struct ActivitySportsView: View {
    @Environment(ActivityStore.self) private var activity
    @Environment(UserStore.self) private var user
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ActivitySportsViewModel()
    @State private var didLoad = false

    /// When set, the sheet edits this existing entry instead of creating one.
    var editing: ActivityEntry?

    private var weightKg: Double { user.profile?.currentWeightKg ?? 70 }
    private var savedSports: [ActivityTemplate] { activity.templates.filter { $0.type == .sport } }

    var body: some View {
        NavigationStack {
            Form {
                if !savedSports.isEmpty {
                    Section("Saved sports") {
                        ForEach(savedSports) { template in
                            Button {
                                viewModel.apply(template)
                                Haptics.tap()
                            } label: {
                                Label(templateLabel(template),
                                      systemImage: (template.details?.sport?.sport ?? .other).systemImage)
                            }
                        }
                        .onDelete { offsets in
                            offsets.map { savedSports[$0] }.forEach(activity.removeTemplate)
                        }
                    }
                }

                Section("Sport") {
                    Picker("Sport", selection: $viewModel.sport) {
                        ForEach(Sport.allCases) { sport in
                            Label(sport.label, systemImage: sport.systemImage).tag(sport)
                        }
                    }
                    .pickerStyle(.navigationLink)

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

                Section("Where") {
                    Picker("Venue", selection: $viewModel.venue) {
                        ForEach(SportVenue.allCases) { venue in
                            Text(venue.label).tag(venue)
                        }
                    }
                    Toggle("Outdoors", isOn: $viewModel.isOutdoor)
                }

                Section("Who") {
                    Stepper(value: $viewModel.participants, in: 0...50) {
                        LabeledContent("Played with",
                                       value: viewModel.participants == 0 ? "Solo / practice" : "\(viewModel.participants) people")
                    }
                    if viewModel.sport.usesPosition {
                        TextField("Position", text: $viewModel.position, prompt: Text("Forward, guard, pitcher..."))
                    }
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
                    Toggle("Save this sport to reuse", isOn: $viewModel.saveAsTemplate)
                } footer: {
                    Text("Estimated from the sport, duration, and intensity. You can refine it later.")
                }
            }
            .navigationTitle(editing == nil ? "Log sport" : "Edit sport")
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
        }
        .tint(Theme.activity)
    }

    private func templateLabel(_ template: ActivityTemplate) -> String {
        if let s = template.details?.sport {
            return "\(template.name) · \(s.intensity.label.lowercased()) · \(template.durationMin) min"
        }
        return "\(template.name) · \(template.durationMin) min"
    }

    private func save() {
        activity.add(viewModel.makeEntry(weightKg: weightKg))
        if viewModel.saveAsTemplate {
            activity.saveTemplate(viewModel.makeTemplate())
        }
        Haptics.success()
        dismiss()
    }
}

#Preview {
    ActivitySportsView()
        .withSampleStores()
}
