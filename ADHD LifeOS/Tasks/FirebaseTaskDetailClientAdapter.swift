//
//  FirebaseTaskDetailClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TaskDetailClientAdapting` backed by Firestore through `TaskDetailBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests). Update calls
/// write the delta then re-read the document, so the returned `TaskDetail` is the stored truth
/// (matching the old adapters, which returned the server's row from the PATCH response).
struct FirebaseTaskDetailClientAdapter: TaskDetailClientAdapting {
    private let store: TaskDetailBackingStore

    init(store: TaskDetailBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func fetchTask(id: UUID) async throws -> TaskDetail {
        try await store.fetchTaskDetail(id: id)
    }

    func fetchTagsForTask(taskId: UUID) async throws -> [Tag] {
        try await store.fetchTags(for: .task, parentId: taskId)
    }

    func fetchAllTags() async throws -> [Tag] {
        try await store.fetchTags()
    }

    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws -> TaskDetail {
        try await store.updateTask(id: id, payload: payload)
        return try await store.fetchTaskDetail(id: id)
    }

    func updateStatus(id: UUID, status: TaskStatus) async throws -> TaskDetail {
        try await store.setTaskStatus(id: id, status: status, now: .now)
        return try await store.fetchTaskDetail(id: id)
    }

    func deleteTask(id: UUID) async throws {
        try await store.deleteTask(id: id)
    }

    func createTag(name: String) async throws -> Tag {
        try await store.createTagDeduplicating(name: name)
    }

    func addTagToTask(taskId: UUID, tagId: UUID) async throws {
        try await store.addTagId(tagId, to: .task, parentId: taskId)
    }

    func removeTagFromTask(taskId: UUID, tagId: UUID) async throws {
        try await store.removeTagId(tagId, from: .task, parentId: taskId)
    }
}
