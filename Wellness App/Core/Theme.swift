//
//  Theme.swift
//  Wellness App
//
//  Single source of truth for color. A calm blue and white system: one hero
//  blue, with each pillar a distinct but harmonious member of the blue family so
//  the whole app reads as one palette on white and grouped backgrounds.
//

import SwiftUI

extension Color {
    /// Build a color from a 0xRRGGBB hex value.
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}

enum Theme {
    /// App accent. The hero blue used for primary actions and highlights.
    static let accent = Color(hex: 0x2F6BFF)

    // Per-pillar colors, all in the blue family.
    static let nutrition = Color(hex: 0x3B82F6) // blue
    static let activity  = Color(hex: 0x0EA5E9) // sky
    static let restore   = Color(hex: 0x6366F1) // indigo
}
