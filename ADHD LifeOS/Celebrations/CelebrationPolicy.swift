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
//  - **#6** — a milestone fires in full only if no full-screen celebration has played inside the
//    cooldown; inside it, it gets the in-place celebration, so the moment is never unmarked.
//  - **R-c** — Confirm counts toward the cooldown but is never itself cooled down. E's #6 keeps
//    "every time" for Confirm.
//  - **R-h** — with the switch off a milestone still gets its fallback pop, because several
//    milestone sites (the ring, the Completed button) have no pop of their own.
//

import Foundation

enum CelebrationPolicy {
    /// **E, verbatim (F9): "please reduce that '30-minute cooldown' to 5 seconds for now so i can
    /// test it properly. i am undecided about the cooldown at the moment anyway. but adjust it to a
    /// 5-second cooldown for testing".**
    ///
    /// It is a TESTING value and it is E's to settle after `F-CTACelebrations-5` — including to
    /// remove entirely. **Do not "correct" it to the 30 minutes the design proposed**: that number
    /// was never E's. `CelebrationPolicyTests.testTheCooldownIsTheFiveSecondsEChoseForTesting`
    /// pins it and says why.
    static let milestoneCooldown: TimeInterval = 5

    /// What `kind` gets, given when the last full-screen celebration played and whether E's switch
    /// is on. `lastFullScreenAt` is `nil` before the first one of the launch.
    static func outcome(
        for kind: CelebrationKind,
        lastFullScreenAt: Date?,
        now: Date,
        celebrationsEnabled: Bool
    ) -> CelebrationOutcome {
        switch kind {
        case .pop:
            // E's #3: the switch is over the full-screen celebrations alone.
            return .inPlace
        case .confirm:
            // R-c: never cooled down, and off means nothing rather than something smaller — the
            // site already has its haptic, which the switch deliberately does not cover.
            return celebrationsEnabled ? .fullScreen : .nothing
        case .milestone:
            guard celebrationsEnabled else { return .inPlace }   // R-h
            guard let lastFullScreenAt else { return .fullScreen }
            return now.timeIntervalSince(lastFullScreenAt) < milestoneCooldown ? .inPlace : .fullScreen
        }
    }
}
