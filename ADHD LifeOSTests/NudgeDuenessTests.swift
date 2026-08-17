//
//  NudgeDuenessTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class NudgeDuenessTests: XCTestCase {

    private let utc = TimeZone(identifier: "UTC")!
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private func date(_ iso: String) -> Date {
        dateFormatter.date(from: iso)!
    }

    private func makeNudge(
        schedule: String = "0 9 * * *",
        active: Bool = true,
        lastFiredAt: Date? = nil,
        createdAt: Date
    ) -> Nudge {
        Nudge(
            id: UUID(), label: "Morning check-in", schedule: schedule, active: active,
            lastFiredAt: lastFiredAt, createdAt: createdAt, updatedAt: createdAt
        )
    }

    func testInactiveNudge_isNeverDue_evenWithLongOverdueSchedule() {
        let nudge = makeNudge(active: false, createdAt: date("2020-01-01T00:00:00Z"))

        XCTAssertFalse(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-15T09:00:00Z"), timeZone: utc))
    }

    func testDailyPreset_neverFired_isDueOnceScheduleHasElapsedSinceCreatedAt() {
        let nudge = makeNudge(
            schedule: "0 9 * * *",
            createdAt: date("2026-07-01T09:00:00Z")
        )

        XCTAssertTrue(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-15T09:00:00Z"), timeZone: utc))
    }

    func testDailyPreset_justFired_isNotDueAgainWithinInterval() {
        let nudge = makeNudge(
            lastFiredAt: date("2026-07-15T09:00:00Z"),
            createdAt: date("2020-01-01T00:00:00Z")
        )

        XCTAssertFalse(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-15T15:00:00Z"), timeZone: utc))
    }

    func testDailyPreset_boundary_dueAtExactlyTheNextScheduledFireTime() {
        let nudge = makeNudge(createdAt: date("2026-07-14T09:00:00Z"))

        // Next occurrence strictly after createdAt (2026-07-14T09:00Z) is 2026-07-15T09:00Z.
        XCTAssertTrue(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-15T09:00:00Z"), timeZone: utc))
    }

    func testDailyPreset_notYetDue_oneSecondBeforeBoundary() {
        let nudge = makeNudge(createdAt: date("2026-07-14T09:00:00Z"))

        XCTAssertFalse(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-15T08:59:59Z"), timeZone: utc))
    }

    func testUsesLastFiredAt_insteadOfCreatedAt_onceNudgeHasFiredAtLeastOnce() {
        let nudge = makeNudge(
            lastFiredAt: date("2026-07-15T09:00:00Z"),
            createdAt: date("2020-01-01T00:00:00Z")
        )

        XCTAssertTrue(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-16T09:00:00Z"), timeZone: utc))
    }

    func testWeekdaysPreset_skipsWeekend() {
        // 2026-07-17 is a Friday; next weekday occurrence should be Monday 2026-07-20, not Saturday.
        let nudge = makeNudge(
            schedule: "0 9 * * 1-5",
            createdAt: date("2026-07-17T09:00:00Z")
        )

        XCTAssertFalse(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-18T09:00:00Z"), timeZone: utc))
        XCTAssertTrue(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-20T09:00:00Z"), timeZone: utc))
    }

    func testEveryMondayPreset_onlyDueOnMonday() {
        // 2026-07-13 is a Monday; next occurrence is the following Monday, 2026-07-20.
        let nudge = makeNudge(
            schedule: "0 9 * * 1",
            createdAt: date("2026-07-13T09:00:00Z")
        )

        XCTAssertFalse(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-16T09:00:00Z"), timeZone: utc))
        XCTAssertTrue(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-20T09:00:00Z"), timeZone: utc))
    }

    func testUnsupportedSchedule_dayOfMonthPresent_isNeverDue() {
        let nudge = makeNudge(
            schedule: "0 9 1 * *",
            createdAt: date("2020-01-01T00:00:00Z")
        )

        XCTAssertFalse(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-15T09:00:00Z"), timeZone: utc))
    }

    /// Explicit local-timezone regression test: a fixed reference/now pair that gives a different
    /// due/not-due answer under UTC vs. a real local (non-UTC) timezone. Mobile must use the
    /// local timezone from day one — web's `isNudgeDue` hardcodes UTC (`QA_AUDIT.md` FIX-005),
    /// causing nudges to fire an hour late during BST; mobile does not port that bug.
    func testUsesLocalTimezone_notUTC_forNextFireTimeComputation() {
        let london = TimeZone(identifier: "Europe/London")!
        // createdAt is 2026-07-15T00:30 in Europe/London (BST, UTC+1) but 2026-07-14T23:30 UTC.
        let nudge = makeNudge(
            schedule: "0 9 * * *",
            createdAt: date("2026-07-14T23:30:00Z")
        )
        let now = date("2026-07-15T08:30:00Z")

        // Under UTC, the next 9am fire is 2026-07-15T09:00Z, which is after `now` — not due.
        XCTAssertFalse(NudgeDueness.isNudgeDue(nudge: nudge, now: now, timeZone: utc))
        // Under Europe/London (BST = UTC+1), the next local 9am fire is 2026-07-15T08:00Z — due.
        XCTAssertTrue(NudgeDueness.isNudgeDue(nudge: nudge, now: now, timeZone: london))
    }

    // MARK: Arbitrary time-of-day / weekday combinations (Flexible Nudge Schedules)

    func testArbitraryTime_8am_neverFired_isDueOnceElapsed() {
        let nudge = makeNudge(
            schedule: "0 8 * * *",
            createdAt: date("2026-07-14T08:00:00Z")
        )

        XCTAssertFalse(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-15T07:59:59Z"), timeZone: utc))
        XCTAssertTrue(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-15T08:00:00Z"), timeZone: utc))
    }

    func testArbitraryWeekdaySet_tuesdayAndThursday_onlyDueOnThoseDays() {
        // 2026-07-14 is a Tuesday, 2026-07-16 is a Thursday.
        let nudge = makeNudge(
            schedule: "0 8 * * 2,4",
            createdAt: date("2026-07-14T08:00:00Z")
        )

        // 2026-07-15 (Wednesday) is not a match.
        XCTAssertFalse(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-15T08:00:00Z"), timeZone: utc))
        // 2026-07-16 (Thursday) is the next match.
        XCTAssertTrue(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-16T08:00:00Z"), timeZone: utc))
    }

    func testArbitraryWeekdaySet_weekend_onlyDueOnSaturdayAndSunday() {
        // 2026-07-17 is a Friday; next occurrence is Saturday 2026-07-18.
        let nudge = makeNudge(
            schedule: "0 10 * * 6,0",
            createdAt: date("2026-07-17T10:00:00Z")
        )

        XCTAssertFalse(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-17T23:59:59Z"), timeZone: utc))
        XCTAssertTrue(NudgeDueness.isNudgeDue(nudge: nudge, now: date("2026-07-18T10:00:00Z"), timeZone: utc))
    }
}
