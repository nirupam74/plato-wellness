//
//  RestoreMoodCheckInSheet.swift
//  Wellness App
//
//  A quick daily check in: mood, stress, and energy on a 1 to 5 scale plus an
//  optional note. Saves a MoodEntry through restore.addMood.
//

import SwiftUI

struct RestoreMoodCheckInSheet: View {
    @Environment(RestoreStore.self) private var restore
    @Environment(\.dismiss) private var dismiss

    @State private var mood: Int = 3
    @State private var stress: Int = 3
    @State private var energy: Int = 3
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    RestoreRatingPicker(title: "Mood", value: $mood, lowLabel: "Low", highLabel: "Great")
                    RestoreRatingPicker(title: "Stress", value: $stress, lowLabel: "Calm", highLabel: "Tense")
                    RestoreRatingPicker(title: "Energy", value: $energy, lowLabel: "Drained", highLabel: "Lively")
                }
                Section("Anything on your mind?") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Check in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        restore.addMood(MoodEntry(
                            mood: mood,
                            stress: stress,
                            energy: energy,
                            note: trimmed.isEmpty ? nil : trimmed
                        ))
                        dismiss()
                    }
                }
            }
        }
        .tint(Theme.restore)
    }
}

#Preview {
    RestoreMoodCheckInSheet()
        .withSampleStores()
}
