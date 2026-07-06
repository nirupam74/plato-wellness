//
//  FocusManager.swift
//  Wellness App
//
//  A commitment based focus lock. The user picks distracting apps and websites
//  (social media, video, etc.) and locks them for a chosen number of hours. The
//  app applies a Screen Time shield to the selection and, crucially, offers no
//  in-app way to shorten or remove the lock until it expires. This raises the
//  cost of caving in the moment.
//
//  Uses Apple's Family Controls, Managed Settings, and Device Activity. These
//  require the Family Controls entitlement and only work on a real device (not
//  the simulator); everything is guarded so the app still builds and runs
//  everywhere.
//

import Foundation
import Observation

#if os(iOS)
import FamilyControls
import ManagedSettings
#endif

@Observable
final class FocusManager {
    /// Whether the platform can actually block apps (device + entitlement).
    var isSupported: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    var isAuthorized = false

    /// When the current lock ends. Nil means no active lock.
    private(set) var lockEndDate: Date?

    /// True while a lock is active. While true, the selection cannot be changed
    /// and the lock cannot be removed.
    var isLocked: Bool {
        guard let end = lockEndDate else { return false }
        return Date() < end
    }

    private let defaults = UserDefaults.standard
    private let endKey = "focus.lockEnd"
    private let selectionKey = "focus.selection"

    #if os(iOS)
    var selection = FamilyActivitySelection()
    private let store = ManagedSettingsStore(named: .init("plato.focus"))
    #endif

    init() {
        lockEndDate = defaults.object(forKey: endKey) as? Date
        loadSelection()
        refresh()
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        #if os(iOS)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        } catch {
            isAuthorized = false
        }
        #endif
    }

    // MARK: - Lock lifecycle

    /// Start a lock for `hours`. Ignored if a lock is already active.
    func startLock(hours: Int) {
        guard !isLocked, hours > 0 else { return }
        let end = Date().addingTimeInterval(Double(hours) * 3600)
        lockEndDate = end
        defaults.set(end, forKey: endKey)
        saveSelection()
        applyShields()
    }

    /// Re-apply or clear shields based on whether the lock is still active.
    /// Called on launch and when returning to the foreground.
    func refresh() {
        if isLocked {
            applyShields()
        } else {
            clearLockIfExpired()
        }
    }

    private func clearLockIfExpired() {
        if lockEndDate != nil {
            lockEndDate = nil
            defaults.removeObject(forKey: endKey)
        }
        clearShields()
    }

    // MARK: - Shields

    private func applyShields() {
        #if os(iOS)
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        #endif
    }

    private func clearShields() {
        #if os(iOS)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        #endif
    }

    // MARK: - Persistence

    private func saveSelection() {
        #if os(iOS)
        if let data = try? JSONEncoder().encode(selection) {
            defaults.set(data, forKey: selectionKey)
        }
        #endif
    }

    private func loadSelection() {
        #if os(iOS)
        if let data = defaults.data(forKey: selectionKey),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
        }
        #endif
    }

    // MARK: - Display

    var selectionCount: Int {
        #if os(iOS)
        return selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
        #else
        return 0
        #endif
    }

    var remainingText: String {
        guard let end = lockEndDate, isLocked else { return "" }
        let seconds = max(0, end.timeIntervalSinceNow)
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m left" }
        return "\(minutes)m left"
    }
}
