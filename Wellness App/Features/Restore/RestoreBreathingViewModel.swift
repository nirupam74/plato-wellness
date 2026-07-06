//
//  RestoreBreathingViewModel.swift
//  Wellness App
//
//  Drives the animated breathing pacer: it walks a technique's phase cycle
//  (inhale, hold, exhale, hold) second by second until the chosen duration is
//  reached, then reports a completed session back to the caller.
//

import SwiftUI
import Observation

/// One phase within a breathing cycle.
enum RestoreBreathPhase: Equatable {
    case inhale, holdIn, exhale, holdOut

    var label: String {
        switch self {
        case .inhale:  "Breathe in"
        case .holdIn:  "Hold"
        case .exhale:  "Breathe out"
        case .holdOut: "Hold"
        }
    }

    /// Target scale of the pacer circle for this phase.
    var targetScale: CGFloat {
        switch self {
        case .inhale:  1.0
        case .holdIn:  1.0
        case .exhale:  0.5
        case .holdOut: 0.5
        }
    }
}

/// A named breathing pattern, described as an ordered list of timed phases.
struct RestoreBreathingTechnique: Identifiable {
    var id: String { name }
    var name: String
    var detail: String
    /// The repeating cycle: each phase with its length in seconds. Zero-length
    /// phases are skipped so patterns like coherent breathing work too.
    var cycle: [(phase: RestoreBreathPhase, seconds: Int)]

    static let box = RestoreBreathingTechnique(
        name: "Box breathing",
        detail: "Equal 4 count in, hold, out, hold. Calms and steadies.",
        cycle: [(.inhale, 4), (.holdIn, 4), (.exhale, 4), (.holdOut, 4)]
    )

    static let fourSevenEight = RestoreBreathingTechnique(
        name: "4-7-8 breathing",
        detail: "In for 4, hold for 7, out for 8. Eases you toward rest.",
        cycle: [(.inhale, 4), (.holdIn, 7), (.exhale, 8)]
    )

    static let coherent = RestoreBreathingTechnique(
        name: "Coherent breathing",
        detail: "Smooth 5 count in and out. Balances body and mind.",
        cycle: [(.inhale, 5), (.exhale, 5)]
    )

    static let all: [RestoreBreathingTechnique] = [.box, .fourSevenEight, .coherent]
}

@MainActor
@Observable
final class RestoreBreathingViewModel {
    let technique: RestoreBreathingTechnique
    let targetSeconds: Int

    private(set) var phase: RestoreBreathPhase = .inhale
    private(set) var phaseSecondsRemaining: Int = 0
    private(set) var currentPhaseLength: Int = 1
    private(set) var elapsedSeconds: Int = 0
    private(set) var isRunning = false
    private(set) var isComplete = false

    private var task: Task<Void, Never>?

    init(technique: RestoreBreathingTechnique, durationMin: Int) {
        self.technique = technique
        self.targetSeconds = max(1, durationMin) * 60
        if let first = technique.cycle.first {
            self.phase = first.phase
            self.phaseSecondsRemaining = first.seconds
            self.currentPhaseLength = max(1, first.seconds)
        }
    }

    var progress: Double {
        Double(elapsedSeconds) / Double(targetSeconds)
    }

    var elapsedText: String {
        String(format: "%d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
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

    func stop() {
        pause()
        elapsedSeconds = 0
        isComplete = false
        if let first = technique.cycle.first {
            phase = first.phase
            phaseSecondsRemaining = first.seconds
            currentPhaseLength = max(1, first.seconds)
        }
    }

    private func run() async {
        let steps = technique.cycle.filter { $0.seconds > 0 }
        guard !steps.isEmpty else { return }
        var index = 0
        while isRunning && elapsedSeconds < targetSeconds {
            let step = steps[index % steps.count]
            phase = step.phase
            currentPhaseLength = step.seconds
            phaseSecondsRemaining = step.seconds
            var remaining = step.seconds
            while remaining > 0 && isRunning && elapsedSeconds < targetSeconds {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return // cancelled
                }
                guard isRunning else { return }
                remaining -= 1
                elapsedSeconds += 1
                phaseSecondsRemaining = remaining
            }
            index += 1
        }
        if elapsedSeconds >= targetSeconds {
            complete()
        }
    }

    private func complete() {
        isRunning = false
        isComplete = true
        task = nil
    }
}
