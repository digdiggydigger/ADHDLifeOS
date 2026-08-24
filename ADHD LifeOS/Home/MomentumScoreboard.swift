//
//  MomentumScoreboard.swift
//  ADHD LifeOS
//
//  The pure arithmetic behind Home's Momentum scoreboard (Concept C, 2026-08-24): closure ring,
//  streak, best-next-move and per-area weekly rates. Everything derives from fields the app
//  already stores — `completed_at` stamps and `focus_duration_seconds` — no new backend data.
//  Palette note: the original "structure only" call was superseded 2026-08-24 by E's v3
//  palette decision (Option A) — the views now render these numbers in the v3 State and Area
//  tokens (F-V3-Today).
//

import Foundation

enum MomentumScoreboard {
    /// The ring's denominator until the Momentum settings block makes it a persisted preference.
    static let defaultDailyGoal = 5

    /// Consecutive days with at least one closure, counting back from today — or from yesterday
    /// when today is still empty, because an unfinished day is not yet a miss. Days, not items:
    /// three closures on Tuesday are one day of streak. Honest-counterweight rule: a streak never
    /// counts a miss, it just stops.
    static func streak(tasks: [TaskItem], asOf now: Date = .now, calendar: Calendar = .current) -> Int {
        let closedDays = Set(
            tasks.compactMap { task -> Date? in
                guard task.status == .done, let completedAt = task.completedAt else { return nil }
                return calendar.startOfDay(for: completedAt)
            }
        )
        let today = calendar.startOfDay(for: now)
        var cursor = closedDays.contains(today)
            ? today
            : calendar.date(byAdding: .day, value: -1, to: today) ?? today
        var run = 0
        while closedDays.contains(cursor) {
            run += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return run
    }

    /// How full the closure ring draws. A non-positive goal degrades to "any closure fills it"
    /// rather than dividing by zero.
    static func ringProgress(closed: Int, goal: Int) -> Double {
        guard closed > 0 else { return 0 }
        guard goal > 0 else { return 1 }
        return min(Double(closed) / Double(goal), 1)
    }

    /// The one task Home leads with. Due-now (today or overdue) beats everything, and among those
    /// the SHORTEST estimated effort wins — the cheapest real win, not the scariest priority;
    /// unknown effort ranks last because it cannot be the promised fifteen minutes. With nothing
    /// due it falls back to the Active Goal rule so the card never goes blank while tasks are open.
    static func bestNextMove(
        in tasks: [TaskSummary],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> TaskSummary? {
        let today = calendar.startOfDay(for: now)
        let dueNow = tasks.enumerated().filter { entry in
            guard entry.element.status == .open, let due = entry.element.dueDate else { return false }
            return calendar.startOfDay(for: due) <= today
        }
        guard !dueNow.isEmpty else { return ActiveGoalSelection.topTask(in: tasks) }
        return dueNow
            .min { lhs, rhs in
                let lhsEffort = lhs.element.focusDurationSeconds ?? Int.max
                let rhsEffort = rhs.element.focusDurationSeconds ?? Int.max
                if lhsEffort != rhsEffort { return lhsEffort < rhsEffort }
                if lhs.element.priority != rhs.element.priority {
                    return priorityRank(lhs.element.priority) < priorityRank(rhs.element.priority)
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    /// An area's motion this week: closed over (closed + still open). `nil` when there is nothing
    /// to measure — a dormant area has no rate, which is not the same claim as 0%.
    static func areaRate(closedThisWeek: Int, open: Int) -> Double? {
        let total = closedThisWeek + open
        guard total > 0 else { return nil }
        return Double(closedThisWeek) / Double(total)
    }

    /// Closures in the trailing seven days including today — "this week" as a rolling window
    /// rather than a calendar week, so Monday morning doesn't wipe the board.
    static func closedThisWeek(
        tasks: [TaskItem],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> [TaskItem] {
        let today = calendar.startOfDay(for: now)
        guard let windowStart = calendar.date(byAdding: .day, value: -6, to: today) else { return [] }
        return tasks.filter { task in
            guard task.status == .done, let completedAt = task.completedAt else { return false }
            return completedAt >= windowStart
        }
    }

    /// One area's motion this week, for Today's life-area rows.
    struct AreaMomentum: Identifiable, Equatable {
        let area: LifeArea
        let closedThisWeek: Int
        let open: Int
        /// The area's most recent closure across ALL history (not just the week) — the honest
        /// input to the "quiet since …" clause. `nil` when nothing here has ever closed.
        let lastClosedAt: Date?
        var rate: Double? { MomentumScoreboard.areaRate(closedThisWeek: closedThisWeek, open: open) }
        var id: UUID { area.id }
    }

    /// The Areas-moving strip's data: each area's trailing-week closures and its current open
    /// count, in the caller's (sort-ordered) area order.
    static func areaMomentum(
        areas: [LifeArea],
        openTasks: [TaskSummary],
        allTasks: [TaskItem],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> [AreaMomentum] {
        let weekClosures = closedThisWeek(tasks: allTasks, asOf: now, calendar: calendar)
        return areas.map { area in
            AreaMomentum(
                area: area,
                closedThisWeek: weekClosures.filter { $0.lifeAreaId == area.id }.count,
                open: openTasks.filter { $0.lifeAreaId == area.id && $0.status == .open }.count,
                lastClosedAt: allTasks
                    .filter { $0.lifeAreaId == area.id && $0.status == .done }
                    .compactMap(\.completedAt)
                    .max()
            )
        }
    }

    /// Which of the trailing seven days saw a closure — oldest first, today last, the dot row
    /// under the streak.
    static func trailingWeekClosureFlags(
        tasks: [TaskItem],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> [Bool] {
        let today = calendar.startOfDay(for: now)
        let closedDays = Set(
            tasks.compactMap { task -> Date? in
                guard task.status == .done, let completedAt = task.completedAt else { return nil }
                return calendar.startOfDay(for: completedAt)
            }
        )
        return (0..<7).reversed().compactMap { back in
            calendar.date(byAdding: .day, value: -back, to: today).map { closedDays.contains($0) }
        }
    }

    /// Captures whose inbox-exit stamp is today — the ring's capture contribution when the
    /// Settings toggle counts them. Only the stamp counts: a processed capture with no
    /// `clearedAt` predates the stamp and belongs to no particular day.
    static func clearedToday(
        captures: [Capture],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        captures.filter { capture in
            guard let clearedAt = capture.clearedAt else { return false }
            return calendar.isDate(clearedAt, inSameDayAs: now)
        }.count
    }

    /// Nudges whose dismissal stamp is today — the ring's nudge contribution when the Settings
    /// toggle counts them (M9). `last_fired_at` doubles as the done-event stamp: only the
    /// Dismiss tap writes it, with the client clock, and a schedule fires at most once per day,
    /// so today's stamp means exactly one dismissal today. Deliberately ignores `active` — a
    /// nudge deactivated after its dismissal was still dismissed today.
    static func dismissedToday(
        nudges: [Nudge],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        nudges.filter { nudge in
            guard let lastFiredAt = nudge.lastFiredAt else { return false }
            return calendar.isDate(lastFiredAt, inSameDayAs: now)
        }.count
    }

    /// "15 min" — the effort chip, straight off `focus_duration_seconds`. Sub-minute targets
    /// round UP: "0 min" would promise less than tapping the button costs. `nil` effort renders
    /// no chip rather than inventing a number.
    static func effortLabel(seconds: Int?) -> String? {
        guard let seconds else { return nil }
        let minutes = max(1, Int((Double(seconds) / 60).rounded(.up)))
        return "\(minutes) min"
    }

    /// The longest run of consecutive closure days anywhere in history — derived, never stored,
    /// from the same `completed_at` stamps as the live streak (E's v3 call: ship it by deriving).
    static func bestStreak(tasks: [TaskItem], calendar: Calendar = .current) -> Int {
        let closedDays = Set(
            tasks.compactMap { task -> Date? in
                guard task.status == .done, let completedAt = task.completedAt else { return nil }
                return calendar.startOfDay(for: completedAt)
            }
        )
        var best = 0
        for day in closedDays {
            // Only run starts pay the walk, so the scan stays O(n) in closure days.
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day),
                  !closedDays.contains(previous) else { continue }
            var run = 1
            var cursor = day
            while let next = calendar.date(byAdding: .day, value: 1, to: cursor),
                  closedDays.contains(next) {
                run += 1
                cursor = next
            }
            best = max(best, run)
        }
        return best
    }

    /// The line beside the streak count. After a close it names the best-ever run (v3's
    /// "Streak kept. Best is 9.") — clamped so it never reads below the run you are on.
    static func streakLine(streak: Int, best: Int, closedToday: Int) -> String {
        if closedToday > 0, streak > 0 {
            return "Streak kept. Best is \(max(best, streak))."
        }
        return streak == 1
            ? "One day closed. Keep it alive today."
            : "\(streak) days closed in a row."
    }

    /// A life-area row's status line, tone included. The staleness clause only speaks from a real
    /// last-close stamp — an area that never closed anything is stated plainly, not shamed.
    enum AreaStatusTone: Equatable { case plain, clear, quiet }

    struct AreaStatusLine: Equatable {
        let text: String
        let tone: AreaStatusTone
    }

    static func areaStatusLine(
        closedThisWeek: Int,
        open: Int,
        lastClosedAt: Date?,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> AreaStatusLine {
        let total = closedThisWeek + open
        guard total > 0 else {
            return AreaStatusLine(text: "Nothing open or closed this week", tone: .plain)
        }
        if closedThisWeek == total {
            return AreaStatusLine(text: "\(closedThisWeek) of \(total) closed — all clear", tone: .clear)
        }
        if let lastClosedAt {
            let gap = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: lastClosedAt),
                to: calendar.startOfDay(for: now)
            ).day ?? 0
            if gap >= 7 {
                return AreaStatusLine(text: "\(closedThisWeek) of \(total) closed — quiet all week", tone: .quiet)
            }
            if gap > 3 {
                let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: lastClosedAt) - 1]
                return AreaStatusLine(
                    text: "\(closedThisWeek) of \(total) closed — quiet since \(weekday)", tone: .quiet
                )
            }
        }
        return AreaStatusLine(text: "\(closedThisWeek) of \(total) tasks closed", tone: .plain)
    }

    /// The moment-after-a-close line: the day's ordinal, then where that puts the area's week
    /// (v3's "Third today. Admin & Home is up to 75% this week.").
    static func celebrationLine(closedTodayCount: Int, areaName: String?, areaRate: Double?) -> String {
        let ordinal: String
        switch closedTodayCount {
        case 1: ordinal = "First today."
        case 2: ordinal = "Second today."
        case 3: ordinal = "Third today."
        default: ordinal = "\(closedTodayCount) closed today."
        }
        guard let areaName, let areaRate else { return ordinal }
        if areaRate >= 1 {
            return "\(ordinal) \(areaName) is all clear this week."
        }
        return "\(ordinal) \(areaName) is up to \(Int((areaRate * 100).rounded()))% this week."
    }

    /// The celebration card's second button: what the next move costs, if it names a cost.
    static func nextButtonLabel(effortSeconds: Int?) -> String {
        effortLabel(seconds: effortSeconds).map { "Next: \($0)" } ?? "Next"
    }

    private static func priorityRank(_ priority: TaskPriority) -> Int {
        switch priority {
        case .p1: return 0
        case .p2: return 1
        case .p3: return 2
        case .p4: return 3
        }
    }
}
