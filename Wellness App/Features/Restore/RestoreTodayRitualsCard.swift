//
//  RestoreTodayRitualsCard.swift
//  Wellness App
//
//  The header of the Restore tab: today's self-care rituals as a checklist with
//  overall progress. Reads from restore.todayRituals.
//

import SwiftUI

struct RestoreTodayRitualsCard: View {
    @Environment(RestoreStore.self) private var restore
    var viewModel: RestoreViewModel

    private var rituals: [(name: String, done: Bool)] { restore.todayRituals }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderRow(title: "Today's rituals") {
                    Text("\(viewModel.doneCount(rituals)) of \(rituals.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.restore)
                }

                LabeledProgressBar(
                    value: Double(viewModel.doneCount(rituals)),
                    target: Double(rituals.count),
                    tint: Theme.restore
                )
                .accessibilityLabel("Rituals complete")
                .accessibilityValue("\(viewModel.doneCount(rituals)) of \(rituals.count)")

                VStack(spacing: 10) {
                    ForEach(rituals, id: \.name) { ritual in
                        HStack(spacing: 12) {
                            Image(systemName: ritual.done ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(ritual.done ? Theme.restore : Color.secondary)
                            Text(ritual.name)
                                .strikethrough(ritual.done, color: .secondary)
                                .foregroundStyle(ritual.done ? .secondary : .primary)
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(ritual.name)
                        .accessibilityValue(ritual.done ? "Done" : "Not done yet")
                    }
                }
            }
        }
    }
}

#Preview {
    RestoreTodayRitualsCard(viewModel: RestoreViewModel())
        .padding()
        .withSampleStores()
}
