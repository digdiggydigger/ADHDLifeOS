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

    /// REVERSED (`F-E1-WeeklyChain`) from `testCloseButtonLabel_statesTheStreakConsequence`. E,
    /// round 8b: *"'Close it — makes today count'"* — shown only while today has no activity yet,
    /// *"the gamification principle framed as a gain toward the weekly chain, never a loss."*
    func testCloseButtonLabel_namesTheGainWhileTodayHasNotCounted() {
        XCTAssertEqual(
            MomentumTaskContext.closeButtonLabel(hasCountedToday: false),
            "Close it — makes today count"
        )
    }

    /// REVERSED from `testCloseButtonLabel_withoutAStreak`: once today counts, closing another task
    /// adds nothing to the chain — so the button claims nothing.
    func testCloseButtonLabel_isPlainOnceTodayCounts() {
        XCTAssertEqual(MomentumTaskContext.closeButtonLabel(hasCountedToday: true), "Close it")
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
            showStreaks: true, hasCountedToday: true, asOf: now, calendar: calendar
        )

        XCTAssertEqual(context.areaLine, "💼 Work: 2 of 3 closed this week. Last closed 2 days ago.")
    }

    func testBuild_areaLine_lastClosedTodayAndYesterdayReadAsWords() {
        let work = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)

        let today = MomentumTaskContext.build(
            lifeAreaId: work.id, tasks: [doneTask(daysAgo: 0, lifeAreaId: work.id)],
            lifeAreas: [work], showStreaks: true, hasCountedToday: true, asOf: now, calendar: calendar
        )
        let yesterday = MomentumTaskContext.build(
            lifeAreaId: work.id, tasks: [doneTask(daysAgo: 1, lifeAreaId: work.id)],
            lifeAreas: [work], showStreaks: true, hasCountedToday: true, asOf: now, calendar: calendar
        )

        XCTAssertEqual(today.areaLine, "💼 Work: 1 of 1 closed this week. Last closed today.")
        XCTAssertEqual(yesterday.areaLine, "💼 Work: 1 of 1 closed this week. Last closed yesterday.")
    }

    /// An area that hasn't moved yet states it plainly rather than inventing a rate.
    func testBuild_areaLine_nothingClosedThisWeek() {
        let work = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)

        let context = MomentumTaskContext.build(
            lifeAreaId: work.id, tasks: [openTask(lifeAreaId: work.id)],
            lifeAreas: [work], showStreaks: true, hasCountedToday: true, asOf: now, calendar: calendar
        )

        XCTAssertEqual(context.areaLine, "💼 Work: nothing closed this week yet. 1 open.")
    }

    func testBuild_noAreaMeansNoLine() {
        let context = MomentumTaskContext.build(
            lifeAreaId: nil, tasks: [], lifeAreas: [], showStreaks: true, hasCountedToday: true,
            asOf: now, calendar: calendar
        )

        XCTAssertNil(context.areaLine)
    }

    // MARK: - Chain gating

    /// REVERSED from `testBuild_respectsTheStreakToggle`. `showStreaks` now gates the weekly
    /// CHAIN's display, and "makes today count" speaks for the chain — so with the chain hidden
    /// the button claims nothing either, whatever today holds.
    func testBuild_respectsTheChainToggle() {
        let counted = MomentumTaskContext.build(
            lifeAreaId: nil, tasks: [], lifeAreas: [], showStreaks: true, hasCountedToday: false,
            asOf: now, calendar: calendar
        )
        let hidden = MomentumTaskContext.build(
            lifeAreaId: nil, tasks: [], lifeAreas: [], showStreaks: false, hasCountedToday: false,
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(counted.closeButtonTitle, "Close it — makes today count")
        XCTAssertEqual(hidden.closeButtonTitle, "Close it", "a hidden chain gets no gain line")
    }

    /// The caller's answer is carried, never recomputed: `build` holds only tasks, and today may
    /// already count on a journal line or a sorted capture it cannot see.
    func testBuild_carriesTheCallersHasCountedToday() {
        let already = MomentumTaskContext.build(
            lifeAreaId: nil, tasks: [], lifeAreas: [], showStreaks: true, hasCountedToday: true,
            asOf: now, calendar: calendar
        )

        XCTAssertTrue(already.hasCountedToday)
        XCTAssertEqual(already.closeButtonTitle, "Close it")
        XCTAssertEqual(MomentumTaskContext.Context.empty.closeButtonTitle, "Close it")
    }
}
