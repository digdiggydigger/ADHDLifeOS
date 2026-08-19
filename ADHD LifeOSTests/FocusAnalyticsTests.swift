//
//  FocusAnalyticsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Covers the date-bucketing behind `WeeklyFocusSummaryWidget` and `ProductivityTrendChart`.
/// Everything runs against a fixed UTC calendar and a fixed `now`, so results never depend on the
/// machine's timezone or the day the suite happens to run.
final class FocusAnalyticsTests: XCTestCase {
    /// 2026-08-19 12:00 UTC — a Wednesday, so the Monday-anchored week has days on both sides.
    private let now = Date(timeIntervalSince1970: 1_787_140_800)

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func session(daysAgo: Int, minutes: Int, completed: Bool = true) -> CompletedFocusSession {
        let ended = utc.date(byAdding: .day, value: -daysAgo, to: now)!
        return CompletedFocusSession(
            id: UUID(), taskId: UUID(), taskTitle: "Sprint", lifeAreaEmoji: "💼",
            plannedSeconds: minutes * 60, focusedSeconds: minutes * 60,
            checkpointsReached: 1, completedNaturally: completed,
            startedAt: ended.addingTimeInterval(TimeInterval(-minutes * 60)), endedAt: ended
        )
    }

    // MARK: - Week bucketing

    func testCurrentWeek_hasSevenDaysStartingMonday() {
        let buckets = FocusAnalytics.currentWeek(sessions: [], now: now, calendar: utc)

        XCTAssertEqual(buckets.count, 7)
        XCTAssertEqual(utc.component(.weekday, from: buckets[0].date), 2, "Gregorian weekday 2 == Monday")
        XCTAssertEqual(utc.component(.weekday, from: buckets[6].date), 1, "…through Sunday")
    }

    func testCurrentWeek_bucketsSessionsIntoTheirOwnDay() {
        // `now` is Wednesday: today and two days back are all inside this week.
        let sessions = [
            session(daysAgo: 0, minutes: 25),
            session(daysAgo: 0, minutes: 35),
            session(daysAgo: 2, minutes: 40)
        ]

        let buckets = FocusAnalytics.currentWeek(sessions: sessions, now: now, calendar: utc)

        XCTAssertEqual(buckets[0].focusedSeconds, 40 * 60, "Monday holds the two-days-ago session")
        XCTAssertEqual(buckets[2].focusedSeconds, 60 * 60, "Wednesday sums both of today's sessions")
        XCTAssertEqual(buckets[2].sessionCount, 2)
        XCTAssertEqual(buckets[1].focusedSeconds, 0, "an untouched day still gets a zero bucket")
    }

    func testCurrentWeek_excludesSessionsOutsideTheWeek() {
        let buckets = FocusAnalytics.currentWeek(
            sessions: [session(daysAgo: 10, minutes: 90)], now: now, calendar: utc
        )

        XCTAssertEqual(FocusAnalytics.totalFocusedSeconds(buckets), 0)
    }

    // MARK: - Rolling window

    func testRollingDays_endsTodayAndCountsBack() {
        let buckets = FocusAnalytics.rollingDays(sessions: [], days: 7, now: now, calendar: utc)

        XCTAssertEqual(buckets.count, 7)
        XCTAssertEqual(buckets.last?.date, utc.startOfDay(for: now), "newest bucket is today")
        XCTAssertEqual(buckets.first?.date, utc.date(byAdding: .day, value: -6, to: utc.startOfDay(for: now)))
    }

    func testRollingDays_includesSixDaysAgoButNotSeven() {
        let sessions = [session(daysAgo: 6, minutes: 20), session(daysAgo: 7, minutes: 99)]

        let buckets = FocusAnalytics.rollingDays(sessions: sessions, days: 7, now: now, calendar: utc)

        XCTAssertEqual(FocusAnalytics.totalFocusedSeconds(buckets), 20 * 60)
    }

    func testRollingDays_zeroOrNegative_isEmpty() {
        XCTAssertTrue(FocusAnalytics.rollingDays(sessions: [], days: 0, now: now, calendar: utc).isEmpty)
        XCTAssertTrue(FocusAnalytics.rollingDays(sessions: [], days: -3, now: now, calendar: utc).isEmpty)
    }

    // MARK: - Aggregates

    private func week(_ minutesPerDayAgo: [Int: Int]) -> [FocusDayBucket] {
        let sessions = minutesPerDayAgo.map { session(daysAgo: $0.key, minutes: $0.value) }
        return FocusAnalytics.rollingDays(sessions: sessions, days: 7, now: now, calendar: utc)
    }

    func testTotalsAndActiveDays() {
        let buckets = week([0: 30, 1: 45, 3: 15])

        XCTAssertEqual(FocusAnalytics.totalFocusedSeconds(buckets), 90 * 60)
        XCTAssertEqual(FocusAnalytics.totalSessions(buckets), 3)
        XCTAssertEqual(FocusAnalytics.activeDayCount(buckets), 3)
    }

    func testDailyAverage_spreadsAcrossEveryDayIncludingRestDays() {
        let buckets = week([0: 70, 1: 70])

        // 140 minutes over a 7-day window = 20 minutes/day, not 70.
        XCTAssertEqual(FocusAnalytics.dailyAverageSeconds(buckets), 20 * 60)
    }

    func testDailyAverage_emptyWindow_isZero() {
        XCTAssertEqual(FocusAnalytics.dailyAverageSeconds([]), 0)
    }

    func testPeakDay_findsTheBusiestDay() {
        let buckets = week([0: 30, 2: 95, 4: 60])

        XCTAssertEqual(FocusAnalytics.peakDay(buckets)?.focusedSeconds, 95 * 60)
    }

    func testPeakDay_noSessions_isNil() {
        XCTAssertNil(FocusAnalytics.peakDay(week([:])))
    }

    func testCurrentStreak_countsConsecutiveDaysBackFromToday() {
        XCTAssertEqual(FocusAnalytics.currentStreak(week([0: 10, 1: 10, 2: 10])), 3)
    }

    func testCurrentStreak_brokenByAGapDay() {
        XCTAssertEqual(FocusAnalytics.currentStreak(week([0: 10, 1: 10, 3: 10])), 2)
    }

    func testCurrentStreak_todayStillEmpty_doesNotBreakYesterdaysStreak() {
        // The day isn't over, so an unfocused today shouldn't zero a live streak.
        XCTAssertEqual(FocusAnalytics.currentStreak(week([1: 10, 2: 10])), 2)
    }

    func testCurrentStreak_noHistory_isZero() {
        XCTAssertEqual(FocusAnalytics.currentStreak(week([:])), 0)
        XCTAssertEqual(FocusAnalytics.currentStreak([]), 0)
    }

    // MARK: - Goal progress

    func testGoalProgress_partialAndComplete() {
        // 7 days × 30m goal = 210m. 105m logged = 50%.
        XCTAssertEqual(FocusAnalytics.goalProgress(week([0: 105]), dailyGoalMinutes: 30), 0.5, accuracy: 0.001)
        XCTAssertEqual(FocusAnalytics.goalProgress(week([0: 210]), dailyGoalMinutes: 30), 1.0, accuracy: 0.001)
    }

    func testGoalProgress_clampsAtOneHundredPercent() {
        XCTAssertEqual(FocusAnalytics.goalProgress(week([0: 1000]), dailyGoalMinutes: 30), 1.0, accuracy: 0.001)
    }

    func testGoalProgress_zeroGoalOrEmptyWindow_isZero() {
        XCTAssertEqual(FocusAnalytics.goalProgress(week([0: 60]), dailyGoalMinutes: 0), 0)
        XCTAssertEqual(FocusAnalytics.goalProgress([], dailyGoalMinutes: 30), 0)
    }

    // MARK: - Duration formatting

    func testDurationFormatting() {
        XCTAssertEqual(FocusTimeFormatting.duration(seconds: 0), "0m")
        XCTAssertEqual(FocusTimeFormatting.duration(seconds: 59), "0m")
        XCTAssertEqual(FocusTimeFormatting.duration(seconds: 45 * 60), "45m")
        XCTAssertEqual(FocusTimeFormatting.duration(seconds: 60 * 60), "1h")
        XCTAssertEqual(FocusTimeFormatting.duration(seconds: 85 * 60), "1h 25m")
        XCTAssertEqual(FocusTimeFormatting.duration(seconds: -30), "0m")
    }
}
