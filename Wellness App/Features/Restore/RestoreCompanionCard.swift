//
//  RestoreCompanionCard.swift
//  Wellness App
//
//  The persistent, inviting entry point to the AI companion. It is only the
//  label; RestoreView wraps it in a NavigationLink to CompanionView(), which is
//  owned by a separate agent.
//

import SwiftUI

struct RestoreCompanionCard: View {
    var body: some View {
        Card {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.restore.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(Theme.restore)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Talk with your companion")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("A gentle space to reflect, unwind, and plan your next small step.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Talk with your companion")
        .accessibilityHint("Opens the AI companion")
    }
}

#Preview {
    RestoreCompanionCard()
        .padding()
        .withSampleStores()
}
