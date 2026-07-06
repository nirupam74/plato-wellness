//
//  ActivityView.swift
//  Wellness App
//
//  Tab 2 root. Today's movement summary and calories burned, links into the
//  steps and trends detail screens, and the recent workout list with swipe to
//  delete. The quick-add menu opens the workout or sport logging sheets.
//

import SwiftUI

struct ActivityView: View {
    @Environment(ActivityStore.self) private var activity
    @Environment(UserStore.self) private var user
    @Environment(AppState.self) private var appState
    @State private var viewModel = ActivityViewModel()
    @State private var editingEntry: ActivityEntry?

    private var todayEntries: [ActivityEntry] {
        viewModel.todayEntries(activity.entries)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ActivitySummaryCard()
                    ActivityCaloriesCard()
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    NavigationLink {
                        ActivityStepsDetailView()
                    } label: {
                        Label("Steps & active energy", systemImage: "chart.bar.xaxis")
                    }
                    NavigationLink {
                        ActivityTrendsView()
                    } label: {
                        Label("History & trends", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }

                workoutsSection
            }
            .listStyle(.insetGrouped)
            .refreshable { await appState.syncHealthKit() }
            .navigationTitle("Activity")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            viewModel.presentWorkout()
                        } label: {
                            Label("Log workout", systemImage: "figure.run")
                        }
                        Button {
                            viewModel.presentStrength()
                        } label: {
                            Label("Log strength", systemImage: "dumbbell")
                        }
                        Button {
                            viewModel.presentSport()
                        } label: {
                            Label("Log sport", systemImage: "sportscourt")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Quick add")
                }
            }
            .sheet(item: $viewModel.activeSheet) { sheet in
                switch sheet {
                case .workout:  ActivityLogWorkoutView()
                case .sport:    ActivitySportsView()
                case .strength: ActivityStrengthView()
                }
            }
            .sheet(item: $editingEntry) { entry in
                editor(for: entry)
            }
        }
        .tint(Theme.activity)
    }

    /// Opens the right logger in edit mode for an existing entry.
    @ViewBuilder
    private func editor(for entry: ActivityEntry) -> some View {
        switch entry.type {
        case .sport:    ActivitySportsView(editing: entry)
        case .strength: ActivityStrengthView(editing: entry)
        default:        ActivityLogWorkoutView(editing: entry)
        }
    }

    @ViewBuilder
    private var workoutsSection: some View {
        Section {
            if todayEntries.isEmpty {
                ContentUnavailableView {
                    Label("Nothing logged today", systemImage: "figure.run.circle")
                } description: {
                    Text("Tap the plus button above to log a workout, strength session, or sport.")
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(todayEntries) { entry in
                    entryRow(entry)
                }
                .onDelete(perform: delete)
            }
        } header: {
            Text("Today")
        }

        Section {
            NavigationLink {
                ActivityHistoryView(editingEntry: $editingEntry)
            } label: {
                Label("Past workouts", systemImage: "calendar")
            }
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: ActivityEntry) -> some View {
        if entry.fromHealthKit {
            ActivityWorkoutRow(entry: entry)
        } else {
            Button {
                editingEntry = entry
            } label: {
                ActivityWorkoutRow(entry: entry)
            }
            .buttonStyle(.plain)
        }
    }

    private func delete(at offsets: IndexSet) {
        let entries = todayEntries
        for index in offsets {
            activity.remove(entries[index])
        }
    }
}

// MARK: - History

/// All past activities grouped by day. Rows open the matching editor; swipe to
/// delete. Today's activities also appear here so nothing is lost when the main
/// list rolls over at midnight.
struct ActivityHistoryView: View {
    @Environment(ActivityStore.self) private var activity
    @State private var viewModel = ActivityViewModel()
    @Binding var editingEntry: ActivityEntry?

    var body: some View {
        List {
            let groups = viewModel.entriesByDay(activity.entries)
            if groups.isEmpty {
                ContentUnavailableView {
                    Label("No past workouts", systemImage: "calendar")
                } description: {
                    Text("Your logged activities will appear here, grouped by day.")
                }
            } else {
                ForEach(groups, id: \.day) { group in
                    Section(group.day.formatted(date: .abbreviated, time: .omitted)) {
                        ForEach(group.entries) { entry in
                            row(entry)
                        }
                        .onDelete { offsets in
                            offsets.map { group.entries[$0] }.forEach(activity.remove)
                        }
                    }
                }
            }
        }
        .navigationTitle("Past workouts")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func row(_ entry: ActivityEntry) -> some View {
        if entry.fromHealthKit {
            ActivityWorkoutRow(entry: entry)
        } else {
            Button {
                editingEntry = entry
            } label: {
                ActivityWorkoutRow(entry: entry)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    ActivityView()
        .withSampleStores()
}
