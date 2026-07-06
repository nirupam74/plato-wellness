//
//  OnboardingComponents.swift
//  Wellness App
//
//  Reusable building blocks specific to the onboarding flow. All names are
//  prefixed `Onboarding` so they never collide with the shared Components.
//  Everything below scales with Dynamic Type and carries accessibility labels.
//

import SwiftUI

/// Thin progress bar plus a "Step X of N" caption shown above every step.
struct OnboardingProgressBar: View {
    let current: Int      // zero based index
    let total: Int
    let title: String

    private var fraction: Double {
        total > 0 ? Double(current + 1) / Double(total) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Step \(current + 1) of \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.accent.opacity(0.15))
                    Capsule()
                        .fill(Theme.accent)
                        .frame(width: max(0, geo.size.width * fraction))
                        .animation(.snappy, value: fraction)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("Step \(current + 1) of \(total), \(title)")
    }
}

/// Standard header and scrollable body for a single onboarding step.
struct OnboardingStepScaffold<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                    }
                    Text(title)
                        .font(.largeTitle.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                content
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

/// A selectable option card (radio style) used for sex, activity, goal, diet.
struct OnboardingChoiceRow: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundStyle(isSelected ? Theme.accent : .secondary)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.accent : Color(uiColor: .tertiaryLabel))
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Theme.accent : .clear, lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// A labeled numeric field bound to a Double, with an optional unit suffix.
struct OnboardingDecimalField: View {
    let title: String
    var unit: String? = nil
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer(minLength: 12)
            TextField(title, value: $value, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 110)
                .accessibilityLabel(title)
            if let unit {
                Text(unit)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// A labeled optional numeric field backed by text, for skippable inputs.
struct OnboardingOptionalField: View {
    let title: String
    var unit: String? = nil
    @Binding var text: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer(minLength: 12)
            TextField("Optional", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 110)
                .accessibilityLabel(title)
            if let unit {
                Text(unit)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// A labeled integer field with a stepper, for whole number targets.
struct OnboardingIntField: View {
    let title: String
    var unit: String? = nil
    @Binding var value: Int

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer(minLength: 12)
            TextField(title, value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 90)
                .accessibilityLabel(title)
            if let unit {
                Text(unit)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// Add and remove a free text list (allergies, foods to avoid).
struct OnboardingTokenEditor: View {
    let title: String
    let placeholder: String
    @Binding var items: [String]
    @State private var draft = ""

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderRow(title)
            HStack {
                TextField(placeholder, text: $draft)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit(add)
                Button(action: add) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .disabled(trimmedDraft.isEmpty)
                .accessibilityLabel("Add to \(title)")
            }
            if items.isEmpty {
                Text("None added")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Text(item)
                        Spacer()
                        Button {
                            remove(item)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Remove \(item)")
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func add() {
        let value = trimmedDraft
        guard !value.isEmpty,
              !items.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) else {
            draft = ""
            return
        }
        items.append(value)
        draft = ""
    }

    private func remove(_ item: String) {
        items.removeAll { $0 == item }
    }
}

/// A soft callout box, used for the unsafe deficit warning and crisis notes.
struct OnboardingCallout: View {
    enum Kind { case warning, info }
    let kind: Kind
    let title: String
    let message: String

    private var tint: Color {
        switch kind {
        case .warning: Theme.nutrition
        case .info:    Theme.activity
        }
    }

    private var symbol: String {
        switch kind {
        case .warning: "exclamationmark.triangle.fill"
        case .info:    "info.circle.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .accessibilityElement(children: .combine)
    }
}
