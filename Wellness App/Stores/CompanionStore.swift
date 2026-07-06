//
//  CompanionStore.swift
//  Wellness App
//
//  Drives the AI companion chat. Live: messages persist in Firestore under
//  users/{uid}/companionMessages, and replies come from the companionChat Cloud
//  Function (which proxies the Anthropic Messages API). Preview: a local canned
//  reply when seeded (uid nil), so the UI works without a backend.
//
//  The crisis safety check runs client side here for the pinned resource card,
//  independent of the server side check inside the function (defense in depth).
//

import Foundation
import Observation
import FirebaseFirestore
import FirebaseFunctions

@Observable
final class CompanionStore {
    var messages: [CompanionMessage]
    var isResponding = false

    let crisisResources: [CrisisResource]

    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    private var uid: String?
    private var listener: ListenerRegistration?

    init(seeded: Bool = true) {
        self.messages = seeded ? SampleData.companionMessages() : []
        self.crisisResources = SampleData.crisisResources()
    }

    var isCrisisActive: Bool {
        messages.last(where: { $0.role == .user })?.flaggedForCrisis ?? false
    }

    // MARK: - Firestore binding

    func bind(uid: String?) {
        self.uid = uid
        listener?.remove()
        listener = nil

        guard let uid else {
            messages = []
            return
        }
        listener = db.collection("users/\(uid)/companionMessages")
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snap, _ in
                guard let snap else { return }
                self?.messages = snap.documents.compactMap { try? $0.data(as: CompanionMessage.self) }
            }
    }

    // MARK: - Sending

    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let flagged = Self.crisisSignal(in: trimmed)

        guard let uid else {
            // Preview / offline fallback: local echo, no backend.
            messages.append(CompanionMessage(role: .user, text: trimmed, flaggedForCrisis: flagged))
            isResponding = true
            let reply = flagged
                ? "I am really glad you told me. I am an AI companion, not a crisis service. Please reach out to someone who can help right now. You can call or text 988 any time."
                : "Thank you for sharing that. What feels most present for you right now?"
            messages.append(CompanionMessage(role: .assistant, text: reply))
            isResponding = false
            return
        }

        let messagesRef = db.collection("users/\(uid)/companionMessages")
        let userMessage = CompanionMessage(role: .user, text: trimmed, flaggedForCrisis: flagged)
        try? messagesRef.document(userMessage.id).setData(from: userMessage)

        isResponding = true
        defer { isResponding = false }

        let history = messages.suffix(20).map { ["role": $0.role.rawValue, "text": $0.text] }
        do {
            let result = try await functions.httpsCallable("companionChat").call([
                "message": trimmed,
                "history": history,
            ])
            let data = result.data as? [String: Any]
            let reply = (data?["reply"] as? String) ?? "I am here with you. Tell me a little more about what is on your mind."
            let assistantMessage = CompanionMessage(role: .assistant, text: reply)
            try? messagesRef.document(assistantMessage.id).setData(from: assistantMessage)
        } catch {
            let fallback = CompanionMessage(role: .assistant, text: "I could not reach the companion just now. Please try again in a moment.")
            try? messagesRef.document(fallback.id).setData(from: fallback)
        }
    }

    // MARK: - Safety (independent client side check)

    private static let crisisKeywords = [
        "suicide", "kill myself", "end my life", "want to die", "self harm",
        "self-harm", "hurt myself", "no reason to live", "cant go on", "can't go on",
    ]

    static func crisisSignal(in text: String) -> Bool {
        let lower = text.lowercased()
        return crisisKeywords.contains { lower.contains($0) }
    }

    // MARK: - History

    func clearHistory() {
        if uid != nil {
            Task {
                _ = try? await functions.httpsCallable("deleteCompanionHistory").call()
            }
        } else {
            messages.removeAll()
        }
    }
}
