//
//  CelebrationPolicy.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-3`: the one place that decides what a request GETS. Pure, so the rule can be
//  tested rather than inferred from what happens to appear on screen.
//
//  E's answers, and none of them is a default:
//  - **#3** — the Celebrations switch turns off every FULL-SCREEN celebration; "haptics and
//    in-place feedback stay".
//  - **#6, and then its REVERSAL** — a cooldown was designed, shipped at E's 5 s testing value,
//    and removed entirely by E on 2026-09-12 once they had lived with it. Milestones now play
//    every time, like Confirms. R-c went with it: with no cooldown there is nothing to count
//    toward.
//  - **R-h** — with the switch off a milestone still gets its fallback pop, because several
//    milestone sites (the ring, the Completed button) have no pop of their own.
//

import Foundation

enum CelebrationPolicy {
    /// What `kind` gets, given only whether E's Celebrations switch is on.
    ///
    /// **There is no cooldown, and its absence is a decision rather than an omission.** E's #6
    /// originally asked for one, it shipped at 5 s as E's own testing value (F9: *"i am undecided
    /// about the cooldown at the moment anyway"*), and E removed it on 2026-09-12 after living
    /// with it on the phone: *"Remove the cooldown entirely."*
    ///
    /// So a milestone now behaves like a Confirm: it plays every time. Two that land together
    /// OVERLAP rather than one being downgraded — which is not a new rule but the one E already
    /// approved for quick Confirms (the Confirm record's R1, and `CelebrationQueue.fullScreenCap`
    /// still caps the overlap at three).
    ///
    /// The function takes no clock at all as a result, which is the point:
    /// `testThePolicyHasNoClockAndNoCooldownConstant` keeps a frequency rule from creeping back in
    /// as a private constant nobody discussed.
    static func outcome(for kind: CelebrationKind, celebrationsEnabled: Bool) -> CelebrationOutcome {
        switch kind {
        case .pop:
            // E's #3: the switch is over the full-screen celebrations alone.
            return .inPlace
        case .confirm:
            // Off means nothing rather than something smaller — the site already has its haptic,
            // which the switch deliberately does not cover.
            return celebrationsEnabled ? .fullScreen : .nothing
        case .milestone:
            // R-h: with the switch off a milestone still gets its fallback pop, because several
            // milestone sites (the ring, the Completed button) have no pop of their own. R-h was
            // never about the cooldown and survives its removal.
            return celebrationsEnabled ? .fullScreen : .inPlace
        }
    }
}
