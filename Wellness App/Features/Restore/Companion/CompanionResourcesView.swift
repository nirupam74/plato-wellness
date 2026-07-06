//
//  CompanionResourcesView.swift
//  Wellness App
//
//  Reusable crisis resource UI (spec section 8.2). One row renderer with
//  tap-to-call and tap-to-text links, a compact pinned card for when the crisis
//  check trips, and a full list presented from the toolbar so support is always
//  one tap away, not only when a message is flagged.
//

import SwiftUI

/// One crisis resource with call and text actions. Shared by the pinned card
/// and the full resource list so the two never drift apart.
struct CompanionResourceRow: View {
    var resource: CrisisResource

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resource.name)
                .font(.subheadline.weight(.semibold))
            Text(resource.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                if let call = resource.callNumber,
                   let url = URL(string: "tel:\(digits(call))") {
                    Link(destination: url) {
                        Label("Call \(call)", systemImage: "phone.fill")
                            .font(.footnote.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Call \(resource.name) at \(call)")
                }

                if let text = resource.textNumber,
                   let url = URL(string: "sms:\(digits(text))") {
                    Link(destination: url) {
                        Label("Text \(text)", systemImage: "message.fill")
                            .font(.footnote.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Text \(resource.name) at \(text)")
                }
            }
            .tint(Theme.restore)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Keep only characters a dialer understands so numbers like "988" or
    /// "1-800-273-8255" both resolve.
    private func digits(_ number: String) -> String {
        number.filter { $0.isNumber || $0 == "+" || $0 == "*" || $0 == "#" }
    }
}

/// Persistent card pinned above the chat while `isCrisisActive` holds.
struct CompanionCrisisCard: View {
    var resources: [CrisisResource]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Theme.restore)
                    Text("You deserve support right now")
                        .font(.subheadline.weight(.semibold))
                }

                Text("I am an AI companion and cannot help in a crisis. Please reach a real person who can.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(resources) { resource in
                    CompanionResourceRow(resource: resource)
                    if resource.id != resources.last?.id {
                        Divider()
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.restore.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Crisis support resources")
    }
}

/// Full, always-available list of crisis resources, presented as a sheet from
/// the companion toolbar.
struct CompanionResourcesView: View {
    var resources: [CrisisResource]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("If you are struggling or in danger, these services can help right away. They are free, confidential, and open around the clock.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(resources) { resource in
                        Card {
                            CompanionResourceRow(resource: resource)
                        }
                    }

                    Text("This companion is not a crisis service and does not contact anyone on your behalf.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
            }
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityLabel("Close support resources")
                }
            }
        }
        .tint(Theme.restore)
    }
}

#Preview("Crisis card") {
    ScrollView {
        CompanionCrisisCard(resources: SampleData.crisisResources())
            .padding()
    }
    .withSampleStores()
}

#Preview("Resources list") {
    CompanionResourcesView(resources: SampleData.crisisResources())
        .withSampleStores()
}
