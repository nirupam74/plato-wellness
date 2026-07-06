//
//  ProfileExportView.swift
//  Wellness App
//
//  Pick a format, see what is included, and share a real generated file via the
//  system share sheet.
//

import SwiftUI

struct ProfileExportView: View {
    @Environment(UserStore.self) private var user
    @Environment(NutritionStore.self) private var nutrition
    @Environment(ActivityStore.self) private var activity
    @Environment(RestoreStore.self) private var restore
    @Environment(CompanionStore.self) private var companion

    @State private var format: ProfileExportFormat = .json
    @State private var exportURL: URL?
    @State private var errorMessage: String?

    private var exporter: ProfileExporter {
        ProfileExporter(user: user, nutrition: nutrition, activity: activity, restore: restore, companion: companion)
    }

    var body: some View {
        Form {
            Section("Format") {
                Picker("Format", selection: $format) {
                    ForEach(ProfileExportFormat.allCases) { f in
                        Text(f.label).tag(f)
                    }
                }
                .pickerStyle(.segmented)

                Text(format.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Included") {
                countRow("Food entries", nutrition.entries.count, "fork.knife")
                countRow("Workouts", activity.entries.count, "figure.run")
                countRow("Daily activity", activity.dailySummaries.count, "flame")
                countRow("Water logs", restore.waterEntries.count, "drop.fill")
                countRow("Sleep entries", restore.sleepEntries.count, "bed.double.fill")
                countRow("Mood check-ins", restore.moodEntries.count, "face.smiling")
                countRow("Mindful sessions", restore.sessions.count, "brain.head.profile")
                countRow("Body measurements", user.measurements.count, "ruler")
                countRow("Companion messages", companion.messages.count, "bubble.left.and.bubble.right")
            }

            Section {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share \(format.label) file", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                } else if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.footnote)
                } else {
                    ProgressView().frame(maxWidth: .infinity)
                }
            } footer: {
                Text("Your data never leaves your device until you choose where to send it.")
            }
        }
        .navigationTitle("Export data")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: format) { regenerate() }
    }

    private func countRow(_ title: String, _ count: Int, _ symbol: String) -> some View {
        LabeledContent {
            Text("\(count)").foregroundStyle(.secondary)
        } label: {
            Label(title, systemImage: symbol)
        }
    }

    private func regenerate() {
        exportURL = nil
        errorMessage = nil
        do {
            exportURL = try exporter.exportFile(format: format)
        } catch {
            errorMessage = "Could not prepare the export. Please try again."
        }
    }
}

#Preview {
    NavigationStack {
        ProfileExportView()
    }
    .withSampleStores()
}
