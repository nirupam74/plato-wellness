//
//  Components.swift
//  Wellness App
//
//  Shared, reusable UI building blocks so the four pillars read as one system
//  (spec section 10). Use these instead of rolling per-feature variants.
//

import SwiftUI

/// Rounded, soft card container. One reusable card for the whole app.
struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
    }
}

/// Circular progress ring, used for calories and macros vs target.
struct MetricRing: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var progress: Double            // 0...1 and beyond (clamped visually)
    var tint: Color
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .snappy, value: progress)
        }
        // Purely decorative: every caller pairs the ring with labeled text, so
        // hide it to avoid a meaningless VoiceOver stop.
        .accessibilityHidden(true)
    }
}

/// Compact labeled value tile for stat rows.
struct StatTile: View {
    var title: String
    var value: String
    var systemImage: String? = nil
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage).foregroundStyle(tint)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3.weight(.semibold))
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

/// Linear progress toward a target, with a tint per pillar.
struct LabeledProgressBar: View {
    var value: Double
    var target: Double
    var tint: Color
    var height: CGFloat = 8

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return max(0, min(value / target, 1))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(tint.opacity(0.15))
                Capsule()
                    .fill(tint)
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: height)
    }
}

/// Section header with an optional trailing accessory.
struct SectionHeaderRow<Accessory: View>: View {
    var title: String
    @ViewBuilder var accessory: Accessory

    init(title: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.accessory = accessory()
    }

    /// Positional title with a trailing accessory closure.
    init(_ title: String, @ViewBuilder accessory: () -> Accessory) {
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            accessory
        }
    }
}

extension SectionHeaderRow where Accessory == EmptyView {
    init(_ title: String) {
        self.init(title: title) { EmptyView() }
    }
}
