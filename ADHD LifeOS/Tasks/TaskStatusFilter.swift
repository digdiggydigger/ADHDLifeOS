//
//  TaskStatusFilter.swift
//  ADHD LifeOS
//

import Foundation

enum TaskStatusFilterOption: String, CaseIterable, Identifiable, Sendable {
    case open
    case done
    case all

    var id: String { rawValue }

    var label: String {
        switch self {
        case .open: return "Open"
        case .done: return "Done"
        case .all: return "All"
        }
    }
}

enum TaskStatusFilter {
    static func filter(tasks: [TaskItem], by option: TaskStatusFilterOption) -> [TaskItem] {
        switch option {
        case .open:
            return tasks.filter { $0.status == .open }
        case .done:
            return tasks.filter { $0.status == .done }
        case .all:
            return tasks
        }
    }
}
