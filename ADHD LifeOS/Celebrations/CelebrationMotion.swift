//
//  CelebrationMotion.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-3`: which rendering a celebration gets under Reduce Motion — E's #7, "Fade
//  everywhere new", with Confirm as the ONE waiver of CLAUDE.md §7.2.
//
//  **This file exists so that the Confirm's own files never have to mention Reduce Motion.** With
//  one shared layer drawing every celebration, the setting has to be read SOMEWHERE; putting the
//  read here keeps `ConfettiPhysics`, `ConfirmCelebrationRecipe`, the three fireworks files and
//  `CelebrationFrame` free of it, which is the shape the waiver pin asserts
//  (`ConfirmCelebrationCallSiteTests.testTheConfirmCelebrationIgnoresReduceMotionByDesign`).
//
//  **Reduce Motion is resolved FIRST and the tier second** (§7.2): symbol effects, `PhaseAnimator`
//  and `keyframeAnimator` do not honour the setting themselves, so a site that picked a tier first
//  could reach a motion tier from a reduced path.
//

import Foundation

/// How a celebration is drawn. `.still` is not "less" — it is §7.2's replacement of motion with a
/// fade: the same pieces, in their final pose from the first frame, with only opacity travelling.
enum CelebrationRendering: Equatable {
    case full
    case still
}

enum CelebrationMotion {
    /// **E waived §7.2 for Confirm by name, 2026-09-11 ("B AND C"): with Reduce Motion ON it shows
    /// the glow AND real falling confetti.** The waiver covers that one moment and is not extended
    /// by analogy — E's #7 chose "Fade everywhere new" for every site this arc adds, accepting that
    /// the new milestones will not rain on their own phone.
    ///
    /// The Confirm branch is answered BEFORE the setting is read, so no reordering can route E's
    /// waived celebration down the reduced path.
    static func resolve(reduceMotion: Bool, kind: CelebrationKind) -> CelebrationRendering {
        if case .confirm = kind { return .full }
        return reduceMotion ? .still : .full
    }
}
