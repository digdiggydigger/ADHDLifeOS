//
//  CelebrationCenterHeldBurstTests.swift
//  ADHD LifeOSTests
//
//  Split out of `CelebrationCenterTests` when that class crossed SwiftLint's `type_body_length`
//  ceiling — the `CaptureInboxTriageServiceTests` precedent.
//
//  **Everything here is about a celebration that is asked for but cannot be drawn yet**, which is
//  the Create Task sheet's case and the one `F-CTACelebrations-5` made reachable: the sheet closes
//  ITSELF after a successful promote, so a 5.4 s celebration on its layer would be cut off after a
//  fraction of a second. It is held, and released over whatever is behind it — and until this block
//  it left a cooldown and a chime behind at the moment it was ASKED for rather than the moment it
//  played (register §B.00b).
//

import CoreGraphics
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CelebrationCenterHeldBurstTests: XCTestCase {

    private let launch = Date(timeIntervalSince1970: 1_800_000_000)

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

    /// **And it must hold for as long as the burst WAITS, not merely for the cooldown's length.**
    /// A held burst's `start` is its REQUEST time, so an anchor that simply reports it lets the
    /// cooldown "expire" while the burst is still sitting there unplayed — and `releaseHeld` then
    /// starts both at one instant, which is the stacking this exists to prevent. `heldLifetime` is
    /// 60 s, twelve times the cooldown, so the window is not a corner.
    ///
    /// Found by the `feature-dev:code-reviewer` pass over this block's own fix.
    func testASecondMilestoneIsStillRefusedAfterTheCooldownHasElapsedWhileOneWaits() {
        let clock = Clock(launch)
        let center = centre(at: clock)
        center.surfacePresented(.promoteSheet)
        XCTAssertEqual(center.request(.milestone(.inboxZero), at: nil), .fullScreen)
        clock.advance(CelebrationPolicy.milestoneCooldown + 1)
        XCTAssertEqual(
            center.request(.milestone(.dailyGoal), at: nil), .inPlace,
            "The first burst has not played yet — it is still waiting behind the sheet — so the"
                + " cooldown cannot have expired."
        )
        center.surfaceDismissed(.promoteSheet)
        XCTAssertEqual(center.bursts.filter(\.isFullScreen).count, 1)
    }
}
