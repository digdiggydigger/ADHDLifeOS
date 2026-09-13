//
//  CelebrationUnknownSheetHoldTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-Surfaces`: **a full-screen celebration asked for while a sheet the centre was
//  never told about is up.**
//
//  Four surfaces call `surfacePresented`. The tree holds **26** `.sheet` / `.fullScreenCover` call
//  sites, so everything else — Quick Capture above all, plus Settings, Add Task, the Journal
//  composer, the focus sprint detail, add nudge and the Life Area / Place / Tag editors — leaves
//  `frontmost` reading `.root`. A milestone requested then was drawn on the ROOT layer, under the
//  sheet: invisible, while still marking the day (`CelebrationDayMarking`), firing R-d's haptic and
//  posting the daily-goal announcement. E's call, 2026-09-13: hold it.
//
//  **The queueing was never the work.** `held` and `dismissesItself` have carried the promote
//  sheet since `F-CTACelebrations-5` and are unchanged here; R-g's 60 s drop is unchanged too.
//  What this block adds is DETECTION — and the release, because an untracked sheet tells the app
//  nothing when it closes, so nothing calls `surfaceDismissed` and the centre has to look.
//
//  `NothingPresentedProbe` is the default here on purpose: a test that means "a sheet is up" has to
//  say so.
//

import CoreGraphics
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CelebrationUnknownSheetHoldTests: XCTestCase {

    private let launch = Date(timeIntervalSince1970: 1_800_000_000)

    /// A probe a test can flip, standing in for "a sheet went up" and "it closed".
    private final class StubProbe: PresentationProbing {
        var isAnythingPresented: Bool
        init(_ presented: Bool) { self.isAnythingPresented = presented }
    }

    private final class Clock {
        var now: Date
        init(_ now: Date) { self.now = now }
        func advance(_ seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
    }

    /// `nil` rather than a default `NothingPresentedProbe()`: a default argument is evaluated in a
    /// nonisolated context, and the app target's default isolation is `MainActor`, so building one
    /// there warns (an error in Swift 6). Built in the body instead, where the isolation is this
    /// test class's.
    private func centre(
        at clock: Clock,
        probe: PresentationProbing? = nil,
        chime: @escaping (CelebrationKind) -> Void = { _ in },
        feel: @escaping (HapticFeel) -> Void = { _ in }
    ) -> CelebrationCenter {
        CelebrationCenter(
            now: { clock.now },
            celebrationsGate: { true },
            chime: chime,
            feel: feel,
            probe: probe ?? NothingPresentedProbe(),
            // Instant, so awaiting the watch runs the loop rather than the clock.
            sleep: { _ in await Task.yield() }
        )
    }

    // MARK: - The hold

    /// The whole block in one assertion: nothing told the centre a sheet was up, and it held anyway.
    func testAMilestoneRequestedBehindAnUnknownSheetIsHeldRatherThanDrawnUnderIt() {
        let center = centre(at: Clock(launch), probe: StubProbe(true))
        XCTAssertEqual(center.request(.milestone(.inboxZero), at: nil), .fullScreen)
        XCTAssertTrue(
            center.bursts.isEmpty,
            "Drawn on the root layer, which is underneath the sheet — the defect this block closes."
        )
        XCTAssertEqual(center.held.count, 1)
    }

    /// The other half, and the one that fails if the probe is simply wired to `true`.
    func testAMilestoneRequestedWithNothingPresentedIsDrawnAtOnce() {
        let center = centre(at: Clock(launch), probe: StubProbe(false))
        XCTAssertEqual(center.request(.milestone(.inboxZero), at: nil), .fullScreen)
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertEqual(center.bursts[0].surface, .root)
        XCTAssertTrue(center.held.isEmpty)
    }

    /// **E's call, 2026-09-13, asked alongside the main one.** A pop is a one-second flourish tied
    /// to the point that was tapped; holding it and replaying it seconds later at a stale
    /// coordinate would be wrong, and dropping it changes nothing anyone can see. So the hold stays
    /// full-screen-only, exactly as it is for the promote sheet.
    func testAPopRequestedBehindAnUnknownSheetIsStillDrawnRatherThanHeld() {
        let center = centre(at: Clock(launch), probe: StubProbe(true))
        XCTAssertEqual(center.request(.pop, at: CGPoint(x: 10, y: 20)), .inPlace)
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertTrue(center.held.isEmpty)
    }

    /// **The probe is not consulted on a surface that draws its own layer**, which is the simple
    /// form E chose over reconciling probe DEPTH against the centre's tracked count. The routine
    /// cover IS a presented controller, so a probe read there would report `true` and hold a
    /// celebration the cover was about to draw perfectly well.
    func testASurfaceWithItsOwnLayerDrawsWithoutConsultingTheProbe() {
        let center = centre(at: Clock(launch), probe: StubProbe(true))
        center.surfacePresented(.routineCover)
        center.request(.milestone(.routineFinished), at: nil)
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertEqual(center.bursts[0].surface, .routineCover)
        XCTAssertTrue(center.held.isEmpty)
    }

    /// R-d fires at REQUEST time, not when the burst plays — the daily goal is the one milestone
    /// with no site of its own to buzz. Being held must not change that.
    func testTheDailyGoalHapticStillFiresAtRequestTimeBehindAnUnknownSheet() {
        var felt: [HapticFeel] = []
        let center = centre(at: Clock(launch), probe: StubProbe(true), feel: { felt.append($0) })
        center.request(.milestone(.dailyGoal), at: nil)
        XCTAssertEqual(felt, [.success])
        XCTAssertTrue(center.bursts.isEmpty)
    }

    /// F5's chime belongs to the celebration, not the request. Unchanged from the promote sheet's
    /// case, and it has to hold for this path too or the sheet gets a sound with nothing behind it.
    func testAMilestoneHeldBehindAnUnknownSheetDoesNotChimeUntilItPlays() {
        let clock = Clock(launch)
        var chimed: [CelebrationKind] = []
        let probe = StubProbe(true)
        let center = centre(at: clock, probe: probe, chime: { chimed.append($0) })
        center.request(.milestone(.inboxZero), at: nil)
        XCTAssertTrue(chimed.isEmpty)
        probe.isAnythingPresented = false
        clock.advance(0.4)
        center.pollHeldBursts()
        XCTAssertEqual(chimed, [.milestone(.inboxZero)])
    }

    // MARK: - The release

    /// Nothing calls `surfaceDismissed` for a sheet the centre was never told about, so the centre
    /// has to look for itself. One tick of the watch is the whole rule.
    func testAHeldMilestoneIsReleasedOnceTheUnknownSheetHasGone() {
        let clock = Clock(launch)
        let probe = StubProbe(true)
        let center = centre(at: clock, probe: probe)
        center.request(.milestone(.inboxZero), at: nil)
        clock.advance(0.4)
        center.pollHeldBursts()
        XCTAssertTrue(center.bursts.isEmpty, "Released while the sheet was still up.")

        probe.isAnythingPresented = false
        clock.advance(0.2)
        center.pollHeldBursts()
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertEqual(center.bursts[0].surface, .root)
        XCTAssertEqual(
            center.bursts[0].start, launch.addingTimeInterval(0.6),
            "A released burst starts NOW, or half of it has elapsed before anything is drawn."
        )
        XCTAssertTrue(center.held.isEmpty)
    }

    /// The loop around the tick, not just the tick: the watch starts itself on a hold and runs
    /// until there is nothing left to release.
    func testTheHoldWatchReleasesTheBurstWithNoSurfaceDismissalAtAll() async {
        let probe = StubProbe(true)
        let center = centre(at: Clock(launch), probe: probe)
        center.request(.milestone(.inboxZero), at: nil)
        XCTAssertNotNil(center.holdWatch, "Nothing was watching, so nothing would ever release it.")
        probe.isAnythingPresented = false
        await center.holdWatch?.value
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertNil(center.holdWatch, "The watch outlived the burst it was waiting for.")
    }

    /// With nothing held there is nothing to poll, and a watch that ran anyway would poll forever.
    func testNoWatchRunsWhenNothingIsHeld() {
        let center = centre(at: Clock(launch), probe: StubProbe(false))
        center.request(.milestone(.inboxZero), at: nil)
        XCTAssertNil(center.holdWatch)
    }

    /// **R-g, and the poll gives it teeth it did not have.** It used to be enforced only by the next
    /// `surfaceDismissed`, so a burst behind a sheet nobody tracked would have waited indefinitely.
    func testAHeldBurstBehindASheetThatStaysUpIsDroppedAtSixtySeconds() {
        let clock = Clock(launch)
        var chimed: [CelebrationKind] = []
        let center = centre(at: clock, probe: StubProbe(true), chime: { chimed.append($0) })
        center.request(.milestone(.inboxZero), at: nil)
        clock.advance(CelebrationCenter.heldLifetime + 0.01)
        center.pollHeldBursts()
        XCTAssertTrue(center.held.isEmpty, "R-g never dropped it, so it waits for a sheet forever.")
        XCTAssertTrue(center.bursts.isEmpty)
        XCTAssertTrue(chimed.isEmpty, "It never appeared, so it must leave nothing behind it.")
        XCTAssertNil(center.holdWatch, "The watch is still polling for a burst that no longer exists.")
    }

    /// The hole the probe closes on the OTHER side: a tracked surface closing while an untracked
    /// one is still up would otherwise release the burst under it — the same invisibility, one
    /// layer along.
    func testATrackedSurfaceClosingDoesNotReleaseABurstWhileAnotherSheetIsStillUp() {
        let clock = Clock(launch)
        let probe = StubProbe(true)
        let center = centre(at: clock, probe: probe)
        center.surfacePresented(.promoteSheet)
        center.request(.milestone(.inboxZero), at: nil)
        clock.advance(0.3)
        center.surfaceDismissed(.promoteSheet)
        XCTAssertTrue(center.bursts.isEmpty, "Released under the sheet that was still up.")
        XCTAssertEqual(center.held.count, 1)

        probe.isAnythingPresented = false
        center.pollHeldBursts()
        XCTAssertEqual(center.bursts.count, 1)
    }
}
