//
//  RestoreRatingPicker.swift
//  Wellness App
//
//  A friendly 1 to 5 rating control reused by the mood, stress, energy, and
//  sleep-quality inputs. Renders as a row of tappable pills with an accessible
//  adjustable trait.
//

import SwiftUI

struct RestoreRatingPicker: View {
    var title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...5
    var tint: Color = Theme.restore
    var lowLabel: String = "Low"
    var highLabel: String = "High"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))

            HStack(spacing: 8) {
                ForEach(Array(range), id: \.self) { n in
                    Button {
                        value = n
                    } label: {
                        Text("\(n)")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(n == value ? tint : tint.opacity(0.12))
                            )
                            .foregroundStyle(n == value ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title), \(n)")
                    .accessibilityAddTraits(n == value ? [.isSelected] : [])
                }
            }

            HStack {
                Text(lowLabel)
                Spacer()
                Text(highLabel)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    RestoreRatingPicker(title: "Mood", value: .constant(3))
        .padding()
}
