//
//  CelebrationRequesting.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-3`: the vocabulary every celebration site speaks, and the narrow door it
//  speaks through. E's design and every number behind it:
//  `handoff/SESSION-OPENER-cta-celebrations-design.md`.
//
//  **A site asks; it never decides.** What a request GETS is `CelebrationPolicy`'s answer and
//  `CelebrationCenter`'s to enact — which is what makes E's cooldown (#6), the Celebrations switch
//  (#3) and the held-until-the-sheet-closes rule one rule each instead of nine copies.
//
//  **The environment defaults are INERT on purpose.** `\.celebrate` is a requester that answers
//  `.nothing`, and `\.celebrationCenter` is `nil`, so no preview, snapshot or test has to provide
//  anything and no leaf `init` changes. A singleton was rejected for the reason `FirebaseManager`
//  records: it cannot be tested at any price. `.environmentObject` was rejected because a missing
//  one traps the moment a body is built.
//

import CoreGraphics
import SwiftUI

/// The four moments E chose as full-screen milestones (#5, F3, F8). Each is the every-Confirm
/// celebration; the fireworks stay the stack-clearing Confirm's alone.
enum CelebrationMilestone: String, Equatable, CaseIterable {
    /// The Sorted, Journal it or Create Task that empties the capture inbox (R-a: not a discard).
    case inboxZero
    /// The Completed tap on a routine (R1–R5).
    case routineFinished
    /// A "Done for now" that makes seven consecutive days (R-b: exactly 7).
    case streakSeven
    /// Home's ring count crossing the goal, on any tab, once per day (F7).
    case dailyGoal
}

/// What is being celebrated. The size and the rule follow from this alone.
enum CelebrationKind: Equatable {
    /// A focus-sprint Confirm. `clearedStack` is the one that earns the fireworks.
    case confirm(clearedStack: Bool)
    case milestone(CelebrationMilestone)
    /// The in-place mini confetti pop (E's F6), from the point that was tapped.
    case pop
}

/// Every surface that can be in front of the user with a celebration site on it. E chose **one
/// drawing layer per surface** over a passthrough `UIWindow` (the design record's ARCH question),
/// so this list and the mounts must agree — `CelebrationMountCallSiteTests` is where that is
/// enforced.
enum CelebrationSurface: String, Equatable, CaseIterable {
    /// The tabs, and everything pushed inside them.
    case root
    /// The routine screen (`RootView+Doors`' full-screen cover).
    case routineCover
    /// Tasks' full-screen search surface, whose rows close tasks.
    case tasksSearch
    /// The Create Task sheet.
    case promoteSheet

    /// The promote sheet closes ITSELF after a successful promote, so a 5.4 s celebration drawn on
    /// its layer would be cut off after a fraction of a second. The centre holds a full-screen
    /// celebration requested from a surface like this one and releases it when the surface goes.
    var dismissesItself: Bool { self == .promoteSheet }
}

/// What a request actually got. Returned so a site can tell (for example) how long to hold a
/// congratulation view on screen — 5.4 s for a full celebration, about 2 s otherwise (R5).
enum CelebrationOutcome: Equatable {
    case fullScreen
    case inPlace
    case nothing
}

/// The door a site sees. Deliberately three methods: ask, and tell the centre when a surface comes
/// and goes. Nothing about drawing, queues or the switch crosses it.
protocol CelebrationRequesting {
    @discardableResult
    func request(_ kind: CelebrationKind, at origin: CGPoint?) -> CelebrationOutcome
    func surfacePresented(_ surface: CelebrationSurface)
    func surfaceDismissed(_ surface: CelebrationSurface)
}

/// The environment default: everything is asked, nothing happens. A preview or a snapshot test that
/// renders a site with a pop in it draws the site and no confetti, and needs no setup to do it.
struct InertCelebrationRequester: CelebrationRequesting {
    @discardableResult
    func request(_ kind: CelebrationKind, at origin: CGPoint?) -> CelebrationOutcome { .nothing }
    func surfacePresented(_ surface: CelebrationSurface) {}
    func surfaceDismissed(_ surface: CelebrationSurface) {}
}

private struct CelebrationRequestingKey: EnvironmentKey {
    static let defaultValue: any CelebrationRequesting = InertCelebrationRequester()
}

/// `nil`, not a shared instance: a layer that cannot see the centre draws nothing, which is the
/// right behaviour for a preview and the wrong one for the app — so the app's wiring is asserted by
/// `CelebrationMountCallSiteTests` rather than left to a default that would hide the mistake.
private struct CelebrationCenterKey: EnvironmentKey {
    static let defaultValue: CelebrationCenter? = nil
}

extension EnvironmentValues {
    /// What a SITE reaches for: `celebrate.request(.pop, at: point)`.
    var celebrate: any CelebrationRequesting {
        get { self[CelebrationRequestingKey.self] }
        set { self[CelebrationRequestingKey.self] = newValue }
    }

    /// What a LAYER reaches for — the observable object, because a layer has to redraw when the
    /// live list changes and a protocol cannot publish.
    var celebrationCenter: CelebrationCenter? {
        get { self[CelebrationCenterKey.self] }
        set { self[CelebrationCenterKey.self] = newValue }
    }
}
