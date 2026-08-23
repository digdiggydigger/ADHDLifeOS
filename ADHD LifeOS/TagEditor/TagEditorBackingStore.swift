//
//  TagEditorBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface `FirebaseTagEditorClientAdapter` uses. See `LifeAreaEditorBackingStore`
/// for why the seam exists and why it is one narrow protocol per adapter.
///
/// `tagUsageCounts` replaces the old `GET /tags` server-computed `usageCount` with one read over
/// tasks + captures, and `removeTagEverywhere` is the cascade behind both merge (rewrite every
/// reference to the target) and delete (drop them).
protocol TagEditorBackingStore {
    func fetchTags() async throws -> [Tag]
    func tagUsageCounts() async throws -> [UUID: Int]
    func fetchTag(named name: String) async throws -> Tag?
    func renameTag(id: UUID, to name: String) async throws
    func removeTagEverywhere(_ tagId: UUID, replacingWith replacement: UUID?) async throws
    func saveTag(_ tag: Tag) async throws
}

extension FirebaseManager: TagEditorBackingStore {}
