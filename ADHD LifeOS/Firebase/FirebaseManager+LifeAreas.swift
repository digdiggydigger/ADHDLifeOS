//
//  FirebaseManager+LifeAreas.swift
//  ADHD LifeOS
//

import FirebaseFirestore
import Foundation

extension FirebaseManager {
    func fetchLifeAreas(includeArchived: Bool = false) async throws -> [LifeArea] {
        let areas = try await fetchAll(LifeArea.self, from: .lifeAreas, orderedBy: "sort_order")
        return includeArchived ? areas : areas.filter { !$0.archived }
    }

    /// Creates or fully overwrites one area — covers rename, recolour, and archive/unarchive.
    func saveLifeArea(_ area: LifeArea) async throws {
        try await save(area, id: area.id, in: .lifeAreas)
    }

    /// Partial update of one area. Named rather than letting callers reach the generic
    /// `update(id:fields:in:)` so `LifeAreaEditorBackingStore` cannot address another collection.
    func updateLifeArea(id: UUID, fields: [String: Any]) async throws {
        try await update(id: id, fields: fields, in: .lifeAreas)
    }

    /// Persists a Home-screen reorder as one atomic batch: each area's `sort_order` becomes its
    /// index in `orderedIds`.
    func reorderLifeAreas(orderedIds: [UUID]) async throws {
        // `firestoreBatch()`, not `firestore.batch()`: the client is file-private to
        // `FirebaseManager.swift`, and this method reached it directly while it still lived
        // there — against that file's own stated rule that "extension files that need
        // multi-document atomicity get a batch through this instead of direct client access".
        let batch = firestoreBatch()
        let areas = try collection(.lifeAreas)
        for (index, id) in orderedIds.enumerated() {
            batch.updateData(["sort_order": index], forDocument: areas.document(id.uuidString))
        }
        try await batch.commit()
        DataChangeSignal.post()
    }

    func deleteLifeArea(id: UUID) async throws {
        try await delete(id: id, from: .lifeAreas)
    }
}
