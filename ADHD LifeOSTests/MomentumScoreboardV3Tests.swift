//
//  MomentumScoreboardV3Tests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The v3 additions to the scoreboard arithmetic (F-V3-Today): the best-ever streak derived from
/// completion history (no new stored data), the streak line that names it after a close, the
/// per-area status line with its honest staleness clause, and the celebration line that pairs the
/// ordinal with the area's weekly rate.
final class MomentumScoreboardV3Tests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        // A bare `Calendar(identifier:)` has a nil locale, whose weekdaySymbols abbreviate —
        // production always passes `Calendar.current`, which has one.
        cal.locale = Locale(identifier: "en_US")
        return cal
    }

    /// Friday 14 Aug 2026, 09:41 UTC — the mock's own clock.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private func doneTask(daysAgo: Int, hour: Int = 8, lifeAreaId: UUID? = nil) -> TaskItem {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        let stamp = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        return TaskItem(
            id: UUID(), lifeAreaId: lifeAreaId, title: "Done", status: .done,
            priority: .p3, dueDate: nil, completedAt: stamp
        )
    }

    // MARK: - Best-ever streak

    func testBestStreak_zeroWithNoHistory() {
        XCTAssertEqual(MomentumScoreboard.bestStreak(tasks: [], calendar: calendar), 0)
    }

    func testBestStreak_findsTheLongestRunAnywhereInHistory() {
        // A 3-day run two weeks back beats the current 2-day run.
        let tasks = [
            doneTask(daysAgo: 16), doneTask(daysAgo: 15), doneTask(daysAgo: 14),
            doneTask(daysAgo: 1), doneTask(daysAgo: 0)
        ]
        XCTAssertEqual(MomentumScoreboard.bestStreak(tasks: tasks, calendar: calendar), 3)
    }

    func testBestStreak_countsDaysNotItems() {
        // Three closures on one day are one day of streak.
        let tasks = [doneTask(daysAgo: 2, hour: 7), doneTask(daysAgo: 2, hour: 9), doneTask(daysAgo: 2, hour: 20)]
        XCTAssertEqual(MomentumScoreboard.bestStreak(tasks: tasks, calendar: calendar), 1)
    }

    func testBestStreak_currentRunCanBeTheBest() {
        let tasks = [doneTask(daysAgo: 2), doneTask(daysAgo: 1), doneTask(daysAgo: 0), doneTask(daysAgo: 10)]
        XCTAssertEqual(MomentumScoreboard.bestStreak(tasks: tasks, calendar: calendar), 3)
    }

    // MARK: - Streak line

    func testStreakLine_afterACloseNamesTheBest() {
        XCTAssertEqual(
            MomentumScoreboard.streakLine(streak: 7, best: 9, closedToday: 3),
            "Streak kept. Best is 9."
        )
    }

    func testStreakLine_bestNeverReadsBelowTheCurrentStreak() {
        XCTAssertEqual(
            MomentumScoreboard.streakLine(streak: 7, best: 0, closedToday: 1),
            "Streak kept. Best is 7."
        )
    }

    func testStreakLine_quietDayStatesTheRun() {
        XCTAssertEqual(
            MomentumScoreboard.streakLine(streak: 7, best: 9, closedToday: 0),
            "7 days closed in a row."
        )
        XCTAssertEqual(
            MomentumScoreboard.streakLine(streak: 1, best: 9, closedToday: 0),
            "One day closed. Keep it alive today."
        )
    }

    // MARK: - Area status line

    func testAreaStatusLine_allClear() {
        let line = MomentumScoreboard.areaStatusLine(
            closedThisWeek: 3, open: 0, lastClosedAt: doneTask(daysAgo: 1).completedAt,
            asOf: now, calendar: calendar
        )
        XCTAssertEqual(line.text, "3 of 3 closed — all clear")
        XCTAssertEqual(line.tone, .clear)
    }

    func testAreaStatusLine_plainCount() {
        let line = MomentumScoreboard.areaStatusLine(
            closedThisWeek: 2, open: 1, lastClosedAt: doneTask(daysAgo: 1).completedAt,
            asOf: now, calendar: calendar
        )
        XCTAssertEqual(line.text, "2 of 3 tasks closed")
        XCTAssertEqual(line.tone, .plain)
    }

    func testAreaStatusLine_quietSinceNamesTheWeekday() {
        // Last close 5 days before Friday 14 Aug = Sunday 9 Aug.
        let line = MomentumScoreboard.areaStatusLine(
            closedThisWeek: 1, open: 1, lastClosedAt: doneTask(daysAgo: 5).completedAt,
            asOf: now, calendar: calendar
        )
        XCTAssertEqual(line.text, "1 of 2 closed — quiet since Sunday")
        XCTAssertEqual(line.tone, .quiet)
    }

    func testAreaStatusLine_quietAllWeekWhenTheGapOutrunsTheWindow() {
        let line = MomentumScoreboard.areaStatusLine(
            closedThisWeek: 0, open: 2, lastClosedAt: doneTask(daysAgo: 9).completedAt,
            asOf: now, calendar: calendar
        )
        XCTAssertEqual(line.text, "0 of 2 closed — quiet all week")
        XCTAssertEqual(line.tone, .quiet)
    }

    func testAreaStatusLine_neverClosedStaysPlainNotShamed() {
        let line = MomentumScoreboard.areaStatusLine(
            closedThisWeek: 0, open: 2, lastClosedAt: nil, asOf: now, calendar: calendar
        )
        XCTAssertEqual(line.text, "0 of 2 tasks closed")
        XCTAssertEqual(line.tone, .plain)
    }

    func testAreaStatusLine_emptyArea() {
        let line = MomentumScoreboard.areaStatusLine(
            closedThisWeek: 0, open: 0, lastClosedAt: nil, asOf: now, calendar: calendar
        )
        XCTAssertEqual(line.text, "Nothing open or closed this week")
        XCTAssertEqual(line.tone, .plain)
    }

    // MARK: - Area momentum carries the last close

    func testAreaMomentum_carriesTheAreasLastCloseFromAllHistory() {
        let area = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)
        let other = LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 1)
        let oldClose = doneTask(daysAgo: 12, lifeAreaId: area.id)
        let newClose = doneTask(daysAgo: 9, lifeAreaId: area.id)
        let momentum = MomentumScoreboard.areaMomentum(
            areas: [area, other], openTasks: [], allTasks: [oldClose, newClose],
            asOf: now, calendar: calendar
        )
        XCTAssertEqual(momentum[0].lastClosedAt, newClose.completedAt)
        XCTAssertNil(momentum[1].lastClosedAt)
    }

    // MARK: - Celebration line

    func testCelebrationLine_pairsOrdinalWithAreaRate() {
        XCTAssertEqual(
            MomentumScoreboard.celebrationLine(closedTodayCount: 3, areaName: "Admin & Home", areaRate: 0.75),
            "Third today. Admin & Home is up to 75% this week."
        )
    }

    func testCelebrationLine_allClearArea() {
        XCTAssertEqual(
            MomentumScoreboard.celebrationLine(closedTodayCount: 1, areaName: "Health", areaRate: 1),
            "First today. Health is all clear this week."
        )
    }

    func testCelebrationLine_ordinalAloneWithoutAnArea() {
        XCTAssertEqual(
            MomentumScoreboard.celebrationLine(closedTodayCount: 5, areaName: nil, areaRate: nil),
            "5 closed today."
        )
    }

    // MARK: - Next button label

    func testNextButtonLabel_carriesTheEffort() {
        XCTAssertEqual(MomentumScoreboard.nextButtonLabel(effortSeconds: 1200), "Next: 20 min")
        XCTAssertEqual(MomentumScoreboard.nextButtonLabel(effortSeconds: nil), "Next")
    }
}
