//
//  ProfileView.swift
//  Wellness App
//
//  Tab 4 root. A grouped list that leads into body data, goals, all-time stats,
//  data export, and settings, with a summary header pinned on top.
//

import SwiftUI

struct ProfileView: View {
    @Environment(NutritionStore.self) private var nutrition
    @Environment(ActivityStore.self) private var activity
    @Environment(RestoreStore.self) private var restore

    @State private var viewModel = ProfileViewModel()
    @AppStorage("appearance") private var appearance: ProfileAppearance = .system

    init() {}

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ProfileHeaderView(streak: streak, totalWorkouts: activity.totalWorkouts)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    NavigationLink {
                        ProfileBodyDataView()
                    } label: {
                        ProfileRowLabel(title: "Body data & progress",
                                        subtitle: "Weight, measurements, photos",
                                        systemImage: "figure",
                                        tint: Theme.activity)
                    }

                    NavigationLink {
                        ProfileGoalsView()
                    } label: {
                        ProfileRowLabel(title: "Goals & targets",
                                        subtitle: "Calories, macros, water, sleep",
                                        systemImage: "target",
                                        tint: Theme.nutrition)
                    }

                    NavigationLink {
                        ProfileStatsView()
                    } label: {
                        ProfileRowLabel(title: "All-time stats",
                                        subtitle: "Your lifetime totals",
                                        systemImage: "chart.bar.xaxis",
                                        tint: Theme.restore)
                    }
                }

                Section {
                    NavigationLink {
                        ProfileExportView()
                    } label: {
                        ProfileRowLabel(title: "Export your data",
                                        subtitle: "Download a CSV or JSON",
                                        systemImage: "square.and.arrow.up",
                                        tint: Theme.accent)
                    }

                    NavigationLink {
                        ProfileSettingsView()
                    } label: {
                        ProfileRowLabel(title: "Settings",
                                        subtitle: "Units, notifications, privacy",
                                        systemImage: "gearshape",
                                        tint: .secondary)
                    }
                }
            }
            .navigationTitle("Profile")
        }
        .preferredColorScheme(appearance.colorScheme)
    }

    private var streak: Int {
        viewModel.currentStreak(nutrition: nutrition, activity: activity, restore: restore)
    }
}

// MARK: - Header

private struct ProfileHeaderView: View {
    @Environment(UserStore.self) private var user
    var streak: Int
    var totalWorkouts: Int

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Theme.accent.opacity(0.18))
                        Text(initials)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .frame(width: 60, height: 60)
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(greetingName)
                            .font(.title2.weight(.bold))
                        if let weight = currentWeightText {
                            Text(weight)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 12) {
                    StatTile(title: "Day streak",
                             value: "\(streak)",
                             systemImage: "flame.fill",
                             tint: Theme.nutrition)
                    StatTile(title: "Workouts",
                             value: "\(totalWorkouts)",
                             systemImage: "figure.run",
                             tint: Theme.activity)
                }

                if let celebration = streakMilestone {
                    Label(celebration, systemImage: "party.popper.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.nutrition)
                        .accessibilityLabel(celebration)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private var greetingName: String {
        let name = user.profile?.firstName ?? ""
        let hour = Calendar.current.component(.hour, from: Date())
        let part = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        return name.isEmpty ? part : "\(part), \(name)"
    }

    private var streakMilestone: String? {
        switch streak {
        case 3: "3 day streak, great start."
        case 7: "One week streak. Keep it going."
        case 14: "Two weeks strong."
        case 30: "30 day streak. Amazing."
        case 50: "50 days. Incredible consistency."
        case 100: "100 day streak."
        case 365: "A full year. Remarkable."
        default: nil
        }
    }

    private var initials: String {
        let name = user.profile?.firstName ?? ""
        return String(name.prefix(1)).uppercased().isEmpty ? "?" : String(name.prefix(1)).uppercased()
    }

    private var currentWeightText: String? {
        guard let p = user.profile else { return nil }
        return "Current weight " + Units.displayWeight(kg: p.currentWeightKg, system: p.unitSystem)
    }
}

// MARK: - Row label

struct ProfileRowLabel: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ProfileView()
        .withSampleStores()
}
