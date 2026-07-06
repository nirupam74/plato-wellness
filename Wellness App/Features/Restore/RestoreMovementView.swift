//
//  RestoreMovementView.swift
//  Wellness App
//
//  Movement and breathwork library: yoga flows, guided breathing, and
//  meditation and body-scan timers. Shows total mindful minutes at the top.
//

import SwiftUI

/// A timed session offered in the library (yoga, meditation, or body scan).
struct RestoreTimedSession: Identifiable {
    var id: String { name }
    var type: SessionType
    var name: String
    var detail: String
    var durationMin: Int
}

enum RestoreMovementLibrary {
    static let yoga: [RestoreTimedSession] = [
        RestoreTimedSession(type: .yoga, name: "Wake up flow", detail: "Gentle sun salutations to open the day.", durationMin: 8),
        RestoreTimedSession(type: .yoga, name: "Wind down", detail: "Slow stretches to release the day's tension.", durationMin: 12),
        RestoreTimedSession(type: .yoga, name: "Desk break", detail: "Neck, shoulder, and wrist relief between tasks.", durationMin: 5)
    ]

    static let mindful: [RestoreTimedSession] = [
        RestoreTimedSession(type: .meditation, name: "Focus", detail: "A short seated meditation to settle your attention.", durationMin: 10),
        RestoreTimedSession(type: .meditation, name: "Loving kindness", detail: "Warm, friendly attention toward yourself and others.", durationMin: 8),
        RestoreTimedSession(type: .bodyScan, name: "Body scan", detail: "Move attention head to toe, softening as you go.", durationMin: 12)
    ]
}

struct RestoreMovementView: View {
    @Environment(RestoreStore.self) private var restore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                mindfulMinutesCard
                breathingCard
                timedSection(title: "Yoga flows", systemImage: "figure.yoga", sessions: RestoreMovementLibrary.yoga)
                timedSection(title: "Meditation and body scan", systemImage: "brain.head.profile", sessions: RestoreMovementLibrary.mindful)
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Movement")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.restore)
    }

    @ViewBuilder private var mindfulMinutesCard: some View {
        Card {
            HStack(spacing: 16) {
                StatTile(
                    title: "Mindful minutes",
                    value: "\(restore.totalMindfulMinutes)",
                    systemImage: "brain.head.profile",
                    tint: Theme.restore
                )
                StatTile(
                    title: "Sessions",
                    value: "\(restore.sessions.count)",
                    systemImage: "checkmark.seal.fill",
                    tint: Theme.restore
                )
            }
        }
    }

    @ViewBuilder private var breathingCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderRow(title: "Breathing") {
                    Image(systemName: "wind").foregroundStyle(Theme.restore)
                }
                ForEach(RestoreBreathingTechnique.all) { technique in
                    NavigationLink {
                        RestoreBreathingView(technique: technique, durationMin: 3)
                    } label: {
                        RestoreLibraryRow(
                            title: technique.name,
                            detail: technique.detail,
                            trailing: "3 min",
                            systemImage: "wind"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func timedSection(title: String, systemImage: String, sessions: [RestoreTimedSession]) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderRow(title: title) {
                    Image(systemName: systemImage).foregroundStyle(Theme.restore)
                }
                ForEach(sessions) { session in
                    NavigationLink {
                        RestoreSessionTimerView(
                            type: session.type,
                            name: session.name,
                            detail: session.detail,
                            durationMin: session.durationMin
                        )
                    } label: {
                        RestoreLibraryRow(
                            title: session.name,
                            detail: session.detail,
                            trailing: "\(session.durationMin) min",
                            systemImage: session.type.systemImage
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// A single library row: icon, title, detail, and a trailing duration chip.
struct RestoreLibraryRow: View {
    var title: String
    var detail: String
    var trailing: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Theme.restore)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(detail).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Text(trailing)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.restore)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.restore.opacity(0.12), in: Capsule())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(trailing)")
        .accessibilityHint(detail)
    }
}

#Preview {
    NavigationStack {
        RestoreMovementView()
    }
    .withSampleStores()
}
