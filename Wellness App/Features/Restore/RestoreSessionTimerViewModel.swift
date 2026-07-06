//
//  RestoreSessionTimerViewModel.swift
//  Wellness App
//
//  A simple countdown timer for the timed sessions (yoga flows, meditation, and
//  body scans). Counts down from the chosen duration and reports completion.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class RestoreSessionTimerViewModel {
    let totalSeconds: Int
    private(set) var remainingSeconds: Int
    private(set) var isRunning = false
    private(set) var isComplete = false

    private var task: Task<Void, Never>?

    init(durationMin: Int) {
        let secs = max(1, durationMin) * 60
        self.totalSeconds = secs
        self.remainingSeconds = secs
    }

    var progress: Double {
        Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var remainingText: String {
        String(format: "%d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    func start() {
        guard !isRunning, !isComplete else { return }
        isRunning = true
        task = Task { await run() }
    }

    func pause() {
        isRunning = false
        task?.cancel()
        task = nil
    }

    func reset() {
        pause()
        remainingSeconds = totalSeconds
        isComplete = false
    }

    private func run() async {
        while isRunning && remainingSeconds > 0 {
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }
            guard isRunning else { return }
            remainingSeconds -= 1
        }
        if remainingSeconds <= 0 {
            isRunning = false
            isComplete = true
            task = nil
        }
    }
}
