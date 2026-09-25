//
//  WeeklyActiveChainTests.swift
//  ADHD LifeOSTests
//
//  `F-E1-WeeklyChain` — E's round 3: *"A week 'counts' once the user is active on N days they
//  choose. One missed week a month is repaired automatically."* Round 5b: N defaults to 3, and
//  *"What counts as an active day → 'Anything that moves life on'. Closing a task, finishing a
//  sprint, writing a journal line, or sorting a capture."*
//
//  These REPLACE `MomentumScoreboardTests`' six `testStreak_*` (the daily, task-closure-only streak
//  E retired): each rule those tests pinned — days not items, an unfinished today is not a miss,
//  stampless documents count for nothing — survives here one level up, on weeks.
//

import XCTest
@testable import ADHD_LifeOS

final class WeeklyActiveChainTests: XCTestCase {
    /// Monday-first and pinned to one zone, so a week's boundaries never move under a test.
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        calendar.firstWeekday = 2
        return calendar
    }()

    /// Thursday 24 September 2026, 09:41 — mid-week, so "this week" is genuinely unfinished.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 9, minute: 41))!
    }

    /// Monday of the current week.
    private var thisMonday: Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 21, hour: 12))!
    }

    /// A noon stamp `weeksAgo` weeks back, on the `weekday`-th day of that week (0 = Monday).
    private func stamp(weeksAgo: Int, weekday: Int, hour: Int = 12) -> Date {
        let day = calendar.date(byAdding: .day, value: -7 * weeksAgo + weekday, to: thisMonday)!
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
    }

    /// `days` distinct active days in the week `weeksAgo` back (journal lines are the cheapest
    /// signal to build; the source does not matter to the chain).
    private func activeWeek(weeksAgo: Int, days: Int) -> [Date] {
        (0..<days).map { stamp(weeksAgo: weeksAgo, weekday: $0) }
    }

    private func chain(_ journal: [Date], goal: Int = 3) -> Int {
        let days = WeeklyActiveChain.activeDays(WeeklyActiveChain.Signals(journalLines: journal), calendar: calendar)
        return WeeklyActiveChain.chainLength(activeDays: days, goal: goal, asOf: now, calendar: calendar)
    }

    private func doneTask(at stamp: Date) -> TaskItem {
        TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Done", status: .done,
            priority: .p3, dueDate: nil, completedAt: stamp
        )
    }

    private func session(endedAt: Date) -> CompletedFocusSession {
        CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Sprint", lifeAreaEmoji: "💼",
            plannedSeconds: 900, focusedSeconds: 900, checkpointsReached: 0,
            completedNaturally: true, startedAt: endedAt.addingTimeInterval(-900), endedAt: endedAt
        )
    }

    // MARK: - The defaults E chose

    func testTheDefaultWeeklyGoalIsThreeDays() {
        XCTAssertEqual(WeeklyActiveChain.defaultGoal, 3, "round 5b: '3 days' (the default; changeable in Settings)")
        XCTAssertEqual(WeeklyActiveChain.goalRange, 1...7)
    }

    // MARK: - What counts as an active day

    /// Each of the four signals round 5b names makes a day count on its own.
    func testEachOfTheFourSignalsMakesADayActive() {
        let today = stamp(weeksAgo: 0, weekday: 3, hour: 8)
        let signals: [(String, WeeklyActiveChain.Signals)] = [
            ("closing a task", WeeklyActiveChain.Signals(tasks: [doneTask(at: today)])),
            ("finishing a sprint", WeeklyActiveChain.Signals(sessions: [session(endedAt: today)])),
            ("writing a journal line", WeeklyActiveChain.Signals(journalLines: [today])),
            ("sorting a capture", WeeklyActiveChain.Signals(capturesCleared: [today]))
        ]
        for (name, signal) in signals {
            XCTAssertTrue(
                WeeklyActiveChain.hasCountedToday(signal, asOf: now, calendar: calendar),
                "\(name) must make today count"
            )
        }
    }

    /// The control: yesterday's activity does not make TODAY count, and nothing at all is nothing.
    func testTodayDoesNotCountOnYesterdaysWork() {
        let yesterday = stamp(weeksAgo: 0, weekday: 2)
        let signals = WeeklyActiveChain.Signals(
            tasks: [doneTask(at: yesterday)], sessions: [session(endedAt: yesterday)],
            capturesCleared: [yesterday], journalLines: [yesterday]
        )
        XCTAssertFalse(WeeklyActiveChain.hasCountedToday(signals, asOf: now, calendar: calendar))
        XCTAssertFalse(WeeklyActiveChain.hasCountedToday(.init(), asOf: now, calendar: calendar))
    }

    /// Reversed from `testStreak_multipleClosuresOnOneDayCountOnce`: days, not items — and now
    /// across sources too, so a close and a journal line on one day are still one day.
    func testSeveralSignalsOnOneDayAreOneActiveDay() {
        let morning = stamp(weeksAgo: 0, weekday: 1, hour: 7)
        let evening = stamp(weeksAgo: 0, weekday: 1, hour: 21)
        let signals = WeeklyActiveChain.Signals(
            tasks: [doneTask(at: morning), doneTask(at: evening)], journalLines: [evening]
        )
        XCTAssertEqual(WeeklyActiveChain.activeDays(signals, calendar: calendar).count, 1)
    }

    /// Reversed from `testStreak_ignoresOpenAndStamplessTasks`: an open task, or a done one with no
    /// `completed_at`, belongs to no day.
    func testOpenAndStamplessTasksMakeNoDayActive() {
        var stampless = doneTask(at: now)
        stampless.completedAt = nil
        var reopened = doneTask(at: now)
        reopened.status = .open
        let signals = WeeklyActiveChain.Signals(tasks: [stampless, reopened])
        XCTAssertTrue(WeeklyActiveChain.activeDays(signals, calendar: calendar).isEmpty)
    }

    // MARK: - The chain

    /// Reversed from `testStreak_zeroWhenNothingEverClosed`.
    func testNoActivityIsNoChain() {
        XCTAssertEqual(chain([]), 0)
    }

    /// Reversed from `testStreak_countsConsecutiveDaysWithAtLeastOneClosure`, on weeks.
    func testConsecutiveCountedWeeksChain() {
        let journal = activeWeek(weeksAgo: 1, days: 3) + activeWeek(weeksAgo: 2, days: 4)
            + activeWeek(weeksAgo: 3, days: 3)
        XCTAssertEqual(chain(journal), 3)
    }

    /// Reversed from `testStreak_aliveWhenTodayIsStillEmpty`: an unfinished WEEK is not a miss. On
    /// Thursday with one active day the chain still stands on the weeks behind it…
    func testAnUnfinishedWeekShortOfTheGoalDoesNotBreakTheChain() {
        let journal = activeWeek(weeksAgo: 0, days: 1) + activeWeek(weeksAgo: 1, days: 3)
            + activeWeek(weeksAgo: 2, days: 3)
        XCTAssertEqual(chain(journal), 2)
    }

    /// …and the moment this week reaches the goal, it joins the chain without waiting for Sunday.
    func testTheCurrentWeekCountsAsSoonAsItMeetsTheGoal() {
        let journal = activeWeek(weeksAgo: 0, days: 3) + activeWeek(weeksAgo: 1, days: 3)
        XCTAssertEqual(chain(journal), 2)
    }

    /// Round 3's auto repair: one missed week between two counted weeks keeps the chain alive. The
    /// bridged week adds nothing to the length — round 8's *"none tallies what was missed"* cuts
    /// both ways: it does not shame the gap, and it does not claim the gap was done either.
    func testOneMissedWeekIsRepairedAndBridgesWithoutCounting() {
        let journal = activeWeek(weeksAgo: 1, days: 3) + activeWeek(weeksAgo: 2, days: 2)
            + activeWeek(weeksAgo: 3, days: 3)
        XCTAssertEqual(chain(journal), 2)
    }

    /// The repair keeps a chain going when LAST week was the miss — the case it exists for.
    func testLastWeeksMissIsRepairedWhileThisWeekIsUnderway() {
        let journal = activeWeek(weeksAgo: 2, days: 3) + activeWeek(weeksAgo: 3, days: 3)
        XCTAssertEqual(chain(journal), 2)
    }

    /// Reversed from `testStreak_gapBreaksTheChain`: two missed weeks in a row are not a repair.
    func testTwoMissedWeeksInARowEndTheChain() {
        let journal = activeWeek(weeksAgo: 1, days: 3) + activeWeek(weeksAgo: 4, days: 3)
            + activeWeek(weeksAgo: 5, days: 3)
        XCTAssertEqual(chain(journal), 1)
    }

    /// Reversed from `testStreak_deadWhenLastClosureIsTwoDaysBack`: with nothing counted for two
    /// full weeks there is no chain, however long the one before it was.
    func testAChainLastMetThreeWeeksAgoIsGone() {
        let journal = activeWeek(weeksAgo: 3, days: 3) + activeWeek(weeksAgo: 4, days: 3)
        XCTAssertEqual(chain(journal), 0)
    }

    /// "One missed week a MONTH": a second miss inside the same rolling four weeks is a break.
    func testASecondMissInsideTheFourWeekWindowIsNotRepaired() {
        let journal = activeWeek(weeksAgo: 1, days: 3) + activeWeek(weeksAgo: 3, days: 3)
            + activeWeek(weeksAgo: 5, days: 3)
        // Week 2 bridged; week 4 is only two weeks after that repair.
        XCTAssertEqual(chain(journal), 2)
    }

    /// …but four weeks after a repair, the next miss is repaired again.
    func testMissesFourWeeksApartAreBothRepaired() {
        let met = [1, 3, 4, 5, 7]
        let journal = met.flatMap { activeWeek(weeksAgo: $0, days: 3) }
        XCTAssertEqual(chain(journal), 5, "misses at weeks 2 and 6 are four weeks apart")
    }

    /// The goal is the user's N: two days a week is a counted week at N = 2 and a miss at N = 3.
    func testTheWeeklyGoalDecidesWhichWeeksCount() {
        let journal = activeWeek(weeksAgo: 1, days: 2) + activeWeek(weeksAgo: 2, days: 2)
        XCTAssertEqual(chain(journal, goal: 2), 2)
        XCTAssertEqual(chain(journal, goal: 3), 0)
    }

    /// Whatever the stored goal says, the chain reads it inside 1…7 — a goal of 0 would make every
    /// empty week count, and 9 could never be met.
    func testTheGoalIsClampedIntoItsRange() {
        let journal = activeWeek(weeksAgo: 1, days: 1) + activeWeek(weeksAgo: 2, days: 7)
        XCTAssertEqual(chain(journal, goal: 0), 2, "0 reads as 1")
        XCTAssertEqual(chain(activeWeek(weeksAgo: 1, days: 7), goal: 9), 1, "9 reads as 7")
    }

    /// How many days of THIS week are active — E3's done-today line and E4's Week review read it.
    func testActiveDaysThisWeekCountsOnlyTheCurrentWeek() {
        let journal = activeWeek(weeksAgo: 0, days: 2) + activeWeek(weeksAgo: 1, days: 5)
        let days = WeeklyActiveChain.activeDays(.init(journalLines: journal), calendar: calendar)
        XCTAssertEqual(WeeklyActiveChain.activeDaysThisWeek(activeDays: days, asOf: now, calendar: calendar), 2)
    }
}
