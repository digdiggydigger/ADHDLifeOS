//
//  MomentumWeekCharts.swift
//  ADHD LifeOS
//
//  The pure arithmetic behind the concept's `chartsOn` weekly bars (Concept C, 2026-08-24):
//  closures per trailing day on Today, focus minutes per trailing day on Tasks, and the honest
//  caption under each. Everything derives from data the app already stores — `completed_at`
//  stamps and completed focus sessions — over the same rolling seven-day window as the rest of
//  the scoreboard.
//

import Foundation

enum MomentumWeekCharts {
    /// Closures per trailing day including today, oldest first — the same left-to-right calendar
    /// read as the streak dot row.
    static func closedPerDay(
        tasks: [TaskItem],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> [Int] {
        trailingDays(asOf: now, calendar: calendar).map { day in
            tasks.filter { task in
                guard task.status == .done, let completedAt = task.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: day)
            }.count
        }
    }

    /// Focus minutes per trailing day, oldest first — bucketed by when the sprint ENDED, the
    /// moment its minutes became real, and summed in whole minutes per day.
    static func focusMinutesPerDay(
        sessions: [CompletedFocusSession],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> [Int] {
        trailingDays(asOf: now, calendar: calendar).map { day in
            sessions
                .filter { calendar.isDate($0.endedAt, inSameDayAs: day) }
                .map(\.focusedSeconds)
                .reduce(0, +) / 60
        }
    }

    /// Bar heights relative to the week's own best day. An all-zero week draws no bars rather
    /// than dividing by zero — the views hide the chart before it gets that far.
    static func barFractions(_ counts: [Int]) -> [Double] {
        guard let peak = counts.max(), peak > 0 else { return counts.map { _ in 0 } }
        return counts.map { Double($0) / Double(peak) }
    }

    /// "Sat–Fri, items closed. 220 focus minutes logged." — the day range names the window, and
    /// the week's focus minutes ride along as the counterweight, zero included (an honest zero).
    static func closedCaption(
        sessions: [CompletedFocusSession],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let minutes = weekSessions(sessions, asOf: now, calendar: calendar)
            .map(\.focusedSeconds)
            .reduce(0, +) / 60
        return "\(windowLabel(asOf: now, calendar: calendar)), items closed. \(minutes) focus minutes logged."
    }

    /// "220 minutes logged against 265 targeted." — the week review's stamina pairing, stated in
    /// minutes rather than a percent. `nil` with no sprints in the window: nothing was targeted,
    /// so there is nothing to compare, which is not the same claim as zero.
    static func focusCaption(
        sessions: [CompletedFocusSession],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> String? {
        let week = weekSessions(sessions, asOf: now, calendar: calendar)
        let planned = week.map(\.plannedSeconds).reduce(0, +)
        guard planned > 0 else { return nil }
        let focused = week.map(\.focusedSeconds).reduce(0, +)
        return "\(focused / 60) minutes logged against \(planned / 60) targeted."
    }

    private static func trailingDays(asOf now: Date, calendar: Calendar) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0..<7).reversed().compactMap { back in
            calendar.date(byAdding: .day, value: -back, to: today)
        }
    }

    private static func weekSessions(
        _ sessions: [CompletedFocusSession], asOf now: Date, calendar: Calendar
    ) -> [CompletedFocusSession] {
        let today = calendar.startOfDay(for: now)
        guard let windowStart = calendar.date(byAdding: .day, value: -6, to: today) else { return [] }
        return sessions.filter { $0.endedAt >= windowStart }
    }

    private static func windowLabel(asOf now: Date, calendar: Calendar) -> String {
        let symbols = calendar.shortWeekdaySymbols
        let today = calendar.startOfDay(for: now)
        guard let oldest = calendar.date(byAdding: .day, value: -6, to: today) else { return "" }
        let startLabel = symbols[calendar.component(.weekday, from: oldest) - 1]
        let endLabel = symbols[calendar.component(.weekday, from: today) - 1]
        return "\(startLabel)–\(endLabel)"
    }
}
