//
//  MomentumScoreboardTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The pure arithmetic behind Home's Momentum scoreboard (Concept C, 2026-08-24): the closure
/// ring, the streak, the best-next-move pick and the per-area weekly rates. All of it derives
/// from data the app already stores — `completed_at` stamps and `focus_duration_seconds` — with
/// no new backend fields.
final class MomentumScoreboardTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    /// Friday 14 Aug 2026, 09:41 UTC — the mock's own clock.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private func nudge(dismissedDaysAgo: Int?, active: Bool = true) -> Nudge {
        Nudge(
            id: UUID(), label: "Water the plants", schedule: "0 9 * * *", active: active,
            lastFiredAt: dismissedDaysAgo.map { calendar.date(byAdding: .day, value: -$0, to: now)! },
            createdAt: calendar.date(byAdding: .day, value: -30, to: now)!,
            updatedAt: now
        )
    }

    private func doneTask(daysAgo: Int, hour: Int = 8) -> TaskItem {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        let stamp = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        return TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Done", status: .done,
            priority: .p3, dueDate: nil, completedAt: stamp
        )
    }

    private func openTask(
        title: String = "Open",
        priority: TaskPriority = .p3,
        dueDaysFromNow: Int? = nil,
        focusSeconds: Int? = nil,
        lifeAreaId: UUID? = nil
    ) -> TaskSummary {
        TaskSummary(
            id: UUID(), lifeAreaId: lifeAreaId, status: .open, title: title, priority: priority,
            notes: nil,
            dueDate: dueDaysFromNow.map { calendar.date(byAdding: .day, value: $0, to: now)! },
            focusDurationSeconds: focusSeconds, nudgesCount: nil
        )
    }

    // MARK: - Streak

    func testStreak_zeroWhenNothingEverClosed() {
        XCTAssertEqual(MomentumScoreboard.streak(tasks: [], asOf: now, calendar: calendar), 0)
    }

    func testStreak_countsConsecutiveDaysWithAtLeastOneClosure() {
        let tasks = [doneTask(daysAgo: 0), doneTask(daysAgo: 1), doneTask(daysAgo: 2)]

        XCTAssertEqual(MomentumScoreboard.streak(tasks: tasks, asOf: now, calendar: calendar), 3)
    }

    /// Two closures on one day are one day of streak — it counts days, not items.
    func testStreak_multipleClosuresOnOneDayCountOnce() {
        let tasks = [doneTask(daysAgo: 0), doneTask(daysAgo: 0, hour: 6), doneTask(daysAgo: 1)]

        XCTAssertEqual(MomentumScoreboard.streak(tasks: tasks, asOf: now, calendar: calendar), 2)
    }

    /// Nothing closed TODAY yet must not read as a broken streak at 09:41 — the day isn't over.
    /// The chain just starts counting from yesterday.
    func testStreak_aliveWhenTodayIsStillEmpty() {
        let tasks = [doneTask(daysAgo: 1), doneTask(daysAgo: 2)]

        XCTAssertEqual(MomentumScoreboard.streak(tasks: tasks, asOf: now, calendar: calendar), 2)
    }

    func testStreak_gapBreaksTheChain() {
        let tasks = [doneTask(daysAgo: 0), doneTask(daysAgo: 2), doneTask(daysAgo: 3)]

        XCTAssertEqual(MomentumScoreboard.streak(tasks: tasks, asOf: now, calendar: calendar), 1)
    }

    func testStreak_deadWhenLastClosureIsTwoDaysBack() {
        let tasks = [doneTask(daysAgo: 2), doneTask(daysAgo: 3)]

        XCTAssertEqual(MomentumScoreboard.streak(tasks: tasks, asOf: now, calendar: calendar), 0)
    }

    /// Open tasks and stampless documents contribute nothing, whatever their status claims.
    func testStreak_ignoresOpenAndStamplessTasks() {
        var stampless = doneTask(daysAgo: 0)
        stampless.completedAt = nil
        let tasks = [stampless]

        XCTAssertEqual(MomentumScoreboard.streak(tasks: tasks, asOf: now, calendar: calendar), 0)
    }

    // MARK: - Ring

    func testRingProgress_isClosedOverGoal_cappedAtFull() {
        XCTAssertEqual(MomentumScoreboard.ringProgress(closed: 2, goal: 5), 0.4, accuracy: 0.001)
        XCTAssertEqual(MomentumScoreboard.ringProgress(closed: 9, goal: 5), 1.0)
        XCTAssertEqual(MomentumScoreboard.ringProgress(closed: 0, goal: 5), 0.0)
    }

    /// A zero or negative goal must not divide by zero — it reads as "any closure fills the ring".
    func testRingProgress_toleratesAbsurdGoals() {
        XCTAssertEqual(MomentumScoreboard.ringProgress(closed: 1, goal: 0), 1.0)
        XCTAssertEqual(MomentumScoreboard.ringProgress(closed: 0, goal: 0), 0.0)
    }

    // MARK: - Best next move

    /// Due-today beats everything, and among due-today the SHORTEST effort wins — the design's
    /// "one of them is fifteen minutes": the cheapest real win, not the scariest priority.
    func testBestNextMove_prefersShortestEffortAmongDueToday() {
        let quick = openTask(title: "Quick", priority: .p2, dueDaysFromNow: 0, focusSeconds: 900)
        let deep = openTask(title: "Deep", priority: .p1, dueDaysFromNow: 0, focusSeconds: 1500)
        let tomorrow = openTask(title: "Tomorrow", priority: .p1, dueDaysFromNow: 1, focusSeconds: 300)

        let pick = MomentumScoreboard.bestNextMove(in: [deep, tomorrow, quick], asOf: now, calendar: calendar)

        XCTAssertEqual(pick?.title, "Quick")
    }

    /// Overdue is "due now" too — yesterday's deadline doesn't stop being the next move.
    func testBestNextMove_overdueCountsAsDueNow() {
        let overdue = openTask(title: "Overdue", dueDaysFromNow: -1, focusSeconds: 600)
        let someday = openTask(title: "Someday", priority: .p1, focusSeconds: 300)

        let pick = MomentumScoreboard.bestNextMove(in: [someday, overdue], asOf: now, calendar: calendar)

        XCTAssertEqual(pick?.title, "Overdue")
    }

    /// A task with no effort estimate ranks after every estimated one — "unknown" cannot be the
    /// promised fifteen minutes.
    func testBestNextMove_unknownEffortRanksLast() {
        let unknown = openTask(title: "Unknown", priority: .p1, dueDaysFromNow: 0, focusSeconds: nil)
        let estimated = openTask(title: "Estimated", priority: .p4, dueDaysFromNow: 0, focusSeconds: 1800)

        let pick = MomentumScoreboard.bestNextMove(in: [unknown, estimated], asOf: now, calendar: calendar)

        XCTAssertEqual(pick?.title, "Estimated")
    }

    /// With nothing due, it falls back to the Active Goal rule so Home never goes blank while
    /// tasks are open.
    func testBestNextMove_fallsBackToActiveGoalWhenNothingIsDue() {
        let urgent = openTask(title: "Urgent", priority: .p1, dueDaysFromNow: 3)
        let ambient = openTask(title: "Ambient", priority: .p4)

        let pick = MomentumScoreboard.bestNextMove(in: [ambient, urgent], asOf: now, calendar: calendar)

        XCTAssertEqual(pick?.title, "Urgent")
    }

    func testBestNextMove_nilWhenNothingIsOpen() {
        XCTAssertNil(MomentumScoreboard.bestNextMove(in: [], asOf: now, calendar: calendar))
    }

    // MARK: - Areas moving

    func testAreaRate_isClosedOverClosedPlusOpen() {
        XCTAssertEqual(MomentumScoreboard.areaRate(closedThisWeek: 2, open: 1)!, 2.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(MomentumScoreboard.areaRate(closedThisWeek: 3, open: 0), 1.0)
    }

    /// An area with nothing open and nothing closed has no rate — it is dormant, not at 0%.
    func testAreaRate_nilWhenNothingToMeasure() {
        XCTAssertNil(MomentumScoreboard.areaRate(closedThisWeek: 0, open: 0))
    }

    func testClosedThisWeek_isTheTrailingSevenDays() {
        let inside = doneTask(daysAgo: 6)
        let outside = doneTask(daysAgo: 7)
        let today = doneTask(daysAgo: 0)

        let week = MomentumScoreboard.closedThisWeek(tasks: [inside, outside, today], asOf: now, calendar: calendar)

        XCTAssertEqual(week.count, 2)
    }

    func testAreaMomentum_groupsClosedAndOpenByArea() {
        let work = LifeArea(id: UUID(), name: "Work", colour: "\u{1F4BC}", sortOrder: 0)
        let health = LifeArea(id: UUID(), name: "Health", colour: "\u{1F3CB}", sortOrder: 1)
        let base = doneTask(daysAgo: 1)
        let closedWork = TaskItem(
            id: base.id, lifeAreaId: work.id, title: base.title, status: .done,
            priority: base.priority, dueDate: nil, completedAt: base.completedAt
        )
        let openWork = openTask(title: "Open work", lifeAreaId: work.id)

        let items = MomentumScoreboard.areaMomentum(
            areas: [work, health], openTasks: [openWork], allTasks: [closedWork],
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].closedThisWeek, 1)
        XCTAssertEqual(items[0].open, 1)
        XCTAssertEqual(items[0].rate!, 0.5, accuracy: 0.001)
        XCTAssertNil(items[1].rate, "a dormant area has no rate, which is not the same claim as 0%")
    }

    /// Oldest first, today last — the dot row under the streak reads left to right like a calendar.
    func testTrailingWeekClosureFlags_marksEachOfTheLastSevenDays() {
        let tasks = [doneTask(daysAgo: 0), doneTask(daysAgo: 2), doneTask(daysAgo: 6)]

        let flags = MomentumScoreboard.trailingWeekClosureFlags(tasks: tasks, asOf: now, calendar: calendar)

        XCTAssertEqual(flags, [true, false, false, false, true, false, true])
    }

    /// The ring's capture contribution: captures whose exit stamp is today. Only the stamp
    /// counts — a processed capture with no clearedAt predates M7 and belongs to no day.
    func testClearedToday_countsTodaysExitStampsOnly() {
        func cleared(daysAgo: Int?) -> Capture {
            Capture(
                id: UUID(), content: "x", kind: .note, processed: true, createdAt: now,
                clearedAt: daysAgo.map { calendar.date(byAdding: .day, value: -$0, to: now)! }
            )
        }

        let count = MomentumScoreboard.clearedToday(
            captures: [cleared(daysAgo: 0), cleared(daysAgo: 0), cleared(daysAgo: 1), cleared(daysAgo: nil)],
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(count, 2)
    }

    /// The ring's nudge contribution (M9, E's call 2026-08-24): `last_fired_at` IS the
    /// done-event stamp — only the Dismiss tap writes it, with the client clock, and a schedule
    /// fires at most once per day, so today's stamp means exactly one dismissal today. No new
    /// backend field.
    func testDismissedToday_countsTodaysDismissalStampsOnly() {
        let count = MomentumScoreboard.dismissedToday(
            nudges: [
                nudge(dismissedDaysAgo: 0), nudge(dismissedDaysAgo: 0),
                nudge(dismissedDaysAgo: 1), nudge(dismissedDaysAgo: nil)
            ],
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(count, 2)
    }

    /// Deactivating a nudge after dismissing it must not un-count the day's win — the tap
    /// happened today regardless of what the schedule does tomorrow.
    func testDismissedToday_deactivatedNudgeStillCounts() {
        let count = MomentumScoreboard.dismissedToday(
            nudges: [nudge(dismissedDaysAgo: 0, active: false)],
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(count, 1)
    }

    // MARK: - Effort label

    func testEffortLabel_rendersWholeMinutes() {
        XCTAssertEqual(MomentumScoreboard.effortLabel(seconds: 900), "15 min")
        XCTAssertEqual(MomentumScoreboard.effortLabel(seconds: 1500), "25 min")
    }

    /// Sub-minute targets round up — "0 min" promises less than tapping the button costs.
    func testEffortLabel_subMinuteRoundsUp() {
        XCTAssertEqual(MomentumScoreboard.effortLabel(seconds: 30), "1 min")
    }

    func testEffortLabel_nilForUnknownEffort() {
        XCTAssertNil(MomentumScoreboard.effortLabel(seconds: nil))
    }
}
