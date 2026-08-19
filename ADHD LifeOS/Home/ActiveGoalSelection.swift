//
//  ActiveGoalSelection.swift
//  ADHD LifeOS
//

import Foundation

/// Which single task Home's "Active Goal" hero headlines — the web's
/// `openTasks.find(t => t.priority === 'high') || openTasks[0]` (`HomeView.tsx`), made
/// deterministic: the web relied on array order, but our open-tasks query is unsorted (an
/// `order(by:)` on a `whereField` query needs a composite index), so ties break explicitly —
/// highest urgency band, then earliest due date (undated last), then stable input order.
/// Pure and total. Unlike the web, no placeholder task is fabricated when the list is empty:
/// the hero simply hides.
enum ActiveGoalSelection {
    static func topTask(in tasks: [TaskSummary]) -> TaskSummary? {
        tasks.enumerated()
            .filter { $0.element.status == .open }
            .min { lhs, rhs in
                if lhs.element.priority != rhs.element.priority {
                    return rank(lhs.element.priority) < rank(rhs.element.priority)
                }
                switch (lhs.element.dueDate, rhs.element.dueDate) {
                case (nil, nil): break
                case (nil, _): return false
                case (_, nil): return true
                case (let lhsDate?, let rhsDate?) where lhsDate != rhsDate: return lhsDate < rhsDate
                default: break
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    /// `p1` is the highest urgency, so it ranks lowest (wins `min`).
    private static func rank(_ priority: TaskPriority) -> Int {
        switch priority {
        case .p1: return 0
        case .p2: return 1
        case .p3: return 2
        case .p4: return 3
        }
    }
}
