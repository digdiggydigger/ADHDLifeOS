//
//  TaskListRefinement.swift
//  ADHD LifeOS
//

import Foundation

/// The Tasks screen's sort dropdown, ported from the web's `sortBy` select
/// (`TaskListView.tsx`): default order, urgency high→low, or due date soonest-first.
enum TaskSortOption: String, CaseIterable, Identifiable, Sendable {
    case standard
    case priority
    case dueDate

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: return "Default Order"
        case .priority: return "Priority (High → Low)"
        case .dueDate: return "Due Date"
        }
    }
}

/// Client-side refinement of the fetched task list — case-insensitive title search, an exact
/// priority filter, and the sort above — mirroring the web Tasks screen's `filteredTasks`
/// pipeline. Applied before `TaskGrouping`, so groups contain only matching tasks and keep the
/// chosen order within each group. Pure and total.
enum TaskListRefinement {
    static func apply(
        tasks: [TaskItem],
        searchText: String,
        priorityFilter: TaskPriority?,
        sort: TaskSortOption
    ) -> [TaskItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var refined = tasks

        if !query.isEmpty {
            refined = refined.filter { $0.title.localizedCaseInsensitiveContains(query) }
        }
        if let priorityFilter {
            refined = refined.filter { $0.priority == priorityFilter }
        }

        switch sort {
        case .standard:
            return refined
        case .priority:
            return stableSorted(refined) { rank($0.priority) < rank($1.priority) }
        case .dueDate:
            // The web's rule: undated tasks always sink below dated ones.
            return stableSorted(refined) { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case (nil, nil): return false
                case (nil, _): return false
                case (_, nil): return true
                case (let lhsDate?, let rhsDate?): return lhsDate < rhsDate
                }
            }
        }
    }

    /// `p1` is the highest urgency, so its rank is lowest (sorts first).
    private static func rank(_ priority: TaskPriority) -> Int {
        switch priority {
        case .p1: return 0
        case .p2: return 1
        case .p3: return 2
        case .p4: return 3
        }
    }

    /// `sorted(by:)` doesn't document stability; the index tiebreak makes equal-key tasks keep
    /// their incoming (default) order, which the sort tests assert.
    private static func stableSorted(
        _ tasks: [TaskItem],
        by areInIncreasingOrder: (TaskItem, TaskItem) -> Bool
    ) -> [TaskItem] {
        tasks.enumerated()
            .sorted { lhs, rhs in
                if areInIncreasingOrder(lhs.element, rhs.element) { return true }
                if areInIncreasingOrder(rhs.element, lhs.element) { return false }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
