//
//  RestoreSkincareEditorView.swift
//  Wellness App
//
//  Build and edit the morning and evening skincare routines: add steps, remove
//  them, and reorder by editing each step's order.
//

import SwiftUI

struct RestoreSkincareEditorView: View {
    @Environment(RestoreStore.self) private var restore

    var body: some View {
        @Bindable var restore = restore
        List {
            ForEach(RoutineTime.allCases) { time in
                Section {
                    let steps = restore.steps(for: time)
                    if steps.isEmpty {
                        Text("No steps yet. Add your first below.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(steps) { step in
                        Text(step.name)
                    }
                    .onDelete { offsets in
                        delete(offsets, time: time, in: restore)
                    }
                    .onMove { source, destination in
                        move(source, to: destination, time: time, in: restore)
                    }
                    RestoreAddStepRow(time: time)
                } header: {
                    Label(time.label, systemImage: time.systemImage)
                }
            }
        }
        .navigationTitle("Edit routines")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) { EditButton() }
        }
        .tint(Theme.restore)
    }

    private func delete(_ offsets: IndexSet, time: RoutineTime, in restore: RestoreStore) {
        let steps = restore.steps(for: time)
        for i in offsets where steps.indices.contains(i) {
            restore.removeStep(steps[i])
        }
        renumber(time: time, in: restore)
    }

    private func move(_ source: IndexSet, to destination: Int, time: RoutineTime, in restore: RestoreStore) {
        var steps = restore.steps(for: time)
        steps.move(fromOffsets: source, toOffset: destination)
        for (index, step) in steps.enumerated() {
            if let i = restore.skincareSteps.firstIndex(where: { $0.id == step.id }) {
                restore.skincareSteps[i].order = index
            }
        }
    }

    /// Compact the order values so later inserts append cleanly.
    private func renumber(time: RoutineTime, in restore: RestoreStore) {
        for (index, step) in restore.steps(for: time).enumerated() {
            if let i = restore.skincareSteps.firstIndex(where: { $0.id == step.id }) {
                restore.skincareSteps[i].order = index
            }
        }
    }
}

/// An inline "add a step" row with a text field and add button.
struct RestoreAddStepRow: View {
    @Environment(RestoreStore.self) private var restore
    var time: RoutineTime
    @State private var name: String = ""

    var body: some View {
        HStack {
            TextField("Add a step", text: $name)
                .submitLabel(.done)
                .onSubmit(add)
            Button(action: add) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Theme.restore)
            }
            .disabled(trimmed.isEmpty)
            .accessibilityLabel("Add \(time.label) step")
        }
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func add() {
        guard !trimmed.isEmpty else { return }
        let nextOrder = (restore.steps(for: time).map(\.order).max() ?? -1) + 1
        restore.addStep(SkincareStep(name: trimmed, timeOfDay: time, order: nextOrder))
        name = ""
    }
}

#Preview {
    NavigationStack {
        RestoreSkincareEditorView()
    }
    .withSampleStores()
}
