//
//  RestoreWaterView.swift
//  Wellness App
//
//  Water ritual: progress toward the daily target with one-tap glass and bottle
//  quick-adds plus a custom amount.
//

import SwiftUI

struct RestoreWaterView: View {
    @Environment(RestoreStore.self) private var restore
    @Environment(UserStore.self) private var user
    @State private var showingCustom = false

    private var target: Int { user.profile?.targets.waterMl ?? 2000 }
    private var total: Int { restore.todayWaterMl }
    private var fraction: Double { target > 0 ? min(Double(total) / Double(target), 1) : 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                progressCard
                quickAddCard
                todayLogCard
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Water")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCustom = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Log a custom amount")
            }
        }
        .sheet(isPresented: $showingCustom) {
            RestoreWaterQuickAddSheet()
        }
        .tint(Theme.restore)
    }

    @ViewBuilder private var progressCard: some View {
        Card {
            VStack(spacing: 16) {
                ZStack {
                    MetricRing(progress: fraction, tint: Theme.restore, lineWidth: 14)
                        .frame(width: 150, height: 150)
                    VStack(spacing: 2) {
                        Image(systemName: "drop.fill").foregroundStyle(Theme.restore)
                        Text("\(total)")
                            .font(.largeTitle.weight(.bold))
                            .contentTransition(.numericText())
                        Text("of \(target) ml").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Water today")
                .accessibilityValue("\(total) of \(target) milliliters")

                LabeledProgressBar(value: Double(total), target: Double(target), tint: Theme.restore)

                Text(total >= target ? "Nice, you have hit your water goal for today." : "\(max(0, target - total)) ml to go.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var todayLogCard: some View {
        let todays = restore.waterEntries
            .filter { $0.loggedAt.isSameDay(as: Date()) }
            .sorted { $0.loggedAt > $1.loggedAt }
        if !todays.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeaderRow("Today's log")
                    ForEach(todays) { entry in
                        HStack(spacing: 12) {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(Theme.restore)
                                .accessibilityHidden(true)
                            Text("\(entry.amountMl) ml")
                                .font(.subheadline)
                            Text(entry.loggedAt.formatted(.dateTime.hour().minute()))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                            Button(role: .destructive) {
                                restore.removeWater(entry)
                                Haptics.tap()
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Delete \(entry.amountMl) millilitre entry at \(entry.loggedAt.formatted(.dateTime.hour().minute()))")
                        }
                        .accessibilityElement(children: .combine)
                        if entry.id != todays.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private var quickAddCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderRow("Quick add")
                HStack(spacing: 12) {
                    RestoreWaterButton(title: "Glass", detail: "250 ml", systemImage: "cup.and.saucer.fill") {
                        restore.addWater(ml: 250)
                        Haptics.success()
                    }
                    RestoreWaterButton(title: "Bottle", detail: "500 ml", systemImage: "waterbottle.fill") {
                        restore.addWater(ml: 500)
                        Haptics.success()
                    }
                    RestoreWaterButton(title: "Custom", detail: "Choose", systemImage: "slider.horizontal.3") {
                        showingCustom = true
                    }
                }
            }
        }
    }
}

/// A single tappable water quick-add tile.
struct RestoreWaterButton: View {
    var title: String
    var detail: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(Theme.restore)
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.restore.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(detail)")
    }
}

#Preview {
    NavigationStack {
        RestoreWaterView()
    }
    .withSampleStores()
}
