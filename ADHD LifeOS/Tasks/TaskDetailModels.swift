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
    /// Per-task focus-sprint config; `nil` on pre-existing documents (see `TaskItem`).
    var focusDurationSeconds: Int?
    var nudgesCount: Int?
    /// WHERE this task was closed — same contract as `TaskItem`'s copy of the trio.
    var placeId: UUID?
    var latitude: Double?
    var longitude: Double?

    init(
        id: UUID,
        lifeAreaId: UUID?,
        title: String,
        notes: String?,
        status: TaskStatus,
        priority: TaskPriority,
        dueDate: Date?,
        createdAt: Date,
        focusDurationSeconds: Int? = nil,
        nudgesCount: Int? = nil,
        placeId: UUID? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.lifeAreaId = lifeAreaId
        self.title = title
        self.notes = notes
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.focusDurationSeconds = focusDurationSeconds
        self.nudgesCount = nudgesCount
        self.placeId = placeId
        self.latitude = latitude
        self.longitude = longitude
    }

    enum CodingKeys: String, CodingKey {
        case id, title, notes, status, priority, latitude, longitude
        case lifeAreaId = "life_area_id"
        case dueDate = "due_date"
        case createdAt = "created_at"
        case focusDurationSeconds = "focus_duration_seconds"
        case nudgesCount = "nudges_count"
        case placeId = "place_id"
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
    /// Staged focus-sprint config. `nil` = the control was never rendered/touched (older call
    /// sites), which normalization treats as "unchanged"; the detail view always stages the
    /// concrete resolved values.
    var focusDurationSeconds: Int?
    var nudgesCount: Int?

    init(
        title: String,
        notes: String,
        lifeAreaId: UUID?,
        priority: TaskPriority,
        dueDate: Date?,
        focusDurationSeconds: Int? = nil,
        nudgesCount: Int? = nil
    ) {
        self.title = title
        self.notes = notes
        self.lifeAreaId = lifeAreaId
        self.priority = priority
        self.dueDate = dueDate
        self.focusDurationSeconds = focusDurationSeconds
        self.nudgesCount = nudgesCount
    }
}

struct TaskUpdatePayload: Equatable, Sendable {
    var title: String?
    var notes: String??
    var lifeAreaId: UUID??
    var priority: TaskPriority?
    var dueDate: Date??
    /// Plain optionals (nil = unchanged) — the focus config is never cleared back to null, only
    /// overwritten with a concrete value, matching `title`/`priority`.
    var focusDurationSeconds: Int?
    var nudgesCount: Int?

    var isEmpty: Bool {
        title == nil && notes == nil && lifeAreaId == nil && priority == nil && dueDate == nil
            && focusDurationSeconds == nil && nudgesCount == nil
    }
}
