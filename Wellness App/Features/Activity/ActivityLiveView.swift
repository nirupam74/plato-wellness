//
//  ActivityLiveView.swift
//  Wellness App
//
//  Records a workout live with GPS: a route map, distance, elapsed time, pace,
//  and speed, then logs an editable session. Add extra details (heart rate,
//  notes) afterwards by tapping the session in your activity list.
//

import SwiftUI
import MapKit

struct ActivityLiveView: View {
    @Environment(ActivityStore.self) private var activity
    @Environment(UserStore.self) private var user
    @Environment(\.dismiss) private var dismiss

    @State private var tracker = WorkoutTracker()
    @State private var type: ActivityType = .run
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    private let trackableTypes: [ActivityType] = [.run, .walk, .ride, .swim]
    private var weightKg: Double { user.profile?.currentWeightKg ?? 70 }

    var body: some View {
        NavigationStack {
            Group {
                switch tracker.phase {
                case .idle:     setup
                case .finished: summary
                default:        live
                }
            }
            .navigationTitle("Live workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if tracker.phase == .idle {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
        .tint(Theme.activity)
        .onAppear { tracker.requestAuthorization() }
        .onDisappear { if tracker.phase != .finished { tracker.reset() } }
    }

    // MARK: - Setup

    private var setup: some View {
        Form {
            Section("Activity") {
                Picker("Type", selection: $type) {
                    ForEach(trackableTypes) { t in
                        Label(t.label, systemImage: t.systemImage).tag(t)
                    }
                }
                .pickerStyle(.segmented)
            }

            if !tracker.locationAllowed {
                Section {
                    Label("Location access is needed to map your route and measure distance. You can still time the session without it.",
                          systemImage: "location.slash")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Allow location") { tracker.requestAuthorization() }
                }
            }

            Section {
                Button {
                    tracker.start()
                } label: {
                    Label("Start workout", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
            } footer: {
                Text("Live heart rate needs an Apple Watch or a paired monitor; you can add an average heart rate afterwards by editing the session.")
            }
        }
    }

    // MARK: - Live

    private var live: some View {
        VStack(spacing: 0) {
            Map(position: $cameraPosition) {
                UserAnnotation()
                if tracker.coordinates.count >= 2 {
                    MapPolyline(coordinates: tracker.coordinates)
                        .stroke(Theme.activity, lineWidth: 5)
                }
            }
            .mapControls { MapUserLocationButton() }
            .frame(maxHeight: .infinity)

            statsPanel
        }
    }

    private var statsPanel: some View {
        VStack(spacing: 16) {
            HStack {
                stat(tracker.distanceKm > 0 ? String(format: "%.2f", tracker.distanceKm) : "0.00", "km")
                Divider().frame(height: 40)
                stat(timeString(tracker.elapsed), "time")
                Divider().frame(height: 40)
                stat(tracker.paceMinPerKm != nil ? tracker.paceText.replacingOccurrences(of: " /km", with: "") : "--", "pace /km")
            }

            HStack(spacing: 16) {
                if tracker.phase == .paused {
                    Button { tracker.resume() } label: {
                        Label("Resume", systemImage: "play.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button { tracker.pause() } label: {
                        Label("Pause", systemImage: "pause.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button(role: .destructive) {
                    tracker.stop()
                } label: {
                    Label("Finish", systemImage: "stop.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
        .background(.bar)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.bold).monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Summary

    private var summary: some View {
        let entry = makeEntry()
        return Form {
            Section("Great work") {
                LabeledContent("Activity", value: type.label)
                LabeledContent("Time", value: timeString(tracker.elapsed))
                if tracker.distanceKm > 0 {
                    LabeledContent("Distance", value: String(format: "%.2f km", tracker.distanceKm))
                    LabeledContent("Pace", value: tracker.paceText)
                    LabeledContent("Avg speed", value: String(format: "%.1f km/h", tracker.averageSpeedKmh))
                }
                LabeledContent("Est. calories", value: "\(entry.caloriesBurned) kcal")
            }
            Section {
                Button {
                    activity.add(entry)
                    Haptics.success()
                    dismiss()
                } label: {
                    Label("Save workout", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
                Button(role: .destructive) {
                    tracker.reset()
                    dismiss()
                } label: {
                    Text("Discard").frame(maxWidth: .infinity)
                }
            } footer: {
                Text("Saved workouts appear in your activity list. Tap one to add heart rate, notes, or other details.")
            }
        }
    }

    // MARK: - Helpers

    private func makeEntry() -> ActivityEntry {
        let minutes = max(1, tracker.durationMinutes)
        let intensity = tracker.intensity(for: type)
        let base = HealthMath.estimatedBurn(type: type, minutes: minutes, weightKg: weightKg)
        let calories = Int((Double(base) * intensity.multiplier).rounded())
        return ActivityEntry(
            type: type,
            name: "\(type.label) (live)",
            durationMin: minutes,
            caloriesBurned: calories,
            distanceKm: tracker.distanceKm > 0.01 ? tracker.distanceKm : nil,
            loggedAt: Date()
        )
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}

#Preview {
    ActivityLiveView()
        .withSampleStores()
}
