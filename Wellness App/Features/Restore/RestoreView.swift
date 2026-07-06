//
//  RestoreView.swift
//  Wellness App
//
//  Tab 3. The home of the self-care rituals: today's checklist, the companion
//  entry point, an optional mood/sleep insight, and a card link into each
//  ritual (sleep, mood, water, skincare, movement and breathwork).
//

import SwiftUI

struct RestoreView: View {
    @Environment(RestoreStore.self) private var restore
    @State private var viewModel = RestoreViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    RestoreTodayRitualsCard(viewModel: viewModel)

                    // Companion is owned by a separate agent; we only link to it.
                    NavigationLink {
                        CompanionView()
                    } label: {
                        RestoreCompanionCard()
                    }
                    .buttonStyle(.plain)

                    if let insight = restore.moodSleepInsight() {
                        RestoreInsightCard(text: insight)
                    }

                    RestoreRitualLinks()
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Restore")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        ForEach(RestoreQuickAdd.allCases) { item in
                            Button {
                                viewModel.present(item)
                            } label: {
                                Label(item.label, systemImage: item.systemImage)
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Quick add")
                }
            }
            .sheet(item: Binding(
                get: { viewModel.activeQuickAdd },
                set: { viewModel.activeQuickAdd = $0 }
            )) { sheet in
                switch sheet {
                case .water: RestoreWaterQuickAddSheet()
                case .mood:  RestoreMoodCheckInSheet()
                case .sleep: RestoreSleepLogSheet()
                }
            }
        }
        .tint(Theme.restore)
    }
}

/// The stacked card links into each ritual detail screen.
private struct RestoreRitualLinks: View {
    @Environment(RestoreStore.self) private var restore
    @Environment(UserStore.self) private var user
    @Environment(FocusManager.self) private var focus

    private var focusSubtitle: String {
        focus.isLocked ? focus.remainingText : "Block distracting apps"
    }

    private var sleepSubtitle: String {
        guard let latest = restore.latestSleep else { return "No sleep logged yet" }
        return String(format: "Last night %.1f h", latest.durationHours)
    }

    private var moodSubtitle: String {
        guard let mood = restore.todayMood else { return "No check in today" }
        return "Today's mood \(mood.mood) of 5"
    }

    private var waterSubtitle: String {
        let target = user.profile?.targets.waterMl ?? 0
        if target > 0 {
            return "\(restore.todayWaterMl) of \(target) ml today"
        }
        return "\(restore.todayWaterMl) ml today"
    }

    private var skincareSubtitle: String {
        let streak = restore.skincareStreak
        return streak > 0 ? "\(streak) day streak" : "Build your routine"
    }

    private var movementSubtitle: String {
        "\(restore.totalMindfulMinutes) mindful minutes so far"
    }

    var body: some View {
        VStack(spacing: 12) {
            NavigationLink {
                RestoreSleepView()
            } label: {
                RestoreRitualRow(title: "Sleep", subtitle: sleepSubtitle, systemImage: "bed.double.fill")
            }
            NavigationLink {
                RestoreMoodView()
            } label: {
                RestoreRitualRow(title: "Mood and stress", subtitle: moodSubtitle, systemImage: "face.smiling")
            }
            NavigationLink {
                RestoreWaterView()
            } label: {
                RestoreRitualRow(title: "Water", subtitle: waterSubtitle, systemImage: "drop.fill")
            }
            NavigationLink {
                RestoreSkincareView()
            } label: {
                RestoreRitualRow(title: "Skincare", subtitle: skincareSubtitle, systemImage: "hands.and.sparkles.fill")
            }
            NavigationLink {
                RestoreMovementView()
            } label: {
                RestoreRitualRow(title: "Movement and breathwork", subtitle: movementSubtitle, systemImage: "figure.mind.and.body")
            }
            NavigationLink {
                FocusLockView()
            } label: {
                RestoreRitualRow(title: "Focus lock", subtitle: focusSubtitle, systemImage: "lock.shield.fill")
            }
        }
        .buttonStyle(.plain)
    }
}

/// One tappable ritual row in the home list.
struct RestoreRitualRow: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        Card {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.restore.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundStyle(Theme.restore)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(.primary)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(subtitle)
    }
}

/// A soft callout that surfaces the mood/sleep correlation insight.
struct RestoreInsightCard: View {
    var text: String

    var body: some View {
        Card {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Theme.restore)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 3) {
                    Text("A small pattern")
                        .font(.subheadline.weight(.semibold))
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    RestoreView()
        .withSampleStores()
}
