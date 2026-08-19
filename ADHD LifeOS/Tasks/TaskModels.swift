//
//  TaskModels.swift
//  ADHD LifeOS
//

import Foundation

enum TaskPriority: String, Codable, Equatable, Sendable, CaseIterable {
    case p1
    case p2
    case p3
    case p4
}

struct TaskItem: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let lifeAreaId: UUID?
    var title: String
    var status: TaskStatus
    var priority: TaskPriority
    var dueDate: Date?
    /// Per-task focus-sprint config (web: `focusDurationSeconds` / `nudgesCount`). `nil` on
    /// documents written before the fields existed — resolved through
    /// `FocusSprintConfiguration`'s standard defaults wherever they're displayed or started.
    var focusDurationSeconds: Int?
    var nudgesCount: Int?

    init(
        id: UUID,
        lifeAreaId: UUID?,
        title: String,
        status: TaskStatus,
        priority: TaskPriority,
        dueDate: Date?,
        focusDurationSeconds: Int? = nil,
        nudgesCount: Int? = nil
    ) {
        self.id = id
        self.lifeAreaId = lifeAreaId
        self.title = title
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.focusDurationSeconds = focusDurationSeconds
        self.nudgesCount = nudgesCount
    }

    enum CodingKeys: String, CodingKey {
        case id, title, status, priority
        case lifeAreaId = "life_area_id"
        case dueDate = "due_date"
        case focusDurationSeconds = "focus_duration_seconds"
        case nudgesCount = "nudges_count"
    }
}

struct LifeAreaTaskGroup: Identifiable, Equatable, Sendable {
    let lifeAreaId: UUID?
    let lifeAreaName: String
    let tasks: [TaskItem]

    var id: String { lifeAreaId?.uuidString ?? "unassigned" }
}
