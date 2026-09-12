//
//  CelebrationCenterTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-3`: the one app-level owner every celebration site asks. E chose ONE LAYER
//  PER SURFACE over a passthrough `UIWindow` (the design record's ARCH question), and this is the
//  object that makes that choice work: it knows which surface is frontmost, tags each burst with
//  it, and holds a full-screen celebration requested from a sheet that is about to close itself.
//
//  Everything here runs on an injected clock. `CelebrationCenter` is a `@StateObject` the App owns,
//  so a test that had to wait five real seconds for a cooldown would be a test nobody runs.
//

import CoreGraphics
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CelebrationCenterTests: XCTestCase {

    private let launch = Date(timeIntervalSince1970: 1_800_000_000)

    /// A centre whose clock and switch the test owns. `celebrationsGate` defaults to E's real
    /// Settings switch in production; injected here so no test writes the simulator's own
    /// `UserDefaults` (block 2's rule).
    private func centre(
        at clock: Clock, celebrationsEnabled: Bool = true,
        chime: @escaping (CelebrationKind) -> Void = { _ in },
        feel: @escaping (HapticFeel) -> Void = { _ in }
    ) -> CelebrationCenter {
        CelebrationCenter(
            now: { clock.now }, celebrationsGate: { celebrationsEnabled }, chime: chime, feel: feel
        )
    }

    private final class Clock {
        var now: Date
        init(_ now: Date) { self.now = now }
        func advance(_ seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
    }

    // MARK: - Requesting

    func testAConfirmEnqueuesOneFullScreenBurstAndReportsItAsSuch() {
        let clock = Clock(launch)
        let center = centre(at: clock)
        XCTAssertEqual(center.request(.confirm(clearedStack: true), at: nil), .fullScreen)
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertEqual(center.bursts[0].kind, .confirm(clearedStack: true))
        XCTAssertEqual(center.bursts[0].start, launch)
    }

    /// The gate is the whole of E's #3 on this path: with the switch off a Confirm enqueues
    /// NOTHING, so the frame clock never starts and no pixel changes.
    func testWithTheCelebrationsSwitchOffAConfirmEnqueuesNothingAtAll() {
        let center = centre(at: Clock(launch), celebrationsEnabled: false)
        XCTAssertEqual(center.request(.confirm(clearedStack: false), at: nil), .nothing)
        XCTAssertTrue(center.bursts.isEmpty)
        XCTAssertNil(center.lastFullScreenAt, "A refused Confirm still stamped the cooldown.")
    }

    func testWithTheSwitchOffAPopIsStillEnqueued() {
        let center = centre(at: Clock(launch), celebrationsEnabled: false)
        XCTAssertEqual(center.request(.pop, at: CGPoint(x: 10, y: 20)), .inPlace)
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertEqual(center.bursts[0].origin, CGPoint(x: 10, y: 20))
    }

    /// **`ordinal` did three jobs in the Confirm build** — SwiftUI id, confetti seed and haptic
    /// trigger. The centre's counter takes the first two for EVERY kind, so a pop and a Confirm can
    /// never be handed the same `id` (SwiftUI would reuse the view) or the same seed (they would
    /// draw the same paper).
    func testEveryBurstGetsItsOwnOrdinalWhateverKindItIs() {
        let center = centre(at: Clock(launch))
        center.request(.pop, at: .zero)
        center.request(.confirm(clearedStack: false), at: nil)
        center.request(.pop, at: .zero)
        XCTAssertEqual(center.bursts.map(\.ordinal), [1, 2, 3])
        XCTAssertEqual(Set(center.bursts.map(\.id)).count, 3)
    }

    /// R-c: Confirm counts toward the cooldown. A pop does not — it is not a full-screen
    /// celebration and cooling a milestone down because someone closed a task would be wrong.
    func testAFullScreenStampsTheCooldownAndAPopDoesNot() {
        let clock = Clock(launch)
        let center = centre(at: clock)
        center.request(.pop, at: .zero)
        XCTAssertNil(center.lastFullScreenAt)
        center.request(.confirm(clearedStack: false), at: nil)
        XCTAssertEqual(center.lastFullScreenAt, launch)
        clock.advance(1)
        XCTAssertEqual(
            center.request(.milestone(.inboxZero), at: nil), .inPlace,
            "A milestone one second after a Confirm played in full. R-c makes Confirm count toward"
                + " the cooldown even though it is never cooled down itself."
        )
    }

    // MARK: - Surfaces

    func testABurstIsTaggedWithWhicheverSurfaceIsFrontmost() {
        let center = centre(at: Clock(launch))
        center.surfacePresented(.routineCover)
        center.request(.milestone(.routineFinished), at: nil)
        XCTAssertEqual(center.bursts[0].surface, .routineCover)
        XCTAssertEqual(center.bursts(on: .routineCover).count, 1)
        XCTAssertTrue(
            center.bursts(on: .root).isEmpty,
            "The root layer draws a burst that belongs to the cover above it, where it is invisible."
        )
    }

    /// The root is the base of the stack, not a presentation. Its layer calls `surfacePresented`
    /// unconditionally on appear, so the centre has to ignore it rather than seat it on top.
    func testPresentingTheRootSurfaceNeverChangesTheFrontmost() {
        let center = centre(at: Clock(launch))
        center.surfacePresented(.tasksSearch)
        center.surfacePresented(.root)
        XCTAssertEqual(center.frontmost, .tasksSearch)
    }

    func testDismissingASurfacePutsTheOneBeneathItBackInFront() {
        let center = centre(at: Clock(launch))
        center.surfacePresented(.tasksSearch)
        center.surfacePresented(.promoteSheet)
        center.surfaceDismissed(.promoteSheet)
        XCTAssertEqual(center.frontmost, .tasksSearch)
        center.surfaceDismissed(.tasksSearch)
        XCTAssertEqual(center.frontmost, .root)
    }

    // MARK: - The chime hook (F5)

    /// The hook fires for the full-screen celebrations only — E's F5, "Full-screen milestones
    /// only". The PLAYER behind it, and the Celebration sounds switch it reads, arrive in
    /// `F-CTACelebrations-7`; this is the seam it plugs into.
    func testTheChimeHookFiresForAFullScreenAndNeverForAPop() {
        var chimed: [CelebrationKind] = []
        let center = centre(at: Clock(launch), chime: { chimed.append($0) })
        center.request(.pop, at: .zero)
        XCTAssertTrue(chimed.isEmpty)
        center.request(.confirm(clearedStack: false), at: nil)
        XCTAssertEqual(chimed, [.confirm(clearedStack: false)])
    }

    func testARefusedCelebrationNeverChimes() {
        var chimed: [CelebrationKind] = []
        let center = centre(at: Clock(launch), celebrationsEnabled: false, chime: { chimed.append($0) })
        center.request(.confirm(clearedStack: false), at: nil)
        XCTAssertTrue(chimed.isEmpty)
    }

    // MARK: - R-d: the one milestone whose feel the centre owns

    /// **R-d, and it is an exception to the single-owner rule rather than a hole in it.** Every
    /// other milestone rides a site that already plays its own haptic once — Sorted, Done for now,
    /// Completed. The daily goal has no site at all: it fires from a number changing, about a
    /// second after whatever moved it, possibly on another tab. So the centre plays it.
    func testTheCentrePlaysTheSuccessFeelForTheDailyGoalBecauseNoSiteDoes() {
        var felt: [HapticFeel] = []
        let center = centre(at: Clock(launch), feel: { felt.append($0) })
        center.request(.milestone(.dailyGoal), at: nil)
        XCTAssertEqual(felt, [.success])
    }

    /// **A DOWNGRADED daily goal keeps its feel**, which is the same argument R-h makes for the
    /// fallback pop: inside the cooldown, or with E's switch off, this milestone would otherwise be
    /// the one moment in the app that happens with no feedback whatsoever.
    func testADowngradedDailyGoalStillGetsItsFeel() {
        let clock = Clock(launch)
        var felt: [HapticFeel] = []
        let center = centre(at: clock, feel: { felt.append($0) })
        center.request(.confirm(clearedStack: false), at: nil)
        clock.advance(1)
        XCTAssertEqual(center.request(.milestone(.dailyGoal), at: nil), .inPlace)
        XCTAssertEqual(felt, [.success])
    }

    func testTheOtherMilestonesGetNoFeelFromTheCentreBecauseTheirSitesHaveOne() {
        var felt: [HapticFeel] = []
        let center = centre(at: Clock(launch), feel: { felt.append($0) })
        center.request(.milestone(.inboxZero), at: nil)
        center.request(.milestone(.streakSeven), at: nil)
        center.request(.pop, at: .zero)
        XCTAssertTrue(felt.isEmpty, "The centre buzzed twice for a moment that already buzzed once.")
    }

    // MARK: - Expiry

    func testPruningRemovesOnlyWhatHasFinished() {
        let clock = Clock(launch)
        let center = centre(at: clock)
        center.request(.pop, at: .zero)
        clock.advance(0.5)
        center.request(.confirm(clearedStack: false), at: nil)
        clock.advance(0.6)
        center.prune(now: clock.now)
        XCTAssertEqual(
            center.bursts.map(\.ordinal), [2],
            "Pruning at 1.1 s should take the one-second pop and leave the 5.4 s Confirm."
        )
    }
}
