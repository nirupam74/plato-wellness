//
//  CompanionDisclaimerView.swift
//  Wellness App
//
//  First-run disclaimer and consent (spec sections 8.1 and 8.2). States plainly
//  that this is an AI companion, not a therapist or crisis service, shows the
//  crisis resources, and asks whether the companion may read a summary of recent
//  mood, sleep, and activity for personalization. The context consent maps to
//  `UserProfile.companionContextConsent` (default off). The same view serves as
//  the always-available "About this companion" sheet from the toolbar.
//

import SwiftUI

struct CompanionDisclaimerView: View {
    /// True on first run so the primary action reads "Continue" and dismissal
    /// marks the disclaimer as seen. False when reopened from the info button.
    var isFirstRun: Bool
    var resources: [CrisisResource]

    @Environment(UserStore.self) private var user
    @Environment(\.dismiss) private var dismiss

    private var contextConsent: Binding<Bool> {
        Binding(
            get: { user.profile?.companionContextConsent ?? false },
            set: { newValue in user.update { $0.companionContextConsent = newValue } }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            disclaimerRow(
                                icon: "sparkles",
                                title: "A supportive companion",
                                detail: "A calm space to reflect and check in. It listens and responds, but it does not diagnose or treat anything."
                            )
                            Divider()
                            disclaimerRow(
                                icon: "cross.case",
                                title: "Not a therapist or doctor",
                                detail: "This is not professional care and is not a substitute for a licensed clinician."
                            )
                            Divider()
                            disclaimerRow(
                                icon: "phone.badge.waveform",
                                title: "Not a crisis service",
                                detail: "In an emergency it cannot help. Please use the resources below to reach a real person."
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeaderRow("If you need help now")
                        ForEach(resources) { resource in
                            Card {
                                CompanionResourceRow(resource: resource)
                            }
                        }
                    }

                    Card {
                        Toggle(isOn: contextConsent) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Personalize with my recent wellness")
                                    .font(.subheadline.weight(.semibold))
                                Text("Let the companion read a short summary of your recent mood, sleep, and activity so its replies fit how you are doing. You can turn this off any time. It stays off unless you allow it.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .tint(Theme.restore)
                        .accessibilityLabel("Allow the companion to read a summary of recent mood, sleep, and activity")
                    }
                }
                .padding()
            }
            .navigationTitle(isFirstRun ? "Welcome" : "About this companion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isFirstRun ? "Continue" : "Done") { dismiss() }
                        .accessibilityLabel(isFirstRun ? "Continue to the companion" : "Close")
                }
            }
        }
        .tint(Theme.restore)
        .interactiveDismissDisabled(isFirstRun)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "bubble.left.and.heart.fill")
                .font(.largeTitle)
                .foregroundStyle(Theme.restore)
            Text("Your AI companion")
                .font(.title2.weight(.bold))
            Text("A gentle place to talk things through. Here is what it is, and what it is not, before you begin.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func disclaimerRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.restore)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("First run") {
    CompanionDisclaimerView(isFirstRun: true, resources: SampleData.crisisResources())
        .withSampleStores()
}

#Preview("Reopened") {
    CompanionDisclaimerView(isFirstRun: false, resources: SampleData.crisisResources())
        .withSampleStores()
}
