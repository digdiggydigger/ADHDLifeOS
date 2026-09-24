//
//  MomentumTaskBuckets.swift
//  ADHD LifeOS
//
//  The Tasks tab's Momentum grouping (Concept C, block M3; narrowed in F-V3-Tasks-rebuild):
//  dueness buckets instead of life areas — Due today (overdue folded in, the scoreboard's own
//  "due now" reading), Tomorrow, and the evidence pile, Closed today. The long tail — tasks due
//  beyond tomorrow, and undated tasks — is deliberately NOT on this board (E's b11 call): dense
//  rows made it the page's biggest overwhelm risk, so it renders only under the Open filter.
//  Reuses `LifeAreaTaskGroup` so the list renders these with the machinery it already has.
//
//  *Annotated by `F-D3-TasksAnytimeRow` (2026-09-24):* "undated tasks" no longer belongs to that
//  sentence; "tasks due beyond tomorrow" still does. Round 6 gave undated tasks a fourth bucket,
//  Anytime, LAST on the board and folded by default in `TaskListView` — *"the tail stays folded,
//  but a new task is visible where it was added."* Round 8b settled the scope so this could not
//  widen b11's exclusion by accident: *"Undated tasks already live in Anytime, and future-dated
//  tasks are untouched."*
//

import Foundation

enum MomentumTaskBuckets {
    private enum Bucket: String, CaseIterable {
        case dueToday
        case tomorrow
        case closedToday
        /// Undated open tasks (`F-D3`). LAST, so `allCases` renders it below the evidence pile.
        case anytime

        var title: String {
            switch self {
            case .dueToday: return "Due today"
            case .tomorrow: return "Tomorrow"
            case .closedToday: return "Closed today"
            case .anytime: return "Anytime"
            }
        }
    }

    /// The Anytime bucket's group id — the one string `TaskListView` folds on, spelled once so the
    /// bucket and the fold cannot drift apart (`F-D3-TasksAnytimeRow`).
    static let anytimeGroupId = "momentum-anytime"

    static func group(
        tasks: [TaskItem],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> [LifeAreaTaskGroup] {
        let today = calendar.startOfDay(for: now)
        var buckets: [Bucket: [TaskItem]] = [:]

        for task in tasks {
            guard let bucket = bucket(for: task, today: today, now: now, calendar: calendar) else { continue }
            buckets[bucket, default: []].append(task)
        }

        return Bucket.allCases.compactMap { bucket in
            guard let members = buckets[bucket], !members.isEmpty else { return nil }
            return LifeAreaTaskGroup(
                lifeAreaId: nil,
                lifeAreaName: "\(bucket.title) · \(members.count)",
                tasks: sorted(members),
                customId: "momentum-\(bucket.rawValue)"
            )
        }
    }

    /// "4 open · 1 overdue" — the v3 header's eyebrow. Overdue means an open task whose due
    /// day has passed; due-today is not yet a miss.
    static func headerLine(
        tasks: [TaskItem],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let today = calendar.startOfDay(for: now)
        let open = tasks.filter { $0.status != .done }
        let overdue = open.filter { task in
            guard let due = task.dueDate else { return false }
            return calendar.startOfDay(for: due) < today
        }
        return "\(open.count) open · \(overdue.count) overdue"
    }

    /// The v3 hue for a bucket's section header — warn for due-today, motion-blue for tomorrow,
    /// closure-green for closed-today. `nil` keeps the plain secondary voice.
    static func headerToneAssetName(customId: String?) -> String? {
        switch customId {
        case "momentum-dueToday": return "StateWarn"
        case "momentum-tomorrow": return "AccentColor"
        case "momentum-closedToday": return "StateGo"
        default: return nil
        }
    }

    private static func bucket(
        for task: TaskItem,
        today: Date,
        now: Date,
        calendar: Calendar
    ) -> Bucket? {
        if task.status == .done {
            // Only today's closures are today's evidence; older wins belong to the Done filter.
            guard let completedAt = task.completedAt,
                  calendar.isDate(completedAt, inSameDayAs: now) else { return nil }
            return .closedToday
        }
        // Undated tasks are the board's folded tail (`F-D3`, round 6); the Open filter still
        // lists them too.
        guard let due = task.dueDate else { return .anytime }
        let dueDay = calendar.startOfDay(for: due)
        if dueDay <= today { return .dueToday }
        // Computed off the injected clock — `isDateInTomorrow` reads the wall clock and would
        // make this untestable and wrong at any other `asOf`.
        if dueDay == calendar.date(byAdding: .day, value: 1, to: today) { return .tomorrow }
        // Due beyond tomorrow: Open holds this tail, and round 8b left it untouched — "future-dated
        // tasks are untouched" — so it is NOT Anytime.
        return nil
    }

    /// Urgency first; inside one priority the quick win leads — same reading as the scoreboard's
    /// best-next-move, so the board and the ring agree about what matters.
    private static func sorted(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.enumerated()
            .sorted { lhs, rhs in
                if lhs.element.priority != rhs.element.priority {
                    return rank(lhs.element.priority) < rank(rhs.element.priority)
                }
                let lhsEffort = lhs.element.focusDurationSeconds ?? Int.max
                let rhsEffort = rhs.element.focusDurationSeconds ?? Int.max
                if lhsEffort != rhsEffort { return lhsEffort < rhsEffort }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    private static func rank(_ priority: TaskPriority) -> Int {
        switch priority {
        case .p1: return 0
        case .p2: return 1
        case .p3: return 2
        case .p4: return 3
        }
    }
}
