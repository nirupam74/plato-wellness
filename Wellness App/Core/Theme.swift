//
//  Theme.swift
//  Wellness App
//
//  Single source of truth for color. One accent plus a semantic color per
//  pillar (nutrition, activity, restore) so charts and progress read instantly.
//  These literals are a starting point, promote them to the asset catalog with
//  light and dark variants when the design system firms up.
//

import SwiftUI

enum Theme {
    /// App accent. Falls back to the asset-catalog AccentColor.
    static let accent = Color.accentColor

    // Per-pillar semantic colors.
    static let nutrition = Color(red: 0.95, green: 0.55, blue: 0.25) // warm amber
    static let activity  = Color(red: 0.20, green: 0.65, blue: 0.85) // energetic blue
    static let restore   = Color(red: 0.55, green: 0.45, blue: 0.85) // calm violet
}
