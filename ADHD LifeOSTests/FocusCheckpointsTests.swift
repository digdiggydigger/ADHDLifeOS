//
//  FocusCheckpointsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Ports the assertions the web's in-app "Automated 30s Test Suite" made about checkpoint
/// cadence (`calculateNudgeCheckpoints` / `calculateIntervalNudgeCheckpoints`) into real unit
/// tests — including its headline case: a 30s sprint with 1 nudge fires at exactly 15s.
final class FocusCheckpointsTests: XCTestCase {
    func testThirtySecondSprintWithOneNudge_firesAtFifteenSeconds() {
        XCTAssertEqual(FocusCheckpoints.evenlySpaced(durationSeconds: 30, count: 1), [15])
    }

    func testEvenlySpaced_dividesIntoEqualSegments() {
        XCTAssertEqual(FocusCheckpoints.evenlySpaced(durationSeconds: 60, count: 2), [20, 40])
        XCTAssertEqual(FocusCheckpoints.evenlySpaced(durationSeconds: 900, count: 3), [225, 450, 675])
    }

    func testEvenlySpaced_zeroOrNegativeCount_isEmpty() {
        XCTAssertTrue(FocusCheckpoints.evenlySpaced(durationSeconds: 900, count: 0).isEmpty)
        XCTAssertTrue(FocusCheckpoints.evenlySpaced(durationSeconds: 900, count: -3).isEmpty)
    }

    func testEvenlySpaced_belowMinimumDuration_isEmpty() {
        XCTAssertTrue(FocusCheckpoints.evenlySpaced(durationSeconds: 9, count: 2).isEmpty)
    }

    func testEvenlySpaced_neverIncludesBoundaries() {
        let checkpoints = FocusCheckpoints.evenlySpaced(durationSeconds: 100, count: 5)
        XCTAssertFalse(checkpoints.contains(0))
        XCTAssertFalse(checkpoints.contains(100))
    }

    func testEvenlySpaced_deduplicatesCollidingRoundedPoints() {
        // Many checkpoints in a short window round onto the same second; each must appear once.
        let checkpoints = FocusCheckpoints.evenlySpaced(durationSeconds: 12, count: 11)
        XCTAssertEqual(checkpoints.count, Set(checkpoints).count)
    }

    func testInterval_spacesEveryNSecondsExcludingFinish() {
        XCTAssertEqual(FocusCheckpoints.interval(durationSeconds: 300, intervalSeconds: 60), [60, 120, 180, 240])
    }

    func testInterval_clampsToThirtySecondFloor() {
        XCTAssertEqual(FocusCheckpoints.interval(durationSeconds: 120, intervalSeconds: 10), [30, 60, 90])
    }

    func testInterval_intervalLongerThanSession_isEmpty() {
        XCTAssertTrue(FocusCheckpoints.interval(durationSeconds: 60, intervalSeconds: 300).isEmpty)
    }

    func testStandardCadence_matchesWebRule() {
        XCTAssertEqual(FocusNudgeCadence.standard(forDurationSeconds: 60), .count(1))
        XCTAssertEqual(FocusNudgeCadence.standard(forDurationSeconds: 61), .count(2))
    }

    func testDigitalTimeFormatting() {
        XCTAssertEqual(FocusTimeFormatting.digital(0), "00:00")
        XCTAssertEqual(FocusTimeFormatting.digital(9), "00:09")
        XCTAssertEqual(FocusTimeFormatting.digital(75), "01:15")
        XCTAssertEqual(FocusTimeFormatting.digital(900), "15:00")
        XCTAssertEqual(FocusTimeFormatting.digital(-5), "00:00", "negative remaining clamps to zero")
    }

    // MARK: - FocusSession pure behaviour

    private func session(duration: Int, checkpoints: [Int]) -> FocusSession {
        FocusSession(
            taskId: UUID(), taskTitle: "Write tests", lifeAreaEmoji: "💼",
            durationSeconds: duration, nudgeCheckpoints: checkpoints
        )
    }

    func testProgressAndElapsed() {
        var sut = session(duration: 100, checkpoints: [])
        XCTAssertEqual(sut.progress, 0)
        _ = sut.advance(toRemaining: 25)
        XCTAssertEqual(sut.elapsedSeconds, 75)
        XCTAssertEqual(sut.progress, 0.75, accuracy: 0.0001)
    }

    func testAdvance_reportsCrossedCheckpointsOnceEach() {
        var sut = session(duration: 100, checkpoints: [25, 50, 75])

        XCTAssertEqual(sut.advance(toRemaining: 74), [0], "crossing 25s elapsed fires checkpoint 0")
        XCTAssertEqual(sut.advance(toRemaining: 74), [], "re-advancing to the same point fires nothing")
        XCTAssertEqual(sut.advance(toRemaining: 20), [1, 2], "a big jump fires every checkpoint it passed")
        XCTAssertEqual(sut.triggeredCheckpointIndices, [0, 1, 2])
    }

    func testNextCheckpoint_tracksSoonestUntriggered() {
        var sut = session(duration: 100, checkpoints: [25, 50])
        XCTAssertEqual(sut.nextCheckpoint?.index, 0)
        XCTAssertEqual(sut.secondsUntilNextCheckpoint, 25)

        _ = sut.advance(toRemaining: 70)
        XCTAssertEqual(sut.nextCheckpoint?.index, 1)
        XCTAssertEqual(sut.secondsUntilNextCheckpoint, 20)

        _ = sut.advance(toRemaining: 10)
        XCTAssertNil(sut.nextCheckpoint, "no checkpoints remain once all have fired")
    }

    func testAdvance_clampsWithinBounds() {
        var sut = session(duration: 60, checkpoints: [])
        _ = sut.advance(toRemaining: -20)
        XCTAssertEqual(sut.remainingSeconds, 0)
        XCTAssertTrue(sut.isComplete)

        _ = sut.advance(toRemaining: 999)
        XCTAssertEqual(sut.remainingSeconds, 60)
    }

    func testCheckpointPrompt_variesByPosition() {
        XCTAssertTrue(FocusSession.checkpointPrompt(index: 0, total: 1).contains("Midpoint"))
        XCTAssertTrue(FocusSession.checkpointPrompt(index: 0, total: 3).contains("Flow calibration"))
        XCTAssertTrue(FocusSession.checkpointPrompt(index: 2, total: 3).contains("Final cadence"))
        XCTAssertTrue(FocusSession.checkpointPrompt(index: 1, total: 3).contains("Checkpoint 2"))
    }
}
