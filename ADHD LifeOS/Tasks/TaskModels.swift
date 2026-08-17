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

    enum CodingKeys: String, CodingKey {
        case id, title, status, priority
        case lifeAreaId = "life_area_id"
        case dueDate = "due_date"
    }
}

struct LifeAreaTaskGroup: Identifiable, Equatable, Sendable {
    let lifeAreaId: UUID?
    let lifeAreaName: String
    let tasks: [TaskItem]

    var id: String { lifeAreaId?.uuidString ?? "unassigned" }
}
