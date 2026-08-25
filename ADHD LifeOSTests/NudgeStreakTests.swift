//
//  NudgeStreakTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Per-nudge streaks from the new `completion_dates` stamps (F-V3-Nudges — the data E authorised
/// so the v3 dots ship real): the trailing-week dot flags, the current and best consecutive-day
/// runs, and the "6 of 7 days · best 12" line.
final class NudgeStreakTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private func day(_ daysAgo: Int) -> Date {
        calendar.date(byAdding: .day, value: -daysAgo, to: now)!
    }

    func testWeekFlags_markCompletionDaysOldestFirst() {
        let flags = NudgeStreak.weekFlags(dates: [day(0), day(2), day(9)], asOf: now, calendar: calendar)
        XCTAssertEqual(flags, [false, false, false, false, true, false, true])
    }

    func testRuns_currentAndBest() {
        let dates = [day(0), day(1), day(2), day(10), day(11), day(12), day(13)]
        XCTAssertEqual(NudgeStreak.currentRun(dates: dates, asOf: now, calendar: calendar), 3)
        XCTAssertEqual(NudgeStreak.bestRun(dates: dates, calendar: calendar), 4)
    }

    func testCurrentRun_toleratesAnUnfinishedToday() {
        let dates = [day(1), day(2)]
        XCTAssertEqual(NudgeStreak.currentRun(dates: dates, asOf: now, calendar: calendar), 2)
    }

    func testScheduleSummary_readsAsPlainEnglish() {
        XCTAssertEqual(NudgeSchedule.summary(cronString: "0 21 * * *"), "Daily at 21:00")
        XCTAssertEqual(NudgeSchedule.summary(cronString: "30 9 * * 1,3"), "Mon, Wed at 09:30")
        XCTAssertNil(NudgeSchedule.summary(cronString: "not-cron"))
    }

    func testLine_countsTheWeekAndNamesTheBest() {
        let dates = [day(0), day(1), day(2), day(3), day(4), day(6)]
        XCTAssertEqual(
            NudgeStreak.line(dates: dates, asOf: now, calendar: calendar),
            "6 of 7 days · best 5"
        )
        XCTAssertNil(NudgeStreak.line(dates: [], asOf: now, calendar: calendar))
    }
}
