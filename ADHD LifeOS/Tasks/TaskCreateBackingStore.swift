//
//  TaskCreateBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface `FirebaseTaskCreateClientAdapter` uses. See `LifeAreaEditorBackingStore`
/// for why the seam exists and why it is one narrow protocol per adapter.
protocol TaskCreateBackingStore {
    func fetchTags() async throws -> [Tag]
    func createTagDeduplicating(name: String) async throws -> Tag
    func createTask(_ task: TaskDetail) async throws
    func addTagId(_ tagId: UUID, to parent: FirebaseTagParent, parentId: UUID) async throws
}

extension FirebaseManager: TaskCreateBackingStore {}
