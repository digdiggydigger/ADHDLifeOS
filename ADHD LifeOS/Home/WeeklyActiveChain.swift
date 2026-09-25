//
//  WeeklyActiveChain.swift
//  ADHD LifeOS
//
//  `F-E1-WeeklyChain` — the one streak E kept, and the rules it keeps by.
//
//  E's round 3, *"Streaks → 'Weekly chain + auto repair.'"*: *"A week 'counts' once the user is
//  active on N days they choose. One missed week a month is repaired automatically. The other two
//  streaks go."* Round 5b: N is *"3 days"* by default, and an active day is *"Anything that moves
//  life on. Closing a task, finishing a sprint, writing a journal line, or sorting a capture."*
//  Round 8: *"Every screen may show what was done; none tallies what was missed."*
//
//  **The rules, in the order the arithmetic applies them:**
//
//  1. A DAY is active when any of the four signals carries a stamp on it. Days, not items: three
//     closes and a journal line on one Tuesday are one active day.
//  2. A WEEK is the calendar's own (`dateInterval(of: .weekOfYear)`, so Monday-first wherever the
//     locale says so), and it counts once it holds at least N active days.
//  3. The CURRENT week never breaks the chain. It joins the moment it reaches N; until then it is
//     unfinished, not missed — the old daily streak's "an unfinished today is not a miss", one
//     level up.
//  4. Walking back, a missed week is REPAIRED when the week before it counted and no other repair
//     falls inside the same rolling four weeks — "one missed week a month". The newer side may be
//     this week, still underway: last week's miss is exactly the case a repair exists for. The record
//     left the repair PERIOD open; a rolling four-week window is the stated default (the
//     `F-E1-WeeklyChain` spec), because a calendar month would repair a miss on the 31st and another on
//     the 1st.
//  5. A repaired week BRIDGES but does not COUNT. Round 8's rule cuts both ways: the chain never
//     shames the gap, and it never claims the gap was done either.
//

import Foundation

enum WeeklyActiveChain {
    /// Round 5b's N.
    static let defaultGoal = 3
    /// The Settings Stepper's bounds, and the clamp every read applies.
    static let goalRange = 1...7
    /// "One missed week a month", as a rolling window of weeks.
    static let repairWindowWeeks = 4

    /// The four things that make a day count, reduced to their stamps. Every field defaults to
    /// empty so a screen supplies what it holds — Home all four, Tasks and Journal fewer — and a
    /// missing source can only ever UNDER-report (show "makes today count" on a day that already
    /// counts), never claim a day that did not happen.
    struct Signals: Equatable {
        var tasksClosed: [Date]
        var sprintsFinished: [Date]
        var capturesCleared: [Date]
        var journalLines: [Date]

        /// A task counts on its `completed_at`, and only while it is still done — a close that was
        /// undone (`F-C1`) belongs to no day. A sprint counts on `endedAt`, whether it ran its full
        /// length or was stopped: either way the time was spent on the task.
        init(
            tasks: [TaskItem] = [],
            sessions: [CompletedFocusSession] = [],
            capturesCleared: [Date] = [],
            journalLines: [Date] = []
        ) {
            tasksClosed = tasks.compactMap { task in
                task.status == .done ? task.completedAt : nil
            }
            sprintsFinished = sessions.map(\.endedAt)
            self.capturesCleared = capturesCleared
            self.journalLines = journalLines
        }

        var allStamps: [Date] { tasksClosed + sprintsFinished + capturesCleared + journalLines }
    }

    /// Every active day, as start-of-day dates.
    static func activeDays(_ signals: Signals, calendar: Calendar = .current) -> Set<Date> {
        Set(signals.allStamps.map { calendar.startOfDay(for: $0) })
    }

    /// Whether `day` is active — the question round 5b answers.
    static func isActiveDay(_ day: Date, signals: Signals, calendar: Calendar = .current) -> Bool {
        activeDays(signals, calendar: calendar).contains(calendar.startOfDay(for: day))
    }

    /// Round 8b's condition for "Close it — makes today count": nothing has counted today yet.
    static func hasCountedToday(_ signals: Signals, asOf now: Date = .now, calendar: Calendar = .current) -> Bool {
        isActiveDay(now, signals: signals, calendar: calendar)
    }

    /// Active days so far in the current calendar week.
    static func activeDaysThisWeek(
        activeDays: Set<Date>,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return activeDays.filter { week.contains($0) }.count
    }

    /// The chain, in counted weeks — rules 2 to 5 above.
    static func chainLength(
        activeDays: Set<Date>,
        goal: Int,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let goal = min(max(goal, goalRange.lowerBound), goalRange.upperBound)
        var perWeek: [Date: Int] = [:]
        for day in activeDays {
            guard let start = calendar.dateInterval(of: .weekOfYear, for: day)?.start else { continue }
            perWeek[start, default: 0] += 1
        }
        guard let earliest = perWeek.keys.min(),
              let current = calendar.dateInterval(of: .weekOfYear, for: now)?.start
        else { return 0 }

        func weekStart(_ weeksBack: Int) -> Date? {
            calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: current)
        }
        func counts(_ start: Date?) -> Bool {
            start.map { (perWeek[$0] ?? 0) >= goal } ?? false
        }

        var length = counts(current) ? 1 : 0
        var lastRepair: Int?
        var weeksBack = 1
        while let start = weekStart(weeksBack), start >= earliest {
            if counts(start) {
                length += 1
            } else {
                let repairFree = lastRepair.map { weeksBack - $0 >= repairWindowWeeks } ?? true
                guard repairFree, counts(weekStart(weeksBack + 1)) else { break }
                lastRepair = weeksBack
            }
            weeksBack += 1
        }
        return length
    }
}
