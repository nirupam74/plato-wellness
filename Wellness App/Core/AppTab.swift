//
//  AppTab.swift
//  Wellness App
//
//  The four tabs, each with its own pillar tint from the Theme.
//

import SwiftUI

enum AppTab: Hashable {
    case home
    case nutrition
    case activity
    case restore
    case profile

    var tint: Color {
        switch self {
        case .home:      Theme.accent
        case .nutrition: Theme.nutrition
        case .activity:  Theme.activity
        case .restore:   Theme.restore
        case .profile:   Theme.accent
        }
    }
}
