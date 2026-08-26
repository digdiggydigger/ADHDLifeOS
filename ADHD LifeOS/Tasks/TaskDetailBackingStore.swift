//
//  TaskDetailBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface `FirebaseTaskDetailClientAdapter` uses. See `LifeAreaEditorBackingStore`
/// for why the seam exists and why it is one narrow protocol per adapter.
///
/// `setTaskStatus` takes `now` explicitly for the same reason as `TasksBackingStore`: a protocol
/// requirement has to match arity, and the completion stamp is deliberately the client's clock.
protocol TaskDetailBackingStore {
    func fetchTaskDetail(id: UUID) async throws -> TaskDetail
    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws
    func setTaskStatus(id: UUID, status: TaskStatus, now: Date) async throws
    func deleteTask(id: UUID) async throws
    func fetchTags() async throws -> [Tag]
    func createTagDeduplicating(name: String) async throws -> Tag
    func fetchTags(for parent: FirebaseTagParent, parentId: UUID) async throws -> [Tag]
    func addTagId(_ tagId: UUID, to parent: FirebaseTagParent, parentId: UUID) async throws
    func removeTagId(_ tagId: UUID, from parent: FirebaseTagParent, parentId: UUID) async throws
}

extension FirebaseManager: TaskDetailBackingStore {}
