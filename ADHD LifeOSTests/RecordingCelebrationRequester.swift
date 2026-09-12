//
//  RecordingCelebrationRequester.swift
//  ADHD LifeOSTests
//
//  The double every celebration SITE is tested against. `F-CTACelebrations-5` is the first block
//  whose sites live in services rather than in view bodies, which is the whole reason the two
//  milestone services take `celebrate:` as a defaulted `init` parameter: a service test can watch
//  what was asked for, where a view body's request is only reachable by rendering.
//
//  Deliberately NOT a `CelebrationCenter` with an injected clock. What these tests assert is which
//  moments ASK — E's R-a (a discard is tidying, not doing), R-b (exactly seven) and the day marker.
//  What a request then GETS is `CelebrationPolicy`'s business and is tested there, once.
//

import CoreGraphics
import Foundation
@testable import ADHD_LifeOS

final class RecordingCelebrationRequester: CelebrationRequesting, @unchecked Sendable {
    /// What the site asked for, in order.
    private(set) var requested: [CelebrationKind] = []
    /// Where each request came from, index-aligned with `requested` — `nil` for a milestone with
    /// no origin but the screen.
    private(set) var origins: [CGPoint?] = []
    private(set) var presented: [CelebrationSurface] = []
    private(set) var dismissed: [CelebrationSurface] = []

    /// What `request` answers. A site that changes its behaviour on the outcome — the routine
    /// congratulation's length (R5) — needs to be driven down both branches.
    var outcome: CelebrationOutcome = .fullScreen

    var milestones: [CelebrationMilestone] {
        requested.compactMap {
            if case .milestone(let milestone) = $0 { return milestone }
            return nil
        }
    }

    @discardableResult
    func request(_ kind: CelebrationKind, at origin: CGPoint?) -> CelebrationOutcome {
        requested.append(kind)
        origins.append(origin)
        return outcome
    }

    func surfacePresented(_ surface: CelebrationSurface) { presented.append(surface) }
    func surfaceDismissed(_ surface: CelebrationSurface) { dismissed.append(surface) }
}
