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
        at clock: Clock, celebrationsEnabled: Bool = true, chime: @escaping (CelebrationKind) -> Void = { _ in }
    ) -> CelebrationCenter {
        CelebrationCenter(
            now: { clock.now }, celebrationsGate: { celebrationsEnabled }, chime: chime
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

    // MARK: - Held full-screens

    /// The Create Task sheet dismisses ITSELF after a successful promote, so a 5.4 s celebration
    /// drawn on its layer would be cut off after a fraction of a second. Held instead, and played
    /// over whatever is behind it once it has gone (design §1, §3).
    func testAFullScreenRequestedFromASelfDismissingSheetIsHeldUntilItCloses() {
        let clock = Clock(launch)
        let center = centre(at: clock)
        center.surfacePresented(.promoteSheet)
        XCTAssertEqual(center.request(.milestone(.inboxZero), at: nil), .fullScreen)
        XCTAssertTrue(
            center.bursts.isEmpty,
            "The milestone drew on the sheet that is about to close, so it is cut off mid-flight."
        )
        clock.advance(0.5)
        center.surfaceDismissed(.promoteSheet)
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertEqual(center.bursts[0].surface, .root, "The released burst still belongs to the sheet.")
    }

    /// Released with `start = now`, never with the instant it was requested: otherwise half the
    /// celebration has already elapsed before anything is drawn.
    func testAHeldBurstStartsWhenItIsReleasedRatherThanWhenItWasRequested() {
        let clock = Clock(launch)
        let center = centre(at: clock)
        center.surfacePresented(.promoteSheet)
        center.request(.milestone(.inboxZero), at: nil)
        clock.advance(0.45)
        center.surfaceDismissed(.promoteSheet)
        XCTAssertEqual(center.bursts[0].start, launch.addingTimeInterval(0.45))
    }

    /// R-g: a surface left open for minutes must not release a stale celebration when it finally
    /// closes. Sixty seconds, and the burst is simply dropped.
    func testAHeldBurstOlderThanAMinuteIsDroppedRatherThanReleased() {
        let clock = Clock(launch)
        let center = centre(at: clock)
        center.surfacePresented(.promoteSheet)
        center.request(.milestone(.inboxZero), at: nil)
        clock.advance(CelebrationCenter.heldLifetime + 0.01)
        center.surfaceDismissed(.promoteSheet)
        XCTAssertTrue(center.bursts.isEmpty)
    }

    // MARK: - When a held burst stamps the cooldown and chimes (`F-CTACelebrations-5`)
    //
    // **The defect these close was LATENT until this block.** `request(_:at:)` stamped
    // `lastFullScreenAt` and fired the chime the moment the outcome was `.fullScreen` — BEFORE the
    // held branch — and `releaseHeld()` set neither. Nothing could reach it while the only thing
    // asking for a full screen was the Confirm bridge, which sits below every sheet. Inbox zero
    // via the Create Task sheet is exactly the held path, so from this block on it is live.
    //
    // The register (§B.00b) named the two consequences and the gap: `CelebrationCenterTests` had
    // no test of held-burst stamp or chime timing at all.

    /// A celebration that has not been drawn has not played, so it cannot have started a cooldown.
    func testAHeldBurstStampsTheCooldownOnlyWhenItIsReleased() {
        let clock = Clock(launch)
        let center = centre(at: clock)
        center.surfacePresented(.promoteSheet)
        center.request(.milestone(.inboxZero), at: nil)
        XCTAssertNil(
            center.lastFullScreenAt,
            "A burst still waiting behind the sheet stamped the cooldown, so a milestone that"
                + " follows it is cooled down by a celebration nobody has seen."
        )
        clock.advance(0.45)
        center.surfaceDismissed(.promoteSheet)
        XCTAssertEqual(
            center.lastFullScreenAt, launch.addingTimeInterval(0.45),
            "The cooldown must run from the moment the paper actually starts falling."
        )
    }

    /// F5's chime belongs to the celebration, not to the request: chiming while the Create Task
    /// sheet is still up is a sound with nothing on screen to explain it.
    func testAHeldBurstChimesWhenItPlaysAndNotWhileItWaits() {
        let clock = Clock(launch)
        var chimed: [CelebrationKind] = []
        let center = centre(at: clock, chime: { chimed.append($0) })
        center.surfacePresented(.promoteSheet)
        center.request(.milestone(.inboxZero), at: nil)
        XCTAssertTrue(chimed.isEmpty, "The chime played over a sheet that had not closed yet.")
        clock.advance(0.45)
        center.surfaceDismissed(.promoteSheet)
        XCTAssertEqual(chimed, [.milestone(.inboxZero)])
    }

    /// R-g drops a burst that has waited more than a minute. It never appeared, so it must leave
    /// nothing behind it either — no chime, and above all no cooldown.
    func testAHeldBurstDroppedAtSixtySecondsNeitherStampsNorChimes() {
        let clock = Clock(launch)
        var chimed: [CelebrationKind] = []
        let center = centre(at: clock, chime: { chimed.append($0) })
        center.surfacePresented(.promoteSheet)
        center.request(.milestone(.inboxZero), at: nil)
        clock.advance(CelebrationCenter.heldLifetime + 0.01)
        center.surfaceDismissed(.promoteSheet)
        XCTAssertTrue(center.bursts.isEmpty)
        XCTAssertNil(center.lastFullScreenAt)
        XCTAssertTrue(chimed.isEmpty)
    }

    /// **The cooldown must run from when a held burst PLAYED, not from when it was asked for** —
    /// and the difference is exactly R-e's 0.45 s hold. Stamped at the request, a milestone 5.2 s
    /// later reads as out of the cooldown while the held celebration is still raining on screen.
    func testAMilestoneIsCooledDownFromWhenAHeldBurstPlayedNotFromWhenItWasAsked() {
        let clock = Clock(launch)
        let center = centre(at: clock)
        center.surfacePresented(.promoteSheet)
        center.request(.milestone(.inboxZero), at: nil)
        clock.advance(0.45)
        center.surfaceDismissed(.promoteSheet)
        clock.advance(CelebrationPolicy.milestoneCooldown - 0.25)
        XCTAssertEqual(
            center.request(.milestone(.dailyGoal), at: nil), .inPlace,
            "A second milestone played in full while the held one was still on screen: 5.2 s after"
                + " the request, but only 4.75 s after it started."
        )
    }

    /// **A burst that is WAITING still counts against the cooldown**, even though it has not
    /// stamped it. Without this, two milestones asked for while the sheet is up would both be
    /// promised a full screen and both be released at the same instant — two 5.4 s washes stacked,
    /// which is the opposite of what E's #6 cooldown is for.
    func testASecondMilestoneAskedForWhileOneIsHeldGetsThePopInstead() {
        let clock = Clock(launch)
        let center = centre(at: clock)
        center.surfacePresented(.promoteSheet)
        XCTAssertEqual(center.request(.milestone(.inboxZero), at: nil), .fullScreen)
        clock.advance(0.2)
        XCTAssertEqual(center.request(.milestone(.dailyGoal), at: nil), .inPlace)
        center.surfaceDismissed(.promoteSheet)
        XCTAssertEqual(
            center.bursts.filter(\.isFullScreen).count, 1,
            "Both milestones were released as full-screen celebrations at one instant."
        )
    }

    /// A cover that does NOT dismiss itself draws on its own layer — that is the point of E's
    /// per-surface choice, and holding there would mean the routine screen never celebrated.
    func testAFullScreenOnASurfaceThatStaysOpenIsNotHeld() {
        let center = centre(at: Clock(launch))
        center.surfacePresented(.routineCover)
        center.request(.milestone(.routineFinished), at: nil)
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertEqual(center.bursts[0].surface, .routineCover)
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
