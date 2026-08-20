//
//  FocusWidgetActiveSprintTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The running sprint, as the Home Screen widget sees it.
///
/// Everything here is deadline-derived rather than a countdown value, because the widget is
/// rendered by a different process minutes (or hours) after the app published the payload — and
/// very likely while the app is suspended and in no position to publish again.
final class FocusWidgetActiveSprintTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func sprint(
        durationSeconds: Int = 900,
        deadline: Date? = nil,
        pausedRemainingSeconds: Int? = nil,
        checkpointsReached: Int = 1,
        checkpointCount: Int = 3
    ) -> FocusWidgetSnapshot.ActiveSprint {
        FocusWidgetSnapshot.ActiveSprint(
            taskTitle: "Draft the review",
            emoji: "💼",
            durationSeconds: durationSeconds,
            deadline: deadline,
            pausedRemainingSeconds: pausedRemainingSeconds,
            checkpointsReached: checkpointsReached,
            checkpointCount: checkpointCount
        )
    }

    // MARK: - Running vs paused

    func testRunningSprint_isNotPausedAndSpansThePlannedDuration() {
        let running = sprint(durationSeconds: 900, deadline: now.addingTimeInterval(600))

        XCTAssertFalse(running.isPaused)
        XCTAssertEqual(
            running.timerInterval,
            now.addingTimeInterval(-300)...now.addingTimeInterval(600),
            "the visual start derives from the deadline, so extensions keep the fill truthful"
        )
    }

    func testPausedSprint_hasNoLiveDeadlineAndThereforeNoTimerInterval() {
        let paused = sprint(deadline: nil, pausedRemainingSeconds: 300)

        XCTAssertTrue(paused.isPaused)
        XCTAssertNil(paused.timerInterval, "there is nothing for the OS to count down to")
        XCTAssertEqual(paused.frozenRemainingText, "5:00")
    }

    func testFrozenRemainingText_matchesTheOSTimerFormatting() {
        // Unpadded minutes, padded seconds, hours rolled into minutes — the same rule the Live
        // Activity's paused frame follows, so the two surfaces never disagree about "1:05".
        XCTAssertEqual(sprint(pausedRemainingSeconds: 65).frozenRemainingText, "1:05")
        XCTAssertEqual(sprint(pausedRemainingSeconds: 3900).frozenRemainingText, "65:00")
        XCTAssertEqual(sprint(pausedRemainingSeconds: nil).frozenRemainingText, "0:00")
    }

    // MARK: - Elapsing

    func testHasElapsed_flipsAtTheDeadline() {
        let running = sprint(deadline: now.addingTimeInterval(600))

        XCTAssertFalse(running.hasElapsed(asOf: now.addingTimeInterval(599)))
        XCTAssertTrue(running.hasElapsed(asOf: now.addingTimeInterval(600)))
    }

    func testHasElapsed_whilePaused_isAlwaysFalse() {
        let paused = sprint(deadline: nil, pausedRemainingSeconds: 300)

        XCTAssertFalse(paused.hasElapsed(asOf: now.addingTimeInterval(86_400)))
    }

    // MARK: - Caption

    func testCheckpointSummary_readsNOfM() {
        XCTAssertEqual(sprint(checkpointsReached: 1, checkpointCount: 3).checkpointSummary, "1 of 3 checkpoints")
    }

    func testCheckpointSummary_withNoCheckpoints_isNil() {
        XCTAssertNil(sprint(checkpointsReached: 0, checkpointCount: 0).checkpointSummary)
    }

    // MARK: - Envelope

    func testSnapshotVersion_wasBumpedForTheNewField() {
        XCTAssertEqual(
            FocusWidgetSnapshot.currentVersion, 2,
            "an older app writing v1 must not be half-decoded by a widget expecting activeSprint"
        )
    }

    func testCodableRoundTrip_preservesTheRunningSprint() throws {
        let original = FocusWidgetSnapshot(
            generatedAt: now,
            activeGoal: nil,
            activeSprint: sprint(deadline: now.addingTimeInterval(600)),
            week: .empty
        )

        let decoded = try JSONDecoder().decode(
            FocusWidgetSnapshot.self, from: try JSONEncoder().encode(original)
        )

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.activeSprint?.taskTitle, "Draft the review")
        XCTAssertEqual(decoded.activeSprint?.checkpointsReached, 1)
    }

    func testSnapshot_withNoSprint_leavesTheFieldNil() {
        let idle = FocusWidgetSnapshot(generatedAt: now, activeGoal: nil, week: .empty)

        XCTAssertNil(idle.activeSprint, "the section hides rather than showing a stopped timer")
        XCTAssertNil(FocusWidgetSnapshot.placeholder.activeSprint)
    }
}
