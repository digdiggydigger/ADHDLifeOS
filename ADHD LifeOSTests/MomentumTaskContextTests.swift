//
//  MomentumTaskContextTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The task detail's Momentum context (Concept C, S3): the consequence written on the close
/// button ("Close it — keeps a 7-day streak") and the "Momentum here" area line ("💼 Work: 2 of
/// 3 closed this week. Last closed 2 days ago."). Pure strings over data the callers already
/// hold.
final class MomentumTaskContextTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private func doneTask(daysAgo: Int, lifeAreaId: UUID? = nil) -> TaskItem {
        TaskItem(
            id: UUID(), lifeAreaId: lifeAreaId, title: "Done", status: .done, priority: .p3,
            dueDate: nil, completedAt: calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        )
    }

    private func openTask(lifeAreaId: UUID?) -> TaskItem {
        TaskItem(id: UUID(), lifeAreaId: lifeAreaId, title: "Open", status: .open, priority: .p3, dueDate: nil)
    }

    // MARK: - Close button

    /// Only open tasks carry the button now — closing is one-way (E's b11 addendum removed
    /// Reopen everywhere), so the label no longer takes a status.
    func testCloseButtonLabel_statesTheStreakConsequence() {
        XCTAssertEqual(
            MomentumTaskContext.closeButtonLabel(streak: 7),
            "Close it — keeps a 7-day streak"
        )
        XCTAssertEqual(
            MomentumTaskContext.closeButtonLabel(streak: 1),
            "Close it — keeps a 1-day streak"
        )
    }

    /// No streak, no invented consequence.
    func testCloseButtonLabel_withoutAStreak() {
        XCTAssertEqual(MomentumTaskContext.closeButtonLabel(streak: 0), "Close it")
    }

    // MARK: - Area line

    func testBuild_areaLine_readsClosedOverTotalWithLastClosure() {
        let work = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)
        let tasks = [
            doneTask(daysAgo: 2, lifeAreaId: work.id),
            doneTask(daysAgo: 3, lifeAreaId: work.id),
            openTask(lifeAreaId: work.id)
        ]

        let context = MomentumTaskContext.build(
            lifeAreaId: work.id, tasks: tasks, lifeAreas: [work],
            showStreaks: true, asOf: now, calendar: calendar
        )

        XCTAssertEqual(context.areaLine, "💼 Work: 2 of 3 closed this week. Last closed 2 days ago.")
    }

    func testBuild_areaLine_lastClosedTodayAndYesterdayReadAsWords() {
        let work = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)

        let today = MomentumTaskContext.build(
            lifeAreaId: work.id, tasks: [doneTask(daysAgo: 0, lifeAreaId: work.id)],
            lifeAreas: [work], showStreaks: true, asOf: now, calendar: calendar
        )
        let yesterday = MomentumTaskContext.build(
            lifeAreaId: work.id, tasks: [doneTask(daysAgo: 1, lifeAreaId: work.id)],
            lifeAreas: [work], showStreaks: true, asOf: now, calendar: calendar
        )

        XCTAssertEqual(today.areaLine, "💼 Work: 1 of 1 closed this week. Last closed today.")
        XCTAssertEqual(yesterday.areaLine, "💼 Work: 1 of 1 closed this week. Last closed yesterday.")
    }

    /// An area that hasn't moved yet states it plainly rather than inventing a rate.
    func testBuild_areaLine_nothingClosedThisWeek() {
        let work = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)

        let context = MomentumTaskContext.build(
            lifeAreaId: work.id, tasks: [openTask(lifeAreaId: work.id)],
            lifeAreas: [work], showStreaks: true, asOf: now, calendar: calendar
        )

        XCTAssertEqual(context.areaLine, "💼 Work: nothing closed this week yet. 1 open.")
    }

    func testBuild_noAreaMeansNoLine() {
        let context = MomentumTaskContext.build(
            lifeAreaId: nil, tasks: [], lifeAreas: [], showStreaks: true, asOf: now, calendar: calendar
        )

        XCTAssertNil(context.areaLine)
    }

    // MARK: - Streak gating

    func testBuild_respectsTheStreakToggle() {
        let tasks = [doneTask(daysAgo: 0), doneTask(daysAgo: 1)]

        let counted = MomentumTaskContext.build(
            lifeAreaId: nil, tasks: tasks, lifeAreas: [], showStreaks: true, asOf: now, calendar: calendar
        )
        let uncounted = MomentumTaskContext.build(
            lifeAreaId: nil, tasks: tasks, lifeAreas: [], showStreaks: false, asOf: now, calendar: calendar
        )

        XCTAssertEqual(counted.streak, 2)
        XCTAssertEqual(uncounted.streak, 0, "streaks off keeps every number but stops counting")
    }
}
