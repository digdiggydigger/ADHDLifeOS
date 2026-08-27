//
//  MomentumTaskContext.swift
//  ADHD LifeOS
//
//  The task detail's Momentum context (Concept C, S3): the consequence written on the close
//  button and the "Momentum here" area line. Pure strings over data the pushing screens already
//  hold — the detail never fetches history for a label.
//

import Foundation

enum MomentumTaskContext {
    struct Context: Equatable {
        let streak: Int
        /// "💼 Work: 2 of 3 closed this week. Last closed 2 days ago." — `nil` when the task has
        /// no resolvable area, or the caller had no history to offer.
        let areaLine: String?

        static let empty = Context(streak: 0, areaLine: nil)
    }

    /// S3's button: the consequence stated where the choice is made. No streak, no invented
    /// consequence. Only open tasks show the button — closing is one-way since F-V3-Tasks-rebuild
    /// (E's addendum removed Reopen everywhere), so there is no done-state label.
    static func closeButtonLabel(streak: Int) -> String {
        guard streak > 0 else { return "Close it" }
        return "Close it — keeps a \(streak)-day streak"
    }

    static func build(
        lifeAreaId: UUID?,
        tasks: [TaskItem],
        lifeAreas: [LifeArea],
        showStreaks: Bool,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> Context {
        Context(
            streak: showStreaks ? MomentumScoreboard.streak(tasks: tasks, asOf: now, calendar: calendar) : 0,
            areaLine: areaLine(
                lifeAreaId: lifeAreaId, tasks: tasks, lifeAreas: lifeAreas, asOf: now, calendar: calendar
            )
        )
    }

    private static func areaLine(
        lifeAreaId: UUID?,
        tasks: [TaskItem],
        lifeAreas: [LifeArea],
        asOf now: Date,
        calendar: Calendar
    ) -> String? {
        guard let lifeAreaId, let area = lifeAreas.first(where: { $0.id == lifeAreaId }) else { return nil }
        let areaTasks = tasks.filter { $0.lifeAreaId == area.id }
        let closedThisWeek = MomentumScoreboard.closedThisWeek(tasks: areaTasks, asOf: now, calendar: calendar)
        let open = areaTasks.filter { $0.status == .open }.count

        guard !closedThisWeek.isEmpty else {
            // Honest, not shaming: states the standstill and what is actually there.
            return "\(area.colour) \(area.name): nothing closed this week yet. "
                + "\(open) open."
        }
        let total = closedThisWeek.count + open
        let lastClosed = closedThisWeek.compactMap(\.completedAt).max().map {
            lastClosedPhrase(for: $0, asOf: now, calendar: calendar)
        } ?? ""
        return "\(area.colour) \(area.name): \(closedThisWeek.count) of \(total) closed this week.\(lastClosed)"
    }

    private static func lastClosedPhrase(for date: Date, asOf now: Date, calendar: Calendar) -> String {
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)
        ).day ?? 0
        switch days {
        case 0: return " Last closed today."
        case 1: return " Last closed yesterday."
        default: return " Last closed \(days) days ago."
        }
    }
}
