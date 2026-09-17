//
//  CelebrationCaptureFanHoldTests.swift
//  ADHD LifeOSTests
//
//  `F-FanHoldsCelebration`: **a full-screen celebration asked for while the capture fan is open
//  waits until it closes.**
//
//  `F-CTACelebrations-Surfaces` holds a full-screen celebration while `CelebrationCenter.isBlocked`
//  — tracked surfaces that close themselves, and anything UIKit reports as presented. The fan is
//  neither: it is a SwiftUI overlay in `RootView`, gated on `@State isFabOpen`, so no probe can see
//  it and nothing told the centre. `RootView` tells it now (`captureChanged(isOpen:)`).
//
//  **What E chose, and what E did not (2026-09-17).** The evidence behind the block, frame 20
//  (`IMG_8521`), turned out to be E's OWN Confirm, still playing when E opened the fan — not a
//  request made while the fan was open. Walked through today's behaviour, a replay, and holding new
//  requests only, **E chose "Only hold new requests"**: a celebration ALREADY playing when the fan
//  opens keeps playing over it, exactly as in that frame. And R-g's sixty seconds apply behind the
//  fan as they do behind a sheet (E: "Same 60s rule"). Pops are not held, as `-Surfaces` settled.
//

import CoreGraphics
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CelebrationCaptureFanHoldTests: XCTestCase {

    private let launch = Date(timeIntervalSince1970: 1_800_000_000)

    private final class StubProbe: PresentationProbing {
        var isAnythingPresented: Bool
        init(_ presented: Bool) { self.isAnythingPresented = presented }
    }

    private final class Clock {
        var now: Date
        init(_ now: Date) { self.now = now }
        func advance(_ seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
    }

    /// `nil` rather than a default probe, for the isolation reason `CelebrationUnknownSheetHoldTests`
    /// records. With nothing presented by default, a hold here can only be the FAN's.
    private func centre(
        at clock: Clock,
        probe: PresentationProbing? = nil,
        chime: @escaping (CelebrationKind) -> Void = { _ in }
    ) -> CelebrationCenter {
        CelebrationCenter(
            now: { clock.now },
            celebrationsGate: { true },
            chime: chime,
            feel: { _ in },
            probe: probe ?? NothingPresentedProbe(),
            sleep: { _ in await Task.yield() }
        )
    }

    // MARK: - The hold

    /// The block in one assertion, for both full-screen kinds: the fan is open, so the celebration
    /// waits rather than playing over the tiles.
    func testAFullScreenCelebrationAskedForWhileTheFanIsOpenIsHeld() {
        for kind: CelebrationKind in [.milestone(.dailyGoal), .confirm(clearedStack: true)] {
            let center = centre(at: Clock(launch))
            center.captureChanged(isOpen: true)
            XCTAssertEqual(center.request(kind, at: nil), .fullScreen)
            XCTAssertTrue(center.bursts.isEmpty, "\(kind) played over the open fan.")
            XCTAssertEqual(center.held.count, 1, "\(kind) was not held behind the fan.")
        }
    }

    /// The control, and the one that fails if the fan flag is simply wired to `true`.
    func testWithTheFanClosedTheSameCelebrationPlaysAtOnce() {
        let center = centre(at: Clock(launch))
        center.captureChanged(isOpen: false)
        center.request(.milestone(.dailyGoal), at: nil)
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertTrue(center.held.isEmpty)
    }

    /// A pop is a one-second flourish tied to the point that was tapped. `-Surfaces` chose not to
    /// hold one behind a sheet, and the same reasoning holds behind the fan.
    func testAPopWhileTheFanIsOpenIsNotHeld() {
        let center = centre(at: Clock(launch))
        center.captureChanged(isOpen: true)
        XCTAssertEqual(center.request(.pop, at: CGPoint(x: 10, y: 20)), .inPlace)
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertTrue(center.held.isEmpty)
    }

    // MARK: - The release

    /// Closing the fan plays it straight away — the fan's own close, not the next poll — and it
    /// starts NOW, with its chime, rather than from the moment it was asked for.
    func testClosingTheFanPlaysTheHeldCelebrationFromTheStart() {
        let clock = Clock(launch)
        var chimed: [CelebrationKind] = []
        let center = centre(at: clock, chime: { chimed.append($0) })
        center.captureChanged(isOpen: true)
        center.request(.milestone(.dailyGoal), at: nil)
        XCTAssertTrue(chimed.isEmpty, "It chimed with nothing on screen to explain the sound.")

        clock.advance(4)
        center.captureChanged(isOpen: false)
        XCTAssertEqual(center.bursts.count, 1, "Closing the fan did not release it.")
        XCTAssertEqual(center.bursts.first?.start, launch.addingTimeInterval(4))
        XCTAssertEqual(chimed, [.milestone(.dailyGoal)])
        XCTAssertTrue(center.held.isEmpty)
        XCTAssertNil(center.holdWatch, "The watch outlived the burst it was waiting for.")
    }

    /// The hold watch, not only the close: when the fan closes while something ELSE still blocks
    /// (the composer a tile opened), the watch is what plays it once that clears.
    func testTheHoldWatchReleasesItWhenTheFanClosedWhileSomethingElseStillBlocked() async {
        let probe = StubProbe(false)
        let center = centre(at: Clock(launch), probe: probe)
        center.captureChanged(isOpen: true)
        center.request(.milestone(.dailyGoal), at: nil)
        XCTAssertNotNil(center.holdWatch, "Nothing was watching, so nothing would ever release it.")
        probe.isAnythingPresented = true
        center.captureChanged(isOpen: false)
        XCTAssertTrue(center.bursts.isEmpty)
        probe.isAnythingPresented = false
        await center.holdWatch?.value
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertNil(center.holdWatch)
    }

    /// Opening and closing the fan with nothing held plays nothing and leaves no watch running.
    func testOpeningAndClosingTheFanWithNothingHeldPlaysNothing() {
        let center = centre(at: Clock(launch))
        center.captureChanged(isOpen: true)
        center.captureChanged(isOpen: false)
        XCTAssertTrue(center.bursts.isEmpty)
        XCTAssertTrue(center.held.isEmpty)
        XCTAssertNil(center.holdWatch)
    }

    /// **Picking a tile.** `RootView` closes the fan and opens the composer in one update, and
    /// UIKit presents the composer a run loop or two later. It reports the capture as open until
    /// the composer is gone, so the flag never drops in that gap — and if it did, the probe would
    /// still hold the celebration once the composer is up. This is that second half.
    func testAFanClosingIntoAComposerKeepsTheCelebrationHeldUntilTheComposerGoes() {
        let clock = Clock(launch)
        let probe = StubProbe(false)
        let center = centre(at: clock, probe: probe)
        center.captureChanged(isOpen: true)
        center.request(.milestone(.inboxZero), at: nil)

        probe.isAnythingPresented = true
        center.captureChanged(isOpen: false)
        XCTAssertTrue(center.bursts.isEmpty, "Released under the composer the fan opened.")

        probe.isAnythingPresented = false
        clock.advance(0.3)
        center.pollHeldBursts()
        XCTAssertEqual(center.bursts.count, 1)
    }

    // MARK: - What E chose NOT to change

    /// **E's call, 2026-09-17: "Only hold new requests".** A celebration already playing when the
    /// fan opens keeps playing over it — `IMG_8521` is E's own Confirm doing exactly this, and E
    /// chose to leave it. Opening the fan must not cut, hold or replay it.
    func testACelebrationAlreadyPlayingWhenTheFanOpensKeepsPlaying() {
        let clock = Clock(launch)
        var chimed: [CelebrationKind] = []
        let center = centre(at: clock, chime: { chimed.append($0) })
        center.request(.confirm(clearedStack: true), at: nil)
        let playing = center.bursts

        clock.advance(1)
        center.captureChanged(isOpen: true)
        XCTAssertEqual(center.bursts, playing, "Opening the fan cut the celebration that was already playing.")
        XCTAssertTrue(center.held.isEmpty, "Opening the fan held a celebration that had already started.")

        center.captureChanged(isOpen: false)
        XCTAssertEqual(center.bursts, playing, "Closing the fan replayed it.")
        XCTAssertEqual(chimed.count, 1, "It chimed twice.")
    }

    /// **R-g behind the fan (E: "Same 60s rule").** A fan left open past sixty seconds drops the
    /// celebration rather than firing it late, and leaves nothing behind.
    func testACelebrationHeldBehindAFanLeftOpenPastSixtySecondsIsDropped() {
        let clock = Clock(launch)
        var chimed: [CelebrationKind] = []
        let center = centre(at: clock, chime: { chimed.append($0) })
        center.captureChanged(isOpen: true)
        center.request(.milestone(.dailyGoal), at: nil)
        clock.advance(CelebrationCenter.heldLifetime + 0.01)
        center.captureChanged(isOpen: false)
        XCTAssertTrue(center.bursts.isEmpty, "A stale celebration fired sixty seconds late.")
        XCTAssertTrue(center.held.isEmpty)
        XCTAssertTrue(chimed.isEmpty)
        XCTAssertNil(center.holdWatch)
    }

    /// The fan only exists on the root surface. A tracked cover in front draws its own layer and is
    /// not held by a stale fan flag.
    func testAFanFlagDoesNotHoldACelebrationOnACoverWithItsOwnLayer() {
        let center = centre(at: Clock(launch))
        center.captureChanged(isOpen: true)
        center.surfacePresented(.routineCover)
        center.request(.milestone(.routineFinished), at: nil)
        XCTAssertEqual(center.bursts.count, 1)
        XCTAssertEqual(center.bursts.first?.surface, .routineCover)
    }
}
