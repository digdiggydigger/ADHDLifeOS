//
//  FocusAnalytics.swift
//  ADHD LifeOS
//

import Foundation

/// One day's worth of focus history, the unit both analytics charts plot.
struct FocusDayBucket: Identifiable, Equatable, Sendable {
    /// Start of the day, in the calendar the bucket was built with.
    let date: Date
    let focusedSeconds: Int
    let sessionCount: Int
    /// Sessions that ran their countdown all the way out (vs. stopped early).
    let completedCount: Int

    var id: Date { date }
    var focusedMinutes: Int { focusedSeconds / 60 }
}

/// Pure aggregation behind `WeeklyFocusSummaryWidget` and `ProductivityTrendChart`, ported from
/// the date-bucketing `useMemo` blocks in their React counterparts.
///
/// One deliberate improvement over the web: those components inferred focus minutes from task
/// fields (`focusMinutesLogged` / `focusMinutesTarget`, defaulting to a hardcoded 15) because the
/// prototype never recorded real sessions. This app does — `CompletedFocusSession` rows written
/// by `FocusSessionService` — so the charts plot measured time instead of an estimate.
enum FocusAnalytics {
    /// Monday-through-Sunday buckets for the calendar week containing `now` — the weekly widget's
    /// range. Always exactly 7 buckets, including days with no sessions.
    static func currentWeek(
        sessions: [CompletedFocusSession],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [FocusDayBucket] {
        // Foundation weekday is 1=Sunday...7=Saturday; the web used 0=Sunday. Both reduce to the
        // same "days since Monday" offset.
        let weekday = calendar.component(.weekday, from: now)
        let distanceToMonday = (weekday + 5) % 7
        let today = calendar.startOfDay(for: now)
        guard let monday = calendar.date(byAdding: .day, value: -distanceToMonday, to: today) else {
            return []
        }
        return buckets(from: monday, count: 7, sessions: sessions, calendar: calendar)
    }

    /// The trailing `days`-day window ending today (oldest first) — the trend chart's range.
    static func rollingDays(
        sessions: [CompletedFocusSession],
        days: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [FocusDayBucket] {
        guard days > 0 else { return [] }
        let today = calendar.startOfDay(for: now)
        guard let first = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return [] }
        return buckets(from: first, count: days, sessions: sessions, calendar: calendar)
    }

    private static func buckets(
        from start: Date,
        count: Int,
        sessions: [CompletedFocusSession],
        calendar: Calendar
    ) -> [FocusDayBucket] {
        // Group once, then look each day up — O(sessions + days) rather than a scan per day.
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.endedAt) }
        return (0..<count).compactMap { offset -> FocusDayBucket? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let onDay = grouped[day] ?? []
            return FocusDayBucket(
                date: day,
                focusedSeconds: onDay.reduce(0) { $0 + max(0, $1.focusedSeconds) },
                sessionCount: onDay.count,
                completedCount: onDay.filter(\.completedNaturally).count
            )
        }
    }

    static func totalFocusedSeconds(_ buckets: [FocusDayBucket]) -> Int {
        buckets.reduce(0) { $0 + $1.focusedSeconds }
    }

    static func totalSessions(_ buckets: [FocusDayBucket]) -> Int {
        buckets.reduce(0) { $0 + $1.sessionCount }
    }

    /// Days in the window with any focus time at all.
    static func activeDayCount(_ buckets: [FocusDayBucket]) -> Int {
        buckets.filter { $0.focusedSeconds > 0 }.count
    }

    /// Mean across **every** day in the window, including zero days — the honest "typical day"
    /// number, rather than one flattered by skipping rest days.
    static func dailyAverageSeconds(_ buckets: [FocusDayBucket]) -> Int {
        guard !buckets.isEmpty else { return 0 }
        return totalFocusedSeconds(buckets) / buckets.count
    }

    /// The single best day in the window; `nil` when nothing was logged at all.
    static func peakDay(_ buckets: [FocusDayBucket]) -> FocusDayBucket? {
        buckets.filter { $0.focusedSeconds > 0 }.max { $0.focusedSeconds < $1.focusedSeconds }
    }

    /// Consecutive days with focus, counting back from the newest bucket. A gap on the newest day
    /// alone doesn't end a streak that is otherwise alive — the day isn't over yet — so the count
    /// resumes from the day before.
    static func currentStreak(_ buckets: [FocusDayBucket]) -> Int {
        guard !buckets.isEmpty else { return 0 }
        var streak = 0
        var isFirst = true
        for bucket in buckets.reversed() {
            if bucket.focusedSeconds > 0 {
                streak += 1
            } else if isFirst {
                // today, still in progress — skip without breaking the streak
            } else {
                break
            }
            isFirst = false
        }
        return streak
    }

    /// Progress toward a daily-minutes goal across the window, clamped to 0...1.
    static func goalProgress(_ buckets: [FocusDayBucket], dailyGoalMinutes: Int) -> Double {
        guard dailyGoalMinutes > 0, !buckets.isEmpty else { return 0 }
        let goalSeconds = Double(dailyGoalMinutes * 60 * buckets.count)
        return min(1, max(0, Double(totalFocusedSeconds(buckets)) / goalSeconds))
    }
}
