//
//  MomentumScoreboard.swift
//  ADHD LifeOS
//
//  The pure arithmetic behind Home's Momentum scoreboard (Concept C, 2026-08-24): closure ring,
//  best-next-move and per-area weekly rates. Everything derives from fields the app already
//  stores — `completed_at` stamps and `focus_duration_seconds` — no new backend data. The daily
//  streak, its best run and its line were retired by `F-E1-WeeklyChain` for E's weekly chain
//  (`WeeklyActiveChain`).
//  Palette note: the original "structure only" call was superseded 2026-08-24 by E's v3
//  palette decision (Option A) — the views now render these numbers in the v3 State and Area
//  tokens (F-V3-Today).
//

import Foundation

enum MomentumScoreboard {
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

    /// "2 sessions · 35 min today" — what the Best-next-move hero shows once focus has been
    /// logged against its task today (BUG-b10: a sprint that finished while the app was dead was
    /// recorded but INVISIBLE on Today). Sub-minute sessions still count — E's own repro was a
    /// 30-second sprint, and hiding it would make the fix look broken in the exact test that
    /// found the bug — but their minutes floor away rather than overstate ("1 session today").
    /// `nil` means nothing logged today and the hero stays exactly as it was.
    static func focusLoggedTodayLabel(
        sessions: [CompletedFocusSession],
        taskId: UUID,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> String? {
        let todays = sessions.filter { session in
            session.taskId == taskId && calendar.isDate(session.endedAt, inSameDayAs: now)
        }
        guard !todays.isEmpty else { return nil }
        let count = todays.count
        let sessionsPart = count == 1 ? "1 session" : "\(count) sessions"
        let minutes = todays.reduce(0) { $0 + $1.focusedSeconds } / 60
        guard minutes >= 1 else { return "\(sessionsPart) today" }
        return "\(sessionsPart) · \(minutes) min today"
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

    private static func priorityRank(_ priority: TaskPriority) -> Int {
        switch priority {
        case .p1: return 0
        case .p2: return 1
        case .p3: return 2
        case .p4: return 3
        }
    }
}
