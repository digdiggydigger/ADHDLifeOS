//
//  MomentumWeekReviewTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The week review (Concept C, S5 / block M6): evidence, not verdict — trailing-week closures,
/// focus stamina, the honest "quiet this week", and a gentle kickstart. Derived locally from
/// data Home already holds; the AI-written reflection stays the daily card's job.
final class MomentumWeekReviewTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    /// Friday 14 Aug 2026 09:41 UTC.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private func doneTask(_ title: String, daysAgo: Int, lifeAreaId: UUID? = nil) -> TaskItem {
        TaskItem(
            id: UUID(), lifeAreaId: lifeAreaId, title: title, status: .done, priority: .p3,
            dueDate: nil, completedAt: calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        )
    }

    private func openTask(_ title: String, focusSeconds: Int?, lifeAreaId: UUID? = nil) -> TaskItem {
        TaskItem(
            id: UUID(), lifeAreaId: lifeAreaId, title: title, status: .open, priority: .p3,
            dueDate: nil, focusDurationSeconds: focusSeconds
        )
    }

    private func session(daysAgo: Int, planned: Int, focused: Int) -> CompletedFocusSession {
        let ended = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        return CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Sprint", lifeAreaEmoji: "💼",
            plannedSeconds: planned, focusedSeconds: focused, checkpointsReached: 0,
            completedNaturally: true, startedAt: ended.addingTimeInterval(-Double(focused)), endedAt: ended
        )
    }

    func testBuild_headlineCountsTheTrailingWeek() {
        let review = MomentumWeekReview.build(
            tasks: [doneTask("A", daysAgo: 0), doneTask("B", daysAgo: 6), doneTask("Old", daysAgo: 8)],
            lifeAreas: [], sessions: [session(daysAgo: 1, planned: 1500, focused: 1200)],
            inboxCount: 0, asOf: now, calendar: calendar
        )

        XCTAssertEqual(review.headline, "2 closed · 20 focus minutes")
    }

    /// Oldest first, today last — the bars read like a calendar, and the labels name the days.
    func testBuild_dayBarsCoverSevenDays() {
        let review = MomentumWeekReview.build(
            tasks: [doneTask("A", daysAgo: 0), doneTask("B", daysAgo: 0), doneTask("C", daysAgo: 2)],
            lifeAreas: [], sessions: [], inboxCount: 0, asOf: now, calendar: calendar
        )

        XCTAssertEqual(review.dayCounts, [0, 0, 0, 0, 1, 0, 2])
        XCTAssertEqual(review.dayLabels.count, 7)
        XCTAssertEqual(review.dayLabels.last, "Fri", "the review runs up to the asOf day")
    }

    /// The wins are named, newest first, capped at three — a dopamine list, not a ledger.
    func testBuild_dopamineWins_newestFirstCappedAtThree() {
        let review = MomentumWeekReview.build(
            tasks: [
                doneTask("Oldest", daysAgo: 4), doneTask("Newer", daysAgo: 1),
                doneTask("Newest", daysAgo: 0), doneTask("Mid", daysAgo: 2)
            ],
            lifeAreas: [], sessions: [], inboxCount: 0, asOf: now, calendar: calendar
        )

        XCTAssertEqual(review.dopamineWins, ["Newest", "Newer", "Mid"])
    }

    func testBuild_staminaLine_isFocusedOverPlanned() {
        let review = MomentumWeekReview.build(
            tasks: [], lifeAreas: [],
            sessions: [
                session(daysAgo: 0, planned: 1200, focused: 600),
                session(daysAgo: 2, planned: 600, focused: 900)
            ],
            inboxCount: 0, asOf: now, calendar: calendar
        )

        XCTAssertEqual(review.staminaLine, "83% of targeted minutes actually logged")
    }

    func testBuild_staminaLine_nilWithoutSessions() {
        let review = MomentumWeekReview.build(
            tasks: [], lifeAreas: [], sessions: [], inboxCount: 0, asOf: now, calendar: calendar
        )

        XCTAssertNil(review.staminaLine)
    }

    /// Quiet is stated, never scored: dormant areas by name, and the unfiled pile — "just what
    /// next week starts with".
    func testBuild_quietLine_namesDormantAreasAndUnfiledCaptures() {
        let work = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)
        let hobbies = LifeArea(id: UUID(), name: "Hobbies", colour: "🎨", sortOrder: 1)

        let review = MomentumWeekReview.build(
            tasks: [
                doneTask("A", daysAgo: 0, lifeAreaId: work.id),
                openTask("B", focusSeconds: nil, lifeAreaId: hobbies.id)
            ],
            lifeAreas: [work, hobbies], sessions: [], inboxCount: 4, asOf: now, calendar: calendar
        )

        XCTAssertEqual(
            review.quietLine,
            "Nothing closed in Hobbies this week, and 4 captures are still unfiled. "
                + "Neither is a failure — they are just what next week starts with."
        )
    }

    func testBuild_quietLine_nilWhenEverythingMoved() {
        let work = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)

        let review = MomentumWeekReview.build(
            tasks: [doneTask("A", daysAgo: 0, lifeAreaId: work.id)],
            lifeAreas: [work], sessions: [], inboxCount: 0, asOf: now, calendar: calendar
        )

        XCTAssertNil(review.quietLine)
    }

    /// The kickstart is the two cheapest open tasks, effort-labelled — the shortest honest way in.
    func testBuild_kickstart_twoShortestOpenTasks() {
        let review = MomentumWeekReview.build(
            tasks: [
                openTask("Slow", focusSeconds: 1800),
                openTask("Quick", focusSeconds: 300),
                openTask("Mid", focusSeconds: 900),
                openTask("Unknown", focusSeconds: nil)
            ],
            lifeAreas: [], sessions: [], inboxCount: 0, asOf: now, calendar: calendar
        )

        XCTAssertEqual(review.kickstart, ["5 min · Quick", "15 min · Mid"])
    }
}
