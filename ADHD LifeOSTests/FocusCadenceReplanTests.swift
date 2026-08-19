//
//  FocusCadenceReplanTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Locks the mid-sprint re-planning rule the live cadence editor needs: **the past is immutable,
/// the future is re-spaced**. Checkpoints the sprint already crossed keep their marks and stay
/// counted; every un-fired checkpoint is discarded and replaced by the new cadence's marks that
/// are still ahead of the playhead.
final class FocusCadenceReplanTests: XCTestCase {
    // MARK: - FocusCheckpoints.replanned

    func testReplan_keepsTriggeredMarksAndRespacesEverythingAhead() {
        let result = FocusCheckpoints.replanned(
            existing: [25, 50, 75], triggeredIndices: [0],
            proposed: [20, 40, 60, 80], elapsedSeconds: 30
        )

        XCTAssertEqual(result.checkpoints, [25, 40, 60, 80])
        XCTAssertEqual(result.triggeredIndices, [0])
    }

    func testReplan_dropsProposedMarksAlreadyBehindThePlayhead() {
        let result = FocusCheckpoints.replanned(
            existing: [], triggeredIndices: [], proposed: [10, 20, 30, 40], elapsedSeconds: 25
        )

        XCTAssertEqual(result.checkpoints, [30, 40], "a mark in the past can never fire")
        XCTAssertTrue(result.triggeredIndices.isEmpty)
    }

    func testReplan_discardsUntriggeredMarksFromTheOldCadence() {
        let result = FocusCheckpoints.replanned(
            existing: [25, 50, 75], triggeredIndices: [], proposed: [60], elapsedSeconds: 0
        )

        XCTAssertEqual(result.checkpoints, [60], "nothing had fired, so nothing is preserved")
    }

    func testReplan_onAFreshSprintMatchesThePlainCadence() {
        let proposed = FocusCheckpoints.evenlySpaced(durationSeconds: 900, count: 3)

        let result = FocusCheckpoints.replanned(
            existing: [450], triggeredIndices: [], proposed: proposed, elapsedSeconds: 0
        )

        XCTAssertEqual(result.checkpoints, proposed)
        XCTAssertTrue(result.triggeredIndices.isEmpty)
    }

    func testReplan_withNoProposedMarksKeepsOnlyTheFiredHistory() {
        let result = FocusCheckpoints.replanned(
            existing: [25, 50, 75], triggeredIndices: [0, 1], proposed: [], elapsedSeconds: 60
        )

        XCTAssertEqual(result.checkpoints, [25, 50], "turning nudges off can't un-fire the ones already heard")
        XCTAssertEqual(result.triggeredIndices, [0, 1])
    }

    func testReplan_triggeredIndicesAlwaysFormTheLeadingPrefix() {
        // Kept marks are all behind the playhead and new marks all ahead of it, so after sorting
        // the fired ones are always indices 0..<keptCount — the invariant the timeline relies on
        // to colour pins without re-deriving which mark fired.
        let result = FocusCheckpoints.replanned(
            existing: [10, 20, 30], triggeredIndices: [0, 1], proposed: [5, 26, 50, 70],
            elapsedSeconds: 25
        )

        XCTAssertEqual(result.checkpoints, [10, 20, 26, 50, 70])
        XCTAssertEqual(result.triggeredIndices, [0, 1])
    }

    func testReplan_producesStrictlyIncreasingUniqueMarks() {
        let result = FocusCheckpoints.replanned(
            existing: [30, 60, 90], triggeredIndices: [0, 1], proposed: [30, 60, 90, 120],
            elapsedSeconds: 65
        )

        XCTAssertEqual(result.checkpoints, [30, 60, 90, 120])
        XCTAssertEqual(result.checkpoints, result.checkpoints.sorted())
        XCTAssertEqual(result.checkpoints.count, Set(result.checkpoints).count)
    }

    // MARK: - FocusSession.replanCheckpoints

    private func session(duration: Int, checkpoints: [Int]) -> FocusSession {
        FocusSession(
            taskId: UUID(), taskTitle: "Draft the review", lifeAreaEmoji: "💼",
            durationSeconds: duration, nudgeCheckpoints: checkpoints
        )
    }

    func testSessionReplan_appliesTheNewCadenceAheadOfThePlayhead() {
        var sut = session(duration: 900, checkpoints: [225, 450, 675])
        _ = sut.advance(toRemaining: 600)  // 300s elapsed: checkpoint 0 has fired

        sut.replanCheckpoints(to: .interval(seconds: 120))

        XCTAssertEqual(sut.nudgeCheckpoints, [225, 360, 480, 600, 720, 840])
        XCTAssertEqual(sut.triggeredCheckpointIndices, [0])
        XCTAssertEqual(sut.nextCheckpoint?.atSeconds, 360)
    }

    func testSessionReplan_neverRefiresAKeptCheckpoint() {
        var sut = session(duration: 600, checkpoints: [200, 400])
        _ = sut.advance(toRemaining: 350)  // 250s elapsed: checkpoint 0 fired

        sut.replanCheckpoints(to: .count(4))

        XCTAssertEqual(
            sut.advance(toRemaining: 350), [],
            "re-planning must not make an already-heard checkpoint fire a second time"
        )
        XCTAssertEqual(sut.triggeredCheckpointIndices.count, 1)
    }

    func testSessionReplan_keepsTheReachedCountStableForTheActivityMirror() {
        var sut = session(duration: 600, checkpoints: [150, 300, 450])
        _ = sut.advance(toRemaining: 280)  // 320s elapsed: checkpoints 0 and 1 fired

        let reachedBefore = sut.triggeredCheckpointIndices.count
        sut.replanCheckpoints(to: .count(1))

        XCTAssertEqual(sut.triggeredCheckpointIndices.count, reachedBefore)
        XCTAssertEqual(sut.nudgeCheckpoints, [150, 300], "the count cadence's only mark (300s) is behind the playhead")
    }
}
