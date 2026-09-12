//
//  CelebrationQueueTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-3`: the live bursts, generalised from `ConfirmCelebrationQueue` (now
//  `ConfirmCelebrationClock`, which holds only the Confirm's numbers) to every kind of celebration.
//
//  Two families share one list and they must not share a cap: eight pops in the air are normal
//  (E's F6 puts one on every task close), while a fourth full-screen celebration must drop the
//  oldest — the Confirm record's R1, which E approved and which is unchanged here.
//

import XCTest
@testable import ADHD_LifeOS

final class CelebrationQueueTests: XCTestCase {

    private let launch = Date(timeIntervalSince1970: 1_800_000_000)

    private func burst(
        _ ordinal: Int, _ kind: CelebrationKind, surface: CelebrationSurface = .root, at start: Date? = nil
    ) -> CelebrationBurst {
        CelebrationBurst(
            ordinal: ordinal, kind: kind, surface: surface, start: start ?? launch, origin: nil
        )
    }

    // MARK: - How long each kind is on screen

    func testAPopIsOnScreenForOneSecond() {
        XCTAssertEqual(CelebrationQueue.length(of: burst(1, .pop)), 1.0, accuracy: 0.0001)
    }

    /// E's F8: the four milestones are "the every-Confirm size" — the same 5.4 s celebration, not
    /// a length of their own.
    func testAMilestoneIsOnScreenForExactlyTheEveryConfirmLength() {
        XCTAssertEqual(
            CelebrationQueue.length(of: burst(1, .milestone(.inboxZero))),
            ConfirmCelebrationClock.everyConfirmLength,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            CelebrationQueue.length(of: burst(2, .confirm(clearedStack: false))),
            ConfirmCelebrationClock.everyConfirmLength,
            accuracy: 0.0001
        )
    }

    /// E's decision 1 for block 2, "Same stretch": the fireworks play at the confetti's pace, so a
    /// stack-clearing Confirm is on screen for 5.0 / pace ≈ 6.43 s.
    func testAStackClearingConfirmKeepsItsStretchedFireworksLength() {
        XCTAssertEqual(
            CelebrationQueue.length(of: burst(1, .confirm(clearedStack: true))),
            ConfirmCelebrationClock.stackClearingLength,
            accuracy: 0.0001
        )
        XCTAssertGreaterThan(
            CelebrationQueue.length(of: burst(1, .confirm(clearedStack: true))),
            CelebrationQueue.length(of: burst(2, .confirm(clearedStack: false)))
        )
    }

    // MARK: - Two clocks

    /// The full-screen choreography is STRETCHED (E's +1.2 s), so its drawing time runs slower than
    /// the wall clock. A pop has no stretch to inherit: it is a one-second flourish, and running it
    /// at 78% would leave it hanging.
    func testPopsRunOnRawSecondsWhileFullScreensRunOnTheStretchedClock() {
        let moment = launch.addingTimeInterval(1)
        XCTAssertEqual(
            CelebrationQueue.choreographyTime(of: burst(1, .pop), at: moment), 1.0, accuracy: 0.0001
        )
        XCTAssertEqual(
            CelebrationQueue.choreographyTime(of: burst(2, .confirm(clearedStack: false)), at: moment),
            ConfirmCelebrationClock.pace,
            accuracy: 0.0001,
            "A full-screen burst is no longer placed on the stretched clock, so E's approved"
                + " choreography plays at the wrong speed."
        )
    }

    // MARK: - The two caps

    func testAFourthLiveFullScreenDropsTheOldest() {
        var live: [CelebrationBurst] = []
        for ordinal in 1...4 {
            live = CelebrationQueue.adding(
                burst(ordinal, .milestone(.inboxZero)), to: live, now: launch
            )
        }
        XCTAssertEqual(live.count, CelebrationQueue.fullScreenCap)
        XCTAssertEqual(live.map(\.ordinal), [2, 3, 4])
    }

    /// The caps are per FAMILY. Eight pops in the air must not evict a Confirm, and a Confirm must
    /// not evict the pops that fired beside it.
    func testTheCapsAreCountedPerFamilySoPopsNeverEvictAFullScreen() {
        var live = CelebrationQueue.adding(burst(1, .confirm(clearedStack: false)), to: [], now: launch)
        for ordinal in 2...10 {
            live = CelebrationQueue.adding(burst(ordinal, .pop), to: live, now: launch)
        }
        XCTAssertEqual(
            live.filter(\.isFullScreen).map(\.ordinal), [1],
            "Nine pops evicted the Confirm celebration they fired beside."
        )
        XCTAssertEqual(live.filter { !$0.isFullScreen }.count, CelebrationQueue.popCap)
        XCTAssertEqual(live.filter { !$0.isFullScreen }.map(\.ordinal), Array(3...10))
    }

    // MARK: - Expiry

    func testAFinishedBurstIsPrunedAndTheNextExpiryIsTheSoonest() {
        let pop = burst(1, .pop)
        let milestone = burst(2, .milestone(.dailyGoal))
        let live = [pop, milestone]
        XCTAssertEqual(
            CelebrationQueue.nextExpiry(of: live),
            launch.addingTimeInterval(CelebrationQueue.length(of: pop)),
            "The sweep waits for the LONGEST burst, so a finished pop keeps the frame clock running."
        )
        let afterThePop = launch.addingTimeInterval(CelebrationQueue.length(of: pop) + 0.001)
        XCTAssertEqual(CelebrationQueue.pruned(live, now: afterThePop).map(\.ordinal), [2])
        let afterBoth = launch.addingTimeInterval(CelebrationQueue.length(of: milestone) + 0.001)
        XCTAssertTrue(CelebrationQueue.pruned(live, now: afterBoth).isEmpty)
        XCTAssertNil(CelebrationQueue.nextExpiry(of: []))
    }

    /// Adding prunes first, so a burst that ended while nothing was on screen never comes back to
    /// life beside the new one.
    func testAddingPrunesWhatHasAlreadyEnded() {
        let stale = burst(1, .pop)
        let live = CelebrationQueue.adding(
            burst(2, .pop), to: [stale], now: launch.addingTimeInterval(2)
        )
        XCTAssertEqual(live.map(\.ordinal), [2])
    }
}
