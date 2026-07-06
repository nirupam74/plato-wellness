//
//  RestoreSessionTimerView.swift
//  Wellness App
//
//  A countdown timer screen for yoga, meditation, and body-scan sessions. On
//  completion it records a RestoreSession of the given type.
//

import SwiftUI

struct RestoreSessionTimerView: View {
    @Environment(RestoreStore.self) private var restore
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: RestoreSessionTimerViewModel
    @State private var recorded = false

    private let type: SessionType
    private let name: String
    private let detail: String
    private let durationMin: Int

    init(type: SessionType, name: String, detail: String, durationMin: Int) {
        self.type = type
        self.name = name
        self.detail = detail
        self.durationMin = durationMin
        _viewModel = State(initialValue: RestoreSessionTimerViewModel(durationMin: durationMin))
    }

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 6) {
                Image(systemName: type.systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(Theme.restore)
                Text(name).font(.title2.weight(.bold))
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()

            ZStack {
                MetricRing(progress: viewModel.progress, tint: Theme.restore, lineWidth: 14)
                    .frame(width: 240, height: 240)
                VStack(spacing: 4) {
                    Text(viewModel.isComplete ? "Done" : viewModel.remainingText)
                        .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                    Text(viewModel.isComplete ? "Session complete" : "remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(name) timer")
            .accessibilityValue(viewModel.isComplete ? "Complete" : "\(viewModel.remainingText) remaining")

            Spacer()

            controls
        }
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(type.label)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.isComplete) { _, done in
            if done { recordSession() }
        }
        .onDisappear { viewModel.pause() }
        .tint(Theme.restore)
    }

    @ViewBuilder private var controls: some View {
        if viewModel.isComplete {
            Label("Recorded \(durationMin) mindful minutes.", systemImage: "checkmark.circle.fill")
                .foregroundStyle(Theme.restore)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        } else {
            HStack(spacing: 16) {
                Button {
                    viewModel.isRunning ? viewModel.pause() : viewModel.start()
                } label: {
                    Label(viewModel.isRunning ? "Pause" : "Start",
                          systemImage: viewModel.isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    viewModel.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func recordSession() {
        guard !recorded else { return }
        recorded = true
        restore.addSession(RestoreSession(type: type, name: name, durationMin: durationMin))
    }
}

#Preview {
    NavigationStack {
        RestoreSessionTimerView(
            type: .meditation,
            name: "Focus",
            detail: "A short seated meditation to settle your attention.",
            durationMin: 10
        )
    }
    .withSampleStores()
}
