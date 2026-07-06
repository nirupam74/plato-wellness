//
//  NotificationManager.swift
//  Wellness App
//
//  Local reminder scheduling: meals, water, bedtime, and movement. No remote
//  push, so no server or entitlement is needed. Reminders are recurring daily
//  calendar triggers, rescheduled whenever the user changes their preferences.
//

import Foundation
import Observation
import UserNotifications

@Observable
final class NotificationManager {
    var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    struct Preferences {
        var meals: Bool
        var water: Bool
        var bedtime: Bool
        var move: Bool
    }

    func refreshStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        isAuthorized = granted
        return granted
    }

    func reschedule(_ prefs: Preferences) {
        center.removeAllPendingNotificationRequests()
        guard isAuthorized else { return }

        if prefs.meals {
            schedule(id: "meal.breakfast", title: "Breakfast", body: "Log your breakfast to stay on track.", hour: 8, minute: 30)
            schedule(id: "meal.lunch", title: "Lunch", body: "Time to log lunch.", hour: 12, minute: 30)
            schedule(id: "meal.dinner", title: "Dinner", body: "Log your dinner for today.", hour: 18, minute: 30)
        }
        if prefs.water {
            schedule(id: "water.mid", title: "Hydrate", body: "A glass of water keeps you on target.", hour: 15, minute: 0)
        }
        if prefs.bedtime {
            schedule(id: "bedtime", title: "Wind down", body: "Bedtime soon. Wrap up today and rest well.", hour: 22, minute: 0)
        }
        if prefs.move {
            schedule(id: "move", title: "Move a little", body: "A short walk or workout counts.", hour: 17, minute: 0)
        }
    }

    private func schedule(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
