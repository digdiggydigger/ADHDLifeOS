//
//  NudgeStreak.swift
//  ADHD LifeOS
//

import Foundation

/// Per-nudge streak arithmetic over the `completion_dates` stamps (F-V3-Nudges). Same honest
/// rules as the scoreboard's task streak: days, not events; an unfinished today never breaks a
/// run; nothing here ever counts a miss.
enum NudgeStreak {
    /// Which of the trailing seven days carry a completion — oldest first, the dot row.
    static func weekFlags(
        dates: [Date],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> [Bool] {
        let days = daySet(dates, calendar: calendar)
        let today = calendar.startOfDay(for: now)
        return (0..<7).reversed().compactMap { back in
            calendar.date(byAdding: .day, value: -back, to: today).map { days.contains($0) }
        }
    }

    /// Consecutive completion days ending today — or yesterday while today is still open.
    static func currentRun(
        dates: [Date],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let days = daySet(dates, calendar: calendar)
        let today = calendar.startOfDay(for: now)
        var cursor = days.contains(today)
            ? today
            : calendar.date(byAdding: .day, value: -1, to: today) ?? today
        var run = 0
        while days.contains(cursor) {
            run += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return run
    }

    /// The longest consecutive-day run anywhere in the stamps.
    static func bestRun(dates: [Date], calendar: Calendar = .current) -> Int {
        let days = daySet(dates, calendar: calendar)
        var best = 0
        for day in days {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day),
                  !days.contains(previous) else { continue }
            var run = 1
            var cursor = day
            while let next = calendar.date(byAdding: .day, value: 1, to: cursor), days.contains(next) {
                run += 1
                cursor = next
            }
            best = max(best, run)
        }
        return best
    }

    /// "6 of 7 days · best 12" — `nil` before the first completion, so old nudges show nothing
    /// rather than a wall of zeroes (the stamps only accrue going forward).
    static func line(
        dates: [Date],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> String? {
        guard !dates.isEmpty else { return nil }
        let week = weekFlags(dates: dates, asOf: now, calendar: calendar).filter { $0 }.count
        let current = currentRun(dates: dates, asOf: now, calendar: calendar)
        let best = max(bestRun(dates: dates, calendar: calendar), current)
        return "\(week) of 7 days · best \(best)"
    }

    /// **R-b: exactly seven.** Whether 14 and 21 also fire is E's call and is parked in the
    /// register; this is not "the run is at least seven".
    static let milestoneRun = 7

    /// Whether the "Done for now" that produced `after` is the one that LANDED the run on seven —
    /// E's second full-screen milestone (F3; F4 settled that it is the streak and not every
    /// dismissal).
    ///
    /// **A crossing, so both sides are needed, and that is not defensive coding.** `markFired`
    /// stamps a completion whenever it is called, including on a day that already has one, and
    /// `currentRun` counts DAYS — so a second Done for now on day seven leaves the run at seven.
    /// Reading `after` alone would celebrate on every extra tap for the rest of the day.
    static func landsOnSeven(
        before: [Date],
        after: [Date],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        let previous = currentRun(dates: before, asOf: now, calendar: calendar)
        let current = currentRun(dates: after, asOf: now, calendar: calendar)
        return previous < milestoneRun && current == milestoneRun
    }

    private static func daySet(_ dates: [Date], calendar: Calendar) -> Set<Date> {
        Set(dates.map { calendar.startOfDay(for: $0) })
    }
}
