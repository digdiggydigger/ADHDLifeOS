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

    // MARK: - Retired with the daily streak (`F-E1-WeeklyChain`, 2026-09-25)

    // `bestStreak(tasks:)` and `streakLine(streak:best:closedToday:)` were DELETED, and their seven
    // tests REVERSED into absence assertions in `WeeklyChainRetirementTests`. E's round 3: *"The
    // other two streaks go: the closing streak '6 days · Best is 6'"*, and round 8b sends the three
    // day-streak lines *"with the scoreboard"*. The only caller of either was `MomentumRingCard`'s
    // streak column, which this block removed; the rules those tests pinned (days, not items; a
    // best that never reads below the current run) have no reader left to protect.

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

    // MARK: - Retired with the closure card (`F-C1-UndoCapsule`, 2026-09-20)

    // `celebrationLine(closedTodayCount:areaName:areaRate:)` and `nextButtonLabel(effortSeconds:)`
    // were DELETED with `ClosureCelebrationCard`, and their four tests with them. Both had exactly
    // one call site each — the retired card's text — so they were dead the moment the card was.
    //
    // Recorded rather than silently dropped, because this is the `dead-shared-component-pattern`
    // in its other direction: seven prior instances in this repo were components whose tests kept
    // passing after nothing called them any more. `UndoCapsuleCallSiteTests` now sweeps the whole
    // app target for these two names, so a later block cannot reintroduce them untethered.
}
