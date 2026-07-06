//
//  RestoreBreathingView.swift
//  Wellness App
//
//  A guided breathing session with an animated expanding and contracting pacer
//  circle. On completion it records a breathing RestoreSession.
//

import SwiftUI

struct RestoreBreathingView: View {
    @Environment(RestoreStore.self) private var restore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewModel: RestoreBreathingViewModel
    @State private var circleScale: CGFloat = 0.5
    @State private var recorded = false

    private let durationMin: Int

    init(technique: RestoreBreathingTechnique, durationMin: Int = 3) {
        self.durationMin = durationMin
        _viewModel = State(initialValue: RestoreBreathingViewModel(technique: technique, durationMin: durationMin))
    }

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 6) {
                Text(viewModel.technique.name).font(.title2.weight(.bold))
                Text(viewModel.technique.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()

            pacer

            Spacer()

            VStack(spacing: 4) {
                Text(viewModel.elapsedText)
                    .font(.title3.monospacedDigit())
                Text("of \(durationMin) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            controls
        }
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Breathing")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.phase) { _, newPhase in
            animateCircle(to: newPhase.targetScale)
        }
        .onChange(of: viewModel.isComplete) { _, done in
            if done { recordSession() }
        }
        .onDisappear { viewModel.pause() }
        .tint(Theme.restore)
    }

    private var pacer: some View {
        ZStack {
            Circle()
                .fill(Theme.restore.opacity(0.12))
                .frame(width: 260, height: 260)
            Circle()
                .fill(Theme.restore.opacity(0.35))
                .frame(width: 260, height: 260)
                .scaleEffect(circleScale)
            Circle()
                .stroke(Theme.restore, lineWidth: 3)
                .frame(width: 260, height: 260)
                .scaleEffect(circleScale)
            VStack(spacing: 6) {
                Text(viewModel.isComplete ? "Done" : viewModel.phase.label)
                    .font(.title2.weight(.semibold))
                if !viewModel.isComplete && viewModel.isRunning {
                    Text("\(viewModel.phaseSecondsRemaining)")
                        .font(.largeTitle.monospacedDigit().weight(.bold))
                }
            }
            .foregroundStyle(Theme.restore)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breathing pacer")
        .accessibilityValue(viewModel.isComplete ? "Complete" : viewModel.phase.label)
    }

    @ViewBuilder private var controls: some View {
        if viewModel.isComplete {
            Label("Session complete. Nice work.", systemImage: "checkmark.circle.fill")
                .foregroundStyle(Theme.restore)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        } else {
            HStack(spacing: 16) {
                Button {
                    if viewModel.isRunning {
                        viewModel.pause()
                    } else {
                        viewModel.start()
                        animateCircle(to: viewModel.phase.targetScale)
                    }
                } label: {
                    Label(viewModel.isRunning ? "Pause" : "Start",
                          systemImage: viewModel.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    viewModel.stop()
                    circleScale = 0.5
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func animateCircle(to scale: CGFloat) {
        guard viewModel.isRunning else { return }
        if reduceMotion {
            circleScale = scale
        } else {
            withAnimation(.easeInOut(duration: Double(viewModel.currentPhaseLength))) {
                circleScale = scale
            }
        }
    }

    private func recordSession() {
        guard !recorded else { return }
        recorded = true
        restore.addSession(RestoreSession(
            type: .breathing,
            name: viewModel.technique.name,
            durationMin: durationMin
        ))
    }
}

#Preview {
    NavigationStack {
        RestoreBreathingView(technique: .box, durationMin: 3)
    }
    .withSampleStores()
}
