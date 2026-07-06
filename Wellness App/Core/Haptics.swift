//
//  Haptics.swift
//  Wellness App
//
//  Light haptic feedback for logging actions, gated by an accessibility
//  preference so people who find haptics distracting can turn them off.
//

import UIKit

enum Haptics {
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "a11y.haptics") as? Bool ?? true
    }

    static func tap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
