//
//  MomentumWeekReview.swift
//  ADHD LifeOS
//
//  The week review (Concept C, S5 / block M6): evidence, not verdict. Derived locally, on
//  demand, from data Home already holds — closures, focus history, the inbox count. The
//  AI-written reflection stays the daily summary card's job (E's "both" call, 2026-08-24);
//  this screen is the numbers with their honest counterweights.
//

import Foundation

struct MomentumWeekReview: Equatable {
    /// "8 closed · 220 focus minutes"
    let headline: String
    /// Closures per trailing day, oldest first — the bars.
    let dayCounts: [Int]
    /// "Sat"…"Fri", aligned with `dayCounts`.
    let dayLabels: [String]
    /// The week's named wins, newest first, capped at three — a dopamine list, not a ledger.
    let dopamineWins: [String]
    /// "83% of targeted minutes actually logged" — `nil` with no sprints to measure.
    let staminaLine: String?
    /// Dormant areas and the unfiled pile, stated plainly — never scored. `nil` when everything
    /// moved and the inbox is clear.
    let quietLine: String?
    /// The two cheapest open tasks, effort-labelled — the shortest honest way into next week.
    let kickstart: [String]

    static func build(
        tasks: [TaskItem],
        lifeAreas: [LifeArea],
        sessions: [CompletedFocusSession],
        inboxCount: Int,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> MomentumWeekReview {
        let weekClosures = MomentumScoreboard.closedThisWeek(tasks: tasks, asOf: now, calendar: calendar)
        let weekSessions = sessions.filter { session in
            guard let windowStart = calendar.date(
                byAdding: .day, value: -6, to: calendar.startOfDay(for: now)
            ) else { return false }
            return session.endedAt >= windowStart
        }
        let focusMinutes = weekSessions.map(\.focusedSeconds).reduce(0, +) / 60

        return MomentumWeekReview(
            headline: "\(weekClosures.count) closed · \(focusMinutes) focus minutes",
            dayCounts: dayCounts(closures: weekClosures, asOf: now, calendar: calendar),
            dayLabels: dayLabels(asOf: now, calendar: calendar),
            dopamineWins: weekClosures
                .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
                .prefix(3)
                .map(\.title),
            staminaLine: staminaLine(for: weekSessions),
            quietLine: quietLine(
                closures: weekClosures, tasks: tasks, lifeAreas: lifeAreas,
                inboxCount: inboxCount
            ),
            kickstart: kickstart(tasks: tasks)
        )
    }

    private static func dayCounts(closures: [TaskItem], asOf now: Date, calendar: Calendar) -> [Int] {
        let today = calendar.startOfDay(for: now)
        return (0..<7).reversed().map { back in
            guard let day = calendar.date(byAdding: .day, value: -back, to: today) else { return 0 }
            return closures.filter { task in
                guard let completedAt = task.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: day)
            }.count
        }
    }

    private static func dayLabels(asOf now: Date, calendar: Calendar) -> [String] {
        let symbols = calendar.shortWeekdaySymbols
        let today = calendar.startOfDay(for: now)
        return (0..<7).reversed().compactMap { back in
            calendar.date(byAdding: .day, value: -back, to: today).map {
                symbols[calendar.component(.weekday, from: $0) - 1]
            }
        }
    }

    private static func staminaLine(for sessions: [CompletedFocusSession]) -> String? {
        let planned = sessions.map(\.plannedSeconds).reduce(0, +)
        guard planned > 0 else { return nil }
        let focused = sessions.map(\.focusedSeconds).reduce(0, +)
        let percent = Int((Double(focused) / Double(planned) * 100).rounded())
        return "\(percent)% of targeted minutes actually logged"
    }

    private static func quietLine(
        closures: [TaskItem],
        tasks: [TaskItem],
        lifeAreas: [LifeArea],
        inboxCount: Int
    ) -> String? {
        let movedAreaIds = Set(closures.compactMap(\.lifeAreaId))
        // Quiet = an active area with open work but no closure this week. An area with nothing in
        // it at all is dormant by choice, not stalled.
        let quietAreas = lifeAreas
            .filter { !$0.archived }
            .sorted { $0.sortOrder < $1.sortOrder }
            .filter { area in
                !movedAreaIds.contains(area.id)
                    && tasks.contains { $0.lifeAreaId == area.id && $0.status == .open }
            }
            .map(\.name)

        var clauses: [String] = []
        if !quietAreas.isEmpty {
            clauses.append("Nothing closed in \(quietAreas.joined(separator: " or ")) this week")
        }
        if inboxCount > 0 {
            clauses.append("\(inboxCount) \(inboxCount == 1 ? "capture is" : "captures are") still unfiled")
        }
        guard !clauses.isEmpty else { return nil }
        return clauses.joined(separator: ", and ")
            + ". Neither is a failure — they are just what next week starts with."
    }

    private static func kickstart(tasks: [TaskItem]) -> [String] {
        tasks
            .filter { $0.status == .open && $0.focusDurationSeconds != nil }
            .sorted { ($0.focusDurationSeconds ?? .max) < ($1.focusDurationSeconds ?? .max) }
            .prefix(2)
            .compactMap { task in
                MomentumScoreboard.effortLabel(seconds: task.focusDurationSeconds).map { "\($0) · \(task.title)" }
            }
    }
}
