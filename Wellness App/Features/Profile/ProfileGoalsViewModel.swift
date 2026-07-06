//
//  ProfileGoalsViewModel.swift
//  Wellness App
//
//  Drives the "recompute targets" flow: after the user edits weight or activity
//  level, it produces a proposal comparing the current targets with the freshly
//  computed ones, so the user can accept or dismiss before anything is applied.
//

import Foundation
import Observation

/// A pending targets change, current versus proposed, awaiting user acceptance.
struct ProfileTargetsProposal: Identifiable {
    let id = UUID()
    let current: DailyTargets
    let proposed: DailyTargets

    var isNoop: Bool { current == proposed }
}

@Observable
final class ProfileGoalsViewModel {
    /// Non-nil while the accept/reject sheet should be shown.
    var proposal: ProfileTargetsProposal?

    /// Recompute from the profile's current inputs and, if anything changed,
    /// stage a proposal for the user to review.
    func recompute(using user: UserStore) {
        guard let current = user.profile?.targets,
              let proposed = user.recomputedTargets() else { return }
        let candidate = ProfileTargetsProposal(current: current, proposed: proposed)
        proposal = candidate.isNoop ? nil : candidate
    }

    func accept(using user: UserStore) {
        if let proposed = proposal?.proposed {
            user.applyTargets(proposed)
        }
        proposal = nil
    }

    func dismiss() {
        proposal = nil
    }
}
