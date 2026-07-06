//
//  RestoreWaterQuickAddSheet.swift
//  Wellness App
//
//  A custom-amount water logger used by the nav-bar quick add. The water detail
//  screen offers one-tap glass and bottle buttons directly.
//

import SwiftUI

struct RestoreWaterQuickAddSheet: View {
    @Environment(RestoreStore.self) private var restore
    @Environment(\.dismiss) private var dismiss

    @State private var amountMl: Int = 250

    private let presets: [Int] = [100, 250, 330, 500, 750]

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    Stepper(value: $amountMl, in: 50...2000, step: 50) {
                        Text("\(amountMl) ml")
                            .font(.title3.weight(.semibold))
                            .contentTransition(.numericText())
                    }
                }
                Section("Quick amounts") {
                    HStack {
                        ForEach(presets, id: \.self) { ml in
                            Button("\(ml)") { amountMl = ml }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("Log water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        restore.addWater(ml: amountMl)
                        dismiss()
                    }
                }
            }
        }
        .tint(Theme.restore)
    }
}

#Preview {
    RestoreWaterQuickAddSheet()
        .withSampleStores()
}
