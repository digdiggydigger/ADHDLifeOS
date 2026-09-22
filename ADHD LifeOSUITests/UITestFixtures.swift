//
//  UITestFixtures.swift
//  ADHD LifeOSUITests
//
//  Firestore fixtures a journey writes BEFORE the app launches, on `UITestSession` so a second
//  journey class can reach them — the `scrollUntilHittable` / `openTab` move. `seedTask` lived on
//  `SignedInJourneyUITests` until F-TabDepth-2's journey needed a task with a known id from its
//  own class; that copy now delegates here rather than forking the field spelling.
//

import XCTest

extension UITestSession {
    /// Task documents are fully snake_cased (`life_area_id`, `created_at`) — see CLAUDE.md, where
    /// the tasks/captures casing split is spelled out. Document IDs are UPPERCASE `uuidString`.
    /// Due now, so the row renders on the Momentum board (F-V3-Tasks-rebuild: undated tasks
    /// appear only under the Open filter).
    static func seedTask(id: UUID, title: String, uid: String) throws {
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/tasks/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "title": UITestEmulator.string(title),
                "status": UITestEmulator.string("open"),
                "priority": UITestEmulator.string("p3"),
                "due_date": UITestEmulator.timestamp(Date()),
                "created_at": UITestEmulator.timestamp(Date())
            ]
        )
    }

    /// A task that already carries tags. Same spelling as `seedTask` plus `tag_ids`, which is
    /// snake_cased on BOTH collections — one of the few field names tasks and captures agree on.
    static func seedTask(id: UUID, title: String, uid: String, tagIds: [UUID]) throws {
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/tasks/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "title": UITestEmulator.string(title),
                "status": UITestEmulator.string("open"),
                "priority": UITestEmulator.string("p3"),
                "due_date": UITestEmulator.timestamp(Date()),
                "created_at": UITestEmulator.timestamp(Date()),
                "tag_ids": [
                    "arrayValue": ["values": tagIds.map { UITestEmulator.string($0.uuidString) }]
                ]
            ]
        )
    }

    /// A tag document. **`deleted_at` is snake_cased**, siding with tasks — `Tag.CodingKeys`, added
    /// by `F-C4-TagsRecentlyDeleted`, is the only place that convention is written down.
    static func seedTag(id: UUID, name: String, uid: String, deletedAt: Date? = nil) throws {
        var fields: [String: Any] = [
            "id": UITestEmulator.string(id.uuidString),
            "name": UITestEmulator.string(name)
        ]
        if let deletedAt {
            fields["deleted_at"] = UITestEmulator.timestamp(deletedAt)
        }
        try UITestEmulator.writeDocument(path: "users/\(uid)/tags/\(id.uuidString)", fields: fields)
    }
}
