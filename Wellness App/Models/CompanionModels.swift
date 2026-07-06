//
//  CompanionModels.swift
//  Wellness App
//
//  AI companion chat. The message model carries a crisis flag set by the
//  independent safety check (spec section 8.2).
//

import Foundation

struct CompanionMessage: Codable, Identifiable {
    var id: String
    var role: MessageRole
    var text: String
    var createdAt: Date
    var flaggedForCrisis: Bool

    init(
        id: String = UUID().uuidString,
        role: MessageRole,
        text: String,
        createdAt: Date = Date(),
        flaggedForCrisis: Bool = false
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.flaggedForCrisis = flaggedForCrisis
    }
}

/// A region-appropriate crisis resource shown one tap from the companion.
struct CrisisResource: Identifiable {
    var id = UUID()
    var name: String
    var detail: String
    var callNumber: String?
    var textNumber: String?
}
