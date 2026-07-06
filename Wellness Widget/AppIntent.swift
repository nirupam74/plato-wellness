//
//  AppIntent.swift
//  Wellness Widget
//
//  Interactive intent so the water widget can log a glass straight from the
//  home or lock screen. It queues the amount in the shared App Group; the app
//  reconciles it into the real diary the next time it is opened.
//

import WidgetKit
import AppIntents

struct LogWaterIntent: AppIntent {
    static var title: LocalizedStringResource { "Log a glass of water" }
    static var description: IntentDescription { "Adds 250 ml of water to today." }

    func perform() async throws -> some IntentResult {
        if let defaults = UserDefaults(suiteName: WidgetShared.suiteName) {
            let glass = 250
            let pending = defaults.integer(forKey: WidgetShared.Key.pendingWaterMl)
            defaults.set(pending + glass, forKey: WidgetShared.Key.pendingWaterMl)
            // Optimistically bump the displayed total so the widget updates now.
            let shown = defaults.integer(forKey: WidgetShared.Key.waterMl)
            defaults.set(shown + glass, forKey: WidgetShared.Key.waterMl)
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
