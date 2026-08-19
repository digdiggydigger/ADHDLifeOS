//
//  HomeModels.swift
//  ADHD LifeOS
//

import Foundation

struct LifeArea: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var colour: String
    var sortOrder: Int
    /// Whether the area is archived. `archived` moved onto the shared `LifeArea` (from the
    /// editor-only `EditableLifeArea`) in the Home-reorder block because four of the five picker
    /// sites plus Home now need it. Defaulted to `false` in the memberwise init so the many manual
    /// construction sites (adapters, previews, fakes) that predate it keep compiling.
    var archived: Bool

    init(id: UUID, name: String, colour: String, sortOrder: Int, archived: Bool = false) {
        self.id = id
        self.name = name
        self.colour = colour
        self.sortOrder = sortOrder
        self.archived = archived
    }

    enum CodingKeys: String, CodingKey {
        case id, name, colour, archived
        case sortOrder = "sort_order"
    }

    /// TRAP 4: never *encode* a `LifeArea`. `CodingKeys` maps `sortOrder` → `"sort_order"` (a
    /// Supabase leftover), while every AWS adapter bypasses `Codable` with a camelCase DTO — an
    /// encoded `LifeArea` would send `sort_order` and silently no-op against a backend reading
    /// `sortOrder`. The reorder request body is built from an explicit id-string `Encodable`, not
    /// from this type. Decoding is fine: a response without `archived` (the nine seeded rows
    /// predate the field) reads as `false`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        colour = try container.decode(String.self, forKey: .colour)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        archived = try container.decodeIfPresent(Bool.self, forKey: .archived) ?? false
    }
}

enum TaskStatus: String, Codable, Equatable, Sendable {
    case open
    case done
}

/// Home's projection of a task document. Originally just the badge-count pair
/// (`lifeAreaId` + `status`); widened for the Active Goal hero, which needs the headline task's
/// title, urgency, due date, notes and focus config — all decoded from the same open-tasks query,
/// no extra fetch. New fields default in the memberwise init so the many count-only construction
/// sites keep compiling.
struct TaskSummary: Codable, Equatable, Sendable {
    let id: UUID
    let lifeAreaId: UUID?
    let status: TaskStatus
    let title: String
    let priority: TaskPriority
    let notes: String?
    let dueDate: Date?
    let focusDurationSeconds: Int?
    let nudgesCount: Int?

    init(
        id: UUID = UUID(),
        lifeAreaId: UUID?,
        status: TaskStatus,
        title: String = "",
        priority: TaskPriority = .p3,
        notes: String? = nil,
        dueDate: Date? = nil,
        focusDurationSeconds: Int? = nil,
        nudgesCount: Int? = nil
    ) {
        self.id = id
        self.lifeAreaId = lifeAreaId
        self.status = status
        self.title = title
        self.priority = priority
        self.notes = notes
        self.dueDate = dueDate
        self.focusDurationSeconds = focusDurationSeconds
        self.nudgesCount = nudgesCount
    }

    enum CodingKeys: String, CodingKey {
        case id, status, title, priority, notes
        case lifeAreaId = "life_area_id"
        case dueDate = "due_date"
        case focusDurationSeconds = "focus_duration_seconds"
        case nudgesCount = "nudges_count"
    }
}

struct LifeAreaTaskCount: Identifiable, Equatable, Sendable {
    let lifeArea: LifeArea
    let openTaskCount: Int

    var id: UUID { lifeArea.id }
}
