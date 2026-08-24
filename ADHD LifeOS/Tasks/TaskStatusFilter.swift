//
//  TaskStatusFilter.swift
//  ADHD LifeOS
//

import Foundation

enum TaskStatusFilterOption: String, CaseIterable, Identifiable, Sendable {
    /// The Concept C board (block M3): everything open plus today's closures, grouped by dueness
    /// rather than life area. First and default on the Tasks tab; `LifeAreaDetailView` offers only
    /// `standardOptions` — inside one area the bucket board has nothing extra to say.
    case momentum
    case open
    case done
    case all

    /// The pre-Momentum trio, for screens that filter without re-grouping.
    static let standardOptions: [TaskStatusFilterOption] = [.open, .done, .all]

    var id: String { rawValue }

    var label: String {
        switch self {
        case .momentum: return "Momentum"
        case .open: return "Open"
        case .done: return "Done"
        case .all: return "All"
        }
    }
}

enum TaskStatusFilter {
    static func filter(
        tasks: [TaskItem],
        by option: TaskStatusFilterOption,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> [TaskItem] {
        switch option {
        case .momentum:
            // What's moving today: open work plus today's closures as evidence. Yesterday's wins
            // belong to Done.
            return tasks.filter { task in
                if task.status == .open { return true }
                guard let completedAt = task.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: now)
            }
        case .open:
            return tasks.filter { $0.status == .open }
        case .done:
            return tasks.filter { $0.status == .done }
        case .all:
            return tasks
        }
    }
}
