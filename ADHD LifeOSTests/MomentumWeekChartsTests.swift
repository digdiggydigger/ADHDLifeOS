//
//  MomentumWeekChartsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The pure arithmetic behind the concept's `chartsOn` weekly bars (Concept C, 2026-08-24):
/// closures per trailing day on Today, focus minutes per trailing day on Tasks, and the honest
/// captions under each. Same rolling seven-day window as everything else on the scoreboard.
final class MomentumWeekChartsTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.locale = Locale(identifier: "en_US")
        return cal
    }

    /// Friday 14 Aug 2026, 09:41 UTC — the shared mock clock, so the window runs Sat–Fri.
    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private func doneTask(daysAgo: Int) -> TaskItem {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        return TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Done", status: .done,
            priority: .p3, dueDate: nil, completedAt: day
        )
    }

    private func session(daysAgo: Int, focusedSeconds: Int, plannedSeconds: Int = 1500) -> CompletedFocusSession {
        let ended = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        return CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Sprint", lifeAreaEmoji: "💼",
            plannedSeconds: plannedSeconds, focusedSeconds: focusedSeconds,
            checkpointsReached: 0, completedNaturally: true,
            startedAt: ended.addingTimeInterval(-Double(focusedSeconds)), endedAt: ended
        )
    }

    // MARK: - Closures per day

    /// Oldest first, today last — the same left-to-right calendar read as the streak dot row.
    /// A closure eight days back is outside the rolling window and appears nowhere.
    func testClosedPerDay_bucketsTheTrailingSevenDays() {
        let counts = MomentumWeekCharts.closedPerDay(
            tasks: [doneTask(daysAgo: 0), doneTask(daysAgo: 0), doneTask(daysAgo: 6), doneTask(daysAgo: 8)],
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(counts, [1, 0, 0, 0, 0, 0, 2])
    }

    func testClosedPerDay_ignoresOpenAndStamplessTasks() {
        let open = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Open", status: .open,
            priority: .p3, dueDate: nil, completedAt: nil
        )

        XCTAssertEqual(
            MomentumWeekCharts.closedPerDay(tasks: [open], asOf: now, calendar: calendar),
            [0, 0, 0, 0, 0, 0, 0]
        )
    }

    // MARK: - Focus minutes per day

    /// Bucketed by when the sprint ENDED — the moment the minutes became real — and summed in
    /// whole minutes per day.
    func testFocusMinutesPerDay_bucketsByEndDay() {
        let counts = MomentumWeekCharts.focusMinutesPerDay(
            sessions: [
                session(daysAgo: 0, focusedSeconds: 600),
                session(daysAgo: 0, focusedSeconds: 900),
                session(daysAgo: 6, focusedSeconds: 1500),
                session(daysAgo: 7, focusedSeconds: 3000)
            ],
            asOf: now, calendar: calendar
        )

        XCTAssertEqual(counts, [25, 0, 0, 0, 0, 0, 25])
    }

    // MARK: - Bar fractions

    /// Heights are relative to the week's own best day; an all-zero week draws no bars rather
    /// than dividing by zero.
    func testBarFractions_normalizeToTheTallestBar() {
        XCTAssertEqual(MomentumWeekCharts.barFractions([1, 0, 4, 2]), [0.25, 0, 1, 0.5])
        XCTAssertEqual(MomentumWeekCharts.barFractions([0, 0, 0]), [0, 0, 0])
    }

    // MARK: - Captions

    /// "Sat–Fri, items closed. 25 focus minutes logged." — the day range names the window, and
    /// the focus minutes ride along as the counterweight, zero included (an honest zero).
    func testClosedCaption_namesTheWindowAndTheWeeksFocusMinutes() {
        XCTAssertEqual(
            MomentumWeekCharts.closedCaption(
                sessions: [session(daysAgo: 0, focusedSeconds: 1500), session(daysAgo: 8, focusedSeconds: 6000)],
                asOf: now, calendar: calendar
            ),
            "Sat–Fri, items closed. 25 focus minutes logged."
        )
        XCTAssertEqual(
            MomentumWeekCharts.closedCaption(sessions: [], asOf: now, calendar: calendar),
            "Sat–Fri, items closed. 0 focus minutes logged."
        )
    }

    /// "25 minutes logged against 50 targeted." — the staminaLine's honest pairing, minutes not
    /// percent. `nil` with no sprints in the window: nothing targeted means nothing to compare.
    func testFocusCaption_pairsLoggedAgainstTargeted() {
        XCTAssertEqual(
            MomentumWeekCharts.focusCaption(
                sessions: [
                    session(daysAgo: 1, focusedSeconds: 900, plannedSeconds: 1500),
                    session(daysAgo: 2, focusedSeconds: 600, plannedSeconds: 1500),
                    session(daysAgo: 8, focusedSeconds: 6000, plannedSeconds: 6000)
                ],
                asOf: now, calendar: calendar
            ),
            "25 minutes logged against 50 targeted."
        )
        XCTAssertNil(MomentumWeekCharts.focusCaption(sessions: [], asOf: now, calendar: calendar))
    }
}
