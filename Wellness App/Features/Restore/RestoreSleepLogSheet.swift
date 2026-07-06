//
//  RestoreSleepLogSheet.swift
//  Wellness App
//
//  Manual sleep entry: pick bedtime and wake time, rate quality 1 to 5, and
//  save a SleepEntry through restore.addSleep.
//

import SwiftUI

struct RestoreSleepLogSheet: View {
    @Environment(RestoreStore.self) private var restore
    @Environment(\.dismiss) private var dismiss

    @State private var bedtime: Date = RestoreSleepLogSheet.defaultBedtime
    @State private var wakeTime: Date = RestoreSleepLogSheet.defaultWakeTime
    @State private var quality: Int = 3

    private var durationMin: Int {
        max(0, Int(wakeTime.timeIntervalSince(bedtime) / 60))
    }

    private var durationText: String {
        let h = durationMin / 60
        let m = durationMin % 60
        return "\(h) h \(m) min"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("When did you sleep?") {
                    DatePicker("Bedtime", selection: $bedtime)
                    DatePicker("Wake time", selection: $wakeTime)
                    LabeledContent("Duration", value: durationText)
                }

                Section("How rested do you feel?") {
                    RestoreRatingPicker(
                        title: "Sleep quality",
                        value: $quality,
                        lowLabel: "Poor",
                        highLabel: "Great"
                    )
                }
            }
            .navigationTitle("Log sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        restore.addSleep(SleepEntry(
                            bedtime: bedtime,
                            wakeTime: wakeTime,
                            quality: quality,
                            fromHealthKit: false
                        ))
                        dismiss()
                    }
                    .disabled(durationMin <= 0)
                }
            }
        }
        .tint(Theme.restore)
    }

    private static var defaultBedtime: Date {
        let base = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date().adding(days: -1)) ?? Date()
        return base
    }

    private static var defaultWakeTime: Date {
        Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

#Preview {
    RestoreSleepLogSheet()
        .withSampleStores()
}
