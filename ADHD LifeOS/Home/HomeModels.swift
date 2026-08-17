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

struct TaskSummary: Codable, Equatable, Sendable {
    let lifeAreaId: UUID?
    let status: TaskStatus

    enum CodingKeys: String, CodingKey {
        case lifeAreaId = "life_area_id"
        case status
    }
}

struct LifeAreaTaskCount: Identifiable, Equatable, Sendable {
    let lifeArea: LifeArea
    let openTaskCount: Int

    var id: UUID { lifeArea.id }
}
