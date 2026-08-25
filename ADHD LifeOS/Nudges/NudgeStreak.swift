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

    private static func daySet(_ dates: [Date], calendar: Calendar) -> Set<Date> {
        Set(dates.map { calendar.startOfDay(for: $0) })
    }
}
