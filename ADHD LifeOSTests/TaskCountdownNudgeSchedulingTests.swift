//
//  TaskCountdownNudgeSchedulingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class TaskCountdownNudgeSchedulingTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    // MARK: - Mode selection (6-hour boundary)

    func testMode_exactlySixHoursRemaining_isEvenDivision() {
        let dueDate = now.addingTimeInterval(6 * 3600)
        XCTAssertEqual(TaskCountdownNudgeScheduling.mode(now: now, dueDate: dueDate), .evenDivision)
    }

    func testMode_justOverSixHoursRemaining_isCheckpoint() {
        let dueDate = now.addingTimeInterval(6 * 3600 + 1)
        XCTAssertEqual(TaskCountdownNudgeScheduling.mode(now: now, dueDate: dueDate), .checkpoint)
    }

    func testMode_wellUnderSixHours_isEvenDivision() {
        let dueDate = now.addingTimeInterval(42 * 60)
        XCTAssertEqual(TaskCountdownNudgeScheduling.mode(now: now, dueDate: dueDate), .evenDivision)
    }

    // MARK: - Even-division fire dates (E's own worked example: 42 minutes remaining)

    func testEvenDivisionFireDates_oneNudge_firesAtHalfwayPoint() {
        let dueDate = now.addingTimeInterval(42 * 60)
        let fireDates = TaskCountdownNudgeScheduling.evenDivisionFireDates(now: now, dueDate: dueDate, count: 1)
        XCTAssertEqual(fireDates, [now.addingTimeInterval(21 * 60)])
    }

    func testEvenDivisionFireDates_twoNudges_firesAtThirdsPoints() {
        let dueDate = now.addingTimeInterval(42 * 60)
        let fireDates = TaskCountdownNudgeScheduling.evenDivisionFireDates(now: now, dueDate: dueDate, count: 2)
        XCTAssertEqual(fireDates, [now.addingTimeInterval(14 * 60), now.addingTimeInterval(28 * 60)])
    }

    func testEvenDivisionFireDates_threeNudges_firesAtQuartersPoints() {
        let dueDate = now.addingTimeInterval(42 * 60)
        let fireDates = TaskCountdownNudgeScheduling.evenDivisionFireDates(now: now, dueDate: dueDate, count: 3)
        XCTAssertEqual(
            fireDates,
            [now.addingTimeInterval(10.5 * 60), now.addingTimeInterval(21 * 60), now.addingTimeInterval(31.5 * 60)]
        )
    }

    func testEvenDivisionFireDates_dueDateInPast_returnsEmpty() {
        let dueDate = now.addingTimeInterval(-60)
        XCTAssertEqual(TaskCountdownNudgeScheduling.evenDivisionFireDates(now: now, dueDate: dueDate, count: 2), [])
    }

    func testEvenDivisionFireDates_zeroCount_returnsEmpty() {
        let dueDate = now.addingTimeInterval(42 * 60)
        XCTAssertEqual(TaskCountdownNudgeScheduling.evenDivisionFireDates(now: now, dueDate: dueDate, count: 0), [])
    }

    func testEvenDivisionMenuOptions_dueDateInPast_returnsNoOptions() {
        let dueDate = now.addingTimeInterval(-60)
        XCTAssertEqual(TaskCountdownNudgeScheduling.evenDivisionMenuOptions(now: now, dueDate: dueDate), [])
    }

    func testEvenDivisionMenuOptions_fortyTwoMinutes_labelsEachOptionWithItsInterval() {
        let dueDate = now.addingTimeInterval(42 * 60)
        let options = TaskCountdownNudgeScheduling.evenDivisionMenuOptions(now: now, dueDate: dueDate)
        XCTAssertEqual(options.map(\.count), [1, 2, 3])
        XCTAssertEqual(options[0].intervalDescription, "1 nudge (every 21 min)")
        XCTAssertEqual(options[1].intervalDescription, "2 nudges (every 14 min)")
        XCTAssertEqual(options[2].intervalDescription, "3 nudges (every 10.5 min)")
    }

    // MARK: - Checkpoint filtering (>6-hour adaptive mode)

    func testApplicableCheckpoints_dueDateTwoDaysAway_excludesPastCheckpoints() {
        let dueDate = now.addingTimeInterval(2 * 24 * 3600)
        let applicable = TaskCountdownNudgeScheduling.applicableCheckpoints(now: now, dueDate: dueDate)
        // 1 week before and 3 days before would land in the past relative to `now`.
        XCTAssertEqual(applicable, [.oneDayBefore, .threeHoursBefore, .oneHourBefore])
    }

    func testApplicableCheckpoints_dueDateFarInFuture_includesAllCheckpoints() {
        let dueDate = now.addingTimeInterval(30 * 24 * 3600)
        let applicable = TaskCountdownNudgeScheduling.applicableCheckpoints(now: now, dueDate: dueDate)
        XCTAssertEqual(applicable, NudgeCheckpoint.allCases)
    }

    func testApplicableCheckpoints_dueDateJustOverSixHoursAway_includesOnlyNearCheckpoints() {
        let dueDate = now.addingTimeInterval(6 * 3600 + 1)
        let applicable = TaskCountdownNudgeScheduling.applicableCheckpoints(now: now, dueDate: dueDate)
        XCTAssertEqual(applicable, [.threeHoursBefore, .oneHourBefore])
    }

    func testFireDate_forCheckpoint_isDueDateMinusOffset() {
        let dueDate = now.addingTimeInterval(24 * 3600)
        XCTAssertEqual(
            TaskCountdownNudgeScheduling.fireDate(for: .oneDayBefore, dueDate: dueDate),
            dueDate.addingTimeInterval(-24 * 3600)
        )
    }

    // MARK: - Resolving a selection into scheduled nudges

    func testResolveFireDates_none_returnsEmpty() {
        let dueDate = now.addingTimeInterval(42 * 60)
        XCTAssertEqual(
            TaskCountdownNudgeScheduling.resolveFireDates(selection: .none, now: now, dueDate: dueDate), []
        )
    }

    func testResolveFireDates_evenDivision_mapsToScheduledNudges() {
        let dueDate = now.addingTimeInterval(42 * 60)
        let resolved = TaskCountdownNudgeScheduling.resolveFireDates(
            selection: .evenDivision(count: 2), now: now, dueDate: dueDate
        )
        XCTAssertEqual(resolved.map(\.date), [now.addingTimeInterval(14 * 60), now.addingTimeInterval(28 * 60)])
    }

    func testResolveFireDates_checkpoints_filtersPastOnesAndSortsAscending() {
        let dueDate = now.addingTimeInterval(2 * 24 * 3600)
        // .oneWeekBefore would land in the past relative to `now` and must be dropped, not crash.
        let resolved = TaskCountdownNudgeScheduling.resolveFireDates(
            selection: .checkpoints([.oneWeekBefore, .oneDayBefore, .oneHourBefore]), now: now, dueDate: dueDate
        )
        XCTAssertEqual(resolved.map(\.body), [NudgeCheckpoint.oneDayBefore.label, NudgeCheckpoint.oneHourBefore.label])
        XCTAssertTrue(resolved[0].date < resolved[1].date)
    }
}
