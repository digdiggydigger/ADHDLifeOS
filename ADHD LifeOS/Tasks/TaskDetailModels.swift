//
//  TaskDetailModels.swift
//  ADHD LifeOS
//

import Foundation

struct TaskDetail: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var lifeAreaId: UUID?
    var title: String
    var notes: String?
    var status: TaskStatus
    var priority: TaskPriority
    var dueDate: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, notes, status, priority
        case lifeAreaId = "life_area_id"
        case dueDate = "due_date"
        case createdAt = "created_at"
    }
}

/// A partial update payload — mirrors web's `normalizeUpdateTaskInput`: only fields that
/// actually changed are populated, so `TaskDetailClientAdapting.updateTask` only ever sends
/// the delta, never the whole form. `title`/`priority` use a plain `Optional` where `nil`
/// means "unchanged" (neither is a nullable DB column). `notes`/`lifeAreaId`/`dueDate` are
/// nullable columns, so they need a nested optional to distinguish "unchanged" (outer `nil`)
/// from "explicitly cleared to null" (`.some(nil)`).
/// The edited field values a `TaskDetailView` stages before Save — bundled into one struct so
/// `TaskUpdateValidation.normalizeUpdateTaskInput` stays under SwiftLint's parameter-count limit.
struct TaskEditedFields: Equatable, Sendable {
    var title: String
    var notes: String
    var lifeAreaId: UUID?
    var priority: TaskPriority
    var dueDate: Date?
}

struct TaskUpdatePayload: Equatable, Sendable {
    var title: String?
    var notes: String??
    var lifeAreaId: UUID??
    var priority: TaskPriority?
    var dueDate: Date??

    var isEmpty: Bool {
        title == nil && notes == nil && lifeAreaId == nil && priority == nil && dueDate == nil
    }
}
