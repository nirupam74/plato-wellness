//
//  ActivitySessionFeedback.swift
//  Wellness App
//
//  Shared post-session feedback used by every activity logger: how hard it felt,
//  what went well, and any injuries, stiff movements, or breathing trouble. Also
//  the banner that surfaces a prior advisory once, the next time you open the
//  same activity.
//

import SwiftUI

/// Editable draft of a session's feedback, held by each logger's view model.
@Observable
final class SessionFeedbackDraft {
    var difficulty: SessionDifficulty = .moderate
    var wentWell: String = ""
    var issues: [SessionIssue] = []

    func addIssue() { issues.append(SessionIssue()) }

    /// The saved model, or nil when nothing meaningful was entered.
    func model() -> SessionFeedback? {
        let cleaned = issues.filter { !$0.isEmpty }
        let well = wentWell.trimmingCharacters(in: .whitespacesAndNewlines)
        if well.isEmpty && cleaned.isEmpty && difficulty == .moderate { return nil }
        return SessionFeedback(difficulty: difficulty, wentWell: well, issues: cleaned)
    }

    func load(_ feedback: SessionFeedback?) {
        guard let feedback else { return }
        difficulty = feedback.difficulty
        wentWell = feedback.wentWell
        issues = feedback.issues
    }
}

/// The "how did it go" and "anything not feel right" sections.
struct SessionFeedbackSection: View {
    @Bindable var draft: SessionFeedbackDraft

    var body: some View {
        Section {
            Picker("How it felt", selection: $draft.difficulty) {
                ForEach(SessionDifficulty.allCases) { level in
                    Text(level.label).tag(level)
                }
            }
            TextField("What went well?", text: $draft.wentWell, axis: .vertical)
                .lineLimit(1...4)
        } header: {
            Text("How did it go?")
        }

        Section {
            ForEach($draft.issues) { $issue in
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Type", selection: $issue.kind) {
                        ForEach(IssueKind.allCases) { kind in
                            Label(kind.label, systemImage: kind.systemImage).tag(kind)
                        }
                    }
                    TextField("Area (e.g. left knee)", text: $issue.area)
                    TextField("What happened?", text: $issue.note, axis: .vertical)
                        .lineLimit(1...3)
                }
                .padding(.vertical, 2)
            }
            .onDelete { draft.issues.remove(atOffsets: $0) }

            Button {
                draft.addIssue()
            } label: {
                Label("Flag an injury or issue", systemImage: "exclamationmark.triangle")
            }
        } header: {
            Text("Anything not feel right?")
        } footer: {
            Text("Flag an injury, stiff movement, or breathing trouble and we'll suggest how long to ease off, then remind you the next time you do this activity. This is general guidance, not medical advice.")
        }
    }
}

/// A one-time reminder shown at the top of a logger when there is prior advice
/// for this activity.
struct ActivityAdvisoryBanner: View {
    let advisory: ActivityAdvisory

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: advisory.kind.systemImage)
                .font(.title3)
                .foregroundStyle(Theme.activity)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("A note from last time")
                    .font(.subheadline.weight(.semibold))
                Text(advisory.reminderMessage())
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Note from last time. \(advisory.reminderMessage())")
    }
}
