//
//  RestoreSkincareView.swift
//  Wellness App
//
//  Skincare ritual: a daily morning and evening checklist plus the current
//  streak. Editing the routines lives in RestoreSkincareEditorView.
//

import SwiftUI

struct RestoreSkincareView: View {
    @Environment(RestoreStore.self) private var restore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                streakCard
                ForEach(RoutineTime.allCases) { time in
                    RestoreSkincareChecklistCard(time: time)
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Skincare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    RestoreSkincareEditorView()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Edit routines")
            }
        }
        .tint(Theme.restore)
    }

    @ViewBuilder private var streakCard: some View {
        Card {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.restore.opacity(0.15)).frame(width: 52, height: 52)
                    Image(systemName: "flame.fill").font(.title2).foregroundStyle(Theme.restore)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(restore.skincareStreak == 1 ? "1 day streak" : "\(restore.skincareStreak) day streak")
                        .font(.title3.weight(.bold))
                    Text("Complete every step morning and evening to keep it going.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A checklist card for one routine time, checking off steps for today.
struct RestoreSkincareChecklistCard: View {
    @Environment(RestoreStore.self) private var restore
    var time: RoutineTime

    private var steps: [SkincareStep] { restore.steps(for: time) }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderRow(time.label) {
                    Image(systemName: time.systemImage).foregroundStyle(Theme.restore)
                }
                if steps.isEmpty {
                    ContentUnavailableView {
                        Label("No \(time.label.lowercased()) steps yet", systemImage: "hands.and.sparkles.fill")
                    } description: {
                        Text("Add steps from the edit button to start this routine.")
                    }
                } else {
                    VStack(spacing: 6) {
                        ForEach(steps) { step in
                            let done = restore.isStepComplete(step.id, time: time)
                            Button {
                                restore.toggleStep(step.id, time: time)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(done ? Theme.restore : Color.secondary)
                                    Text(step.name)
                                        .strikethrough(done, color: .secondary)
                                        .foregroundStyle(done ? .secondary : .primary)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(step.name), \(time.label)")
                            .accessibilityValue(done ? "Done" : "Not done")
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RestoreSkincareView()
    }
    .withSampleStores()
}
