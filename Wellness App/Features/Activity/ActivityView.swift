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
    @State private var viewModel = ActivityViewModel()

    private var recentEntries: [ActivityEntry] {
        viewModel.recentEntries(activity.entries)
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
                case .workout: ActivityLogWorkoutView()
                case .sport:   ActivitySportsView()
                }
            }
        }
        .tint(Theme.activity)
    }

    @ViewBuilder
    private var workoutsSection: some View {
        Section("Recent workouts") {
            if recentEntries.isEmpty {
                ContentUnavailableView {
                    Label("No workouts yet", systemImage: "figure.run.circle")
                } description: {
                    Text("Log a workout or a sport to see it here.")
                } actions: {
                    Button("Log workout") { viewModel.presentWorkout() }
                        .buttonStyle(.borderedProminent)
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(recentEntries) { entry in
                    ActivityWorkoutRow(entry: entry)
                }
                .onDelete(perform: delete)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let entries = recentEntries
        for index in offsets {
            activity.remove(entries[index])
        }
    }
}

#Preview {
    ActivityView()
        .withSampleStores()
}
