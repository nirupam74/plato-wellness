//
//  PreviewSupport.swift
//  Wellness App
//
//  Injects a fresh, seeded set of stores into any preview so feature views can
//  read them from the environment. Use `.withSampleStores()` in #Preview blocks.
//

import SwiftUI

extension View {
    func withSampleStores() -> some View {
        let state = AppState(seeded: true)
        return self
            .environment(state)
            .environment(state.user)
            .environment(state.nutrition)
            .environment(state.activity)
            .environment(state.restore)
            .environment(state.companion)
    }
}
