//
//  FocusWidgetSprintFreshnessTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// How the Home Screen widget keeps a running sprint's readout true without the app's help.
///
/// The app publishes ONCE and is then suspended — iOS gives it no way to update a widget on a
/// schedule. A stored `checkpointsReached` therefore freezes at whatever it was when the app last
/// drew breath (observed in-simulator, 2026-08-20: the widget read "2 of 11" while checkpoint 4 had
/// already fired). The count is derived from the deadline instead, exactly as the countdown already
/// was, and the timeline carries an entry at every moment that readout changes.
final class FocusWidgetSprintFreshnessTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    /// A 900s sprint with checkpoints at 300s and 600s elapsed, 600s still to run — so the playhead
    /// sits at 300s and the first checkpoint has just been passed.
    private func running(
        durationSeconds: Int = 900,
        remaining: Int = 600,
        checkpointSeconds: [Int] = [300, 600]
    ) -> FocusWidgetSnapshot.ActiveSprint {
        FocusWidgetSnapshot.ActiveSprint(
            taskTitle: "Draft the review", emoji: "💼", durationSeconds: durationSeconds,
            deadline: now.addingTimeInterval(TimeInterval(remaining)),
            pausedRemainingSeconds: nil, checkpointSeconds: checkpointSeconds
        )
    }

    private func paused(
        durationSeconds: Int = 900,
        remaining: Int = 600,
        checkpointSeconds: [Int] = [300, 600]
    ) -> FocusWidgetSnapshot.ActiveSprint {
        FocusWidgetSnapshot.ActiveSprint(
            taskTitle: "Draft the review", emoji: "💼", durationSeconds: durationSeconds,
            deadline: nil, pausedRemainingSeconds: remaining, checkpointSeconds: checkpointSeconds
        )
    }

    // MARK: - Elapsed

    func testElapsed_isDerivedFromTheDeadlineAndMovesWithRealTime() {
        let sprint = running(durationSeconds: 900, remaining: 600)

        XCTAssertEqual(sprint.elapsedSeconds(asOf: now), 300)
        XCTAssertEqual(sprint.elapsedSeconds(asOf: now.addingTimeInterval(120)), 420)
    }

    func testElapsed_neverRunsPastThePlannedDuration() {
        let sprint = running(durationSeconds: 900, remaining: 600)

        XCTAssertEqual(
            sprint.elapsedSeconds(asOf: now.addingTimeInterval(86_400)), 900,
            "a sprint that ended hours ago is 900s elapsed, not a day"
        )
    }

    func testElapsed_whilePaused_isFrozenWhereThePlayheadStopped() {
        let sprint = paused(durationSeconds: 900, remaining: 600)

        XCTAssertEqual(sprint.elapsedSeconds(asOf: now), 300)
        XCTAssertEqual(
            sprint.elapsedSeconds(asOf: now.addingTimeInterval(86_400)), 300,
            "a paused sprint does not quietly advance while the phone is in a pocket"
        )
    }

    /// The sprint with NEITHER clock anchor — no deadline and no frozen remainder — which the
    /// `?? 0` under `pausedRemainingSeconds` exists to absorb.
    ///
    /// It is reachable, not merely defensive: `widgetSprint` publishes
    /// `deadline: session.isPaused ? nil : sprintDeadline`, and `sprintDeadline` is itself
    /// optional, so a session that exists before its deadline is set publishes both as nil. The
    /// snapshot is also `Codable` and decoded from the App Group, where any older writer's shape
    /// arrives unvalidated. Reading it as a FULL bar is the safe answer — the section retires
    /// rather than claiming a sprint is still at the start line.
    func testElapsed_withNeitherADeadlineNorAFrozenRemainder_readsAsTheFullDuration() {
        let sprint = FocusWidgetSnapshot.ActiveSprint(
            taskTitle: "Draft the review", emoji: "💼", durationSeconds: 900,
            deadline: nil, pausedRemainingSeconds: nil, checkpointSeconds: [300, 600]
        )

        XCTAssertEqual(sprint.elapsedSeconds(asOf: now), 900)
        XCTAssertEqual(
            sprint.checkpointsReached(asOf: now), 2,
            "every mark sits behind a playhead at the finish"
        )
    }

    // MARK: - Checkpoints reached

    func testCheckpointsReached_countsTheMarksThePlayheadHasPassed() {
        let sprint = running(remaining: 600, checkpointSeconds: [300, 600])

        XCTAssertEqual(sprint.checkpointsReached(asOf: now), 1)
    }

    /// The whole point: no republish, no app, and the number still moves.
    func testCheckpointsReached_advancesOnItsOwnAsTimePasses() {
        let sprint = running(durationSeconds: 900, remaining: 900, checkpointSeconds: [300, 600])

        XCTAssertEqual(sprint.checkpointsReached(asOf: now), 0)
        XCTAssertEqual(sprint.checkpointsReached(asOf: now.addingTimeInterval(300)), 1)
        XCTAssertEqual(sprint.checkpointsReached(asOf: now.addingTimeInterval(600)), 2)
    }

    func testCheckpointsReached_atTheMarkItself_countsIt() {
        // Matches the engine's own `advance`, which fires a checkpoint at `mark <= elapsed`.
        let sprint = running(durationSeconds: 900, remaining: 600, checkpointSeconds: [300])

        XCTAssertEqual(sprint.checkpointsReached(asOf: now), 1)
    }

    func testCheckpointsReached_onAFinishedSprint_isAllOfThem() {
        let sprint = running(durationSeconds: 900, remaining: 600, checkpointSeconds: [300, 600])

        XCTAssertEqual(sprint.checkpointsReached(asOf: now.addingTimeInterval(601)), 2)
    }

    func testCheckpointCount_isThePlansLength() {
        XCTAssertEqual(running(checkpointSeconds: [100, 200, 300]).checkpointCount, 3)
        XCTAssertEqual(running(checkpointSeconds: []).checkpointCount, 0)
    }

    func testCheckpointSummary_readsNOfMAndMovesWithTime() {
        let sprint = running(durationSeconds: 900, remaining: 900, checkpointSeconds: [300, 600])

        XCTAssertEqual(sprint.checkpointSummary(asOf: now), "0 of 2 checkpoints")
        XCTAssertEqual(sprint.checkpointSummary(asOf: now.addingTimeInterval(300)), "1 of 2 checkpoints")
    }

    func testCheckpointSummary_withNoCheckpoints_isNil() {
        XCTAssertNil(running(checkpointSeconds: []).checkpointSummary(asOf: now))
    }

    // MARK: - Refresh dates

    func testRefreshDates_areEveryCheckpointStillAheadPlusTheDeadline() {
        let sprint = running(durationSeconds: 900, remaining: 900, checkpointSeconds: [300, 600])

        XCTAssertEqual(
            sprint.refreshDates(after: now),
            [
                now.addingTimeInterval(300),
                now.addingTimeInterval(600),
                now.addingTimeInterval(900)
            ]
        )
    }

    func testRefreshDates_skipCheckpointsAlreadyBehindThePlayhead() {
        // 300s already elapsed: only the 600s mark and the finish are still to come.
        let sprint = running(durationSeconds: 900, remaining: 600, checkpointSeconds: [300, 600])

        XCTAssertEqual(
            sprint.refreshDates(after: now),
            [now.addingTimeInterval(300), now.addingTimeInterval(600)]
        )
    }

    func testRefreshDates_forAFinishedSprint_areEmpty() {
        let sprint = running(durationSeconds: 900, remaining: 600, checkpointSeconds: [300, 600])

        XCTAssertTrue(
            sprint.refreshDates(after: now.addingTimeInterval(601)).isEmpty,
            "nothing about a finished sprint changes again"
        )
    }

    func testRefreshDates_whilePaused_areEmpty() {
        XCTAssertTrue(
            paused().refreshDates(after: now).isEmpty,
            "a paused sprint's readout changes only when the user resumes it, which republishes"
        )
    }

    /// A 30-second cadence over a long sprint plans dozens of marks. The entries are thinned rather
    /// than truncated, so the count stays roughly right across the WHOLE sprint instead of being
    /// exact for the first few minutes and then frozen.
    func testRefreshDates_beyondTheLimit_areThinnedNotTruncated() {
        let marks = Array(stride(from: 30, to: 900, by: 30))
        let sprint = running(durationSeconds: 900, remaining: 900, checkpointSeconds: marks)

        let dates = sprint.refreshDates(after: now, limit: 6)

        XCTAssertLessThanOrEqual(dates.count, 6 + 1, "the limit bounds the checkpoints, plus the deadline")
        XCTAssertEqual(dates.last, now.addingTimeInterval(900), "the deadline entry always survives")
        XCTAssertGreaterThan(
            try XCTUnwrap(dates.dropLast().last), now.addingTimeInterval(600),
            "the kept entries span the sprint rather than clustering at the start"
        )
    }

    func testRefreshDates_areStrictlyIncreasing() {
        let marks = Array(stride(from: 30, to: 900, by: 30))
        let sprint = running(durationSeconds: 900, remaining: 900, checkpointSeconds: marks)

        let dates = sprint.refreshDates(after: now, limit: 10)

        XCTAssertEqual(dates, dates.sorted())
        XCTAssertEqual(dates.count, Set(dates).count, "a duplicate entry date is a wasted timeline slot")
    }

    // MARK: - Envelope

    func testSnapshotVersion_wasBumpedForTheDerivedShape() {
        XCTAssertEqual(
            FocusWidgetSnapshot.currentVersion, 3,
            "v2 stored the reached count; a v2 payload decoded as v3 would read as zero checkpoints"
        )
    }
}
