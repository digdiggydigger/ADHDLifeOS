//
//  MomentumTaskContext.swift
//  ADHD LifeOS
//
//  The task detail's Momentum context (Concept C, S3): the consequence written on the close
//  button and the "Momentum here" area line. Pure strings over data the pushing screens already
//  hold — the detail never fetches history for a label.
//
//  `F-E1-WeeklyChain` replaced the button's streak consequence with E's round-8b gain line, "Close
//  it — makes today count", shown only while today has no activity yet.
//

import Foundation

enum MomentumTaskContext {
    struct Context: Equatable {
        /// Whether today already counts toward the weekly chain — the CALLER's answer, carried
        /// as given: this type holds only tasks, and today may count on a journal line or a sorted
        /// capture it cannot see.
        let hasCountedToday: Bool
        /// Whether the chain is shown at all (Settings' `showStreaks`). The gain line speaks for
        /// the chain, so a hidden chain gets none.
        let showsChain: Bool
        /// "💼 Work: 2 of 3 closed this week. Last closed 2 days ago." — `nil` when the task has
        /// no resolvable area, or the caller had no history to offer.
        let areaLine: String?

        static let empty = Context(hasCountedToday: true, showsChain: false, areaLine: nil)

        /// The close button's title, as Task Detail renders it.
        var closeButtonTitle: String {
            MomentumTaskContext.closeButtonLabel(hasCountedToday: hasCountedToday || !showsChain)
        }
    }

    /// S3's button, reframed by E in round 8b: *"'Close it — makes today count'"* while today has
    /// no activity yet, otherwise plain "Close it" — *"framed as a gain toward the weekly chain,
    /// never a loss."* Only open tasks show the button, so there is no done-state label, and that
    /// is still true after `F-C1-UndoCapsule` retired "closing is one-way": the way back is the
    /// shared undo capsule, never a Reopen button on the closed state.
    static func closeButtonLabel(hasCountedToday: Bool) -> String {
        hasCountedToday ? "Close it" : "Close it — makes today count"
    }

    static func build(
        lifeAreaId: UUID?,
        tasks: [TaskItem],
        lifeAreas: [LifeArea],
        showStreaks: Bool,
        hasCountedToday: Bool,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> Context {
        Context(
            hasCountedToday: hasCountedToday,
            showsChain: showStreaks,
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
