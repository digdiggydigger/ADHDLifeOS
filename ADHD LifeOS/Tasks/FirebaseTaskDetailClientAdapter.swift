//
//  FirebaseTaskDetailClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TaskDetailClientAdapting` backed by Firestore via `FirebaseManager`. Update calls
/// write the delta then re-read the document, so the returned `TaskDetail` is the stored truth
/// (matching the old adapters, which returned the server's row from the PATCH response).
struct FirebaseTaskDetailClientAdapter: TaskDetailClientAdapting {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    func fetchTask(id: UUID) async throws -> TaskDetail {
        try await manager.fetchTaskDetail(id: id)
    }

    func fetchTagsForTask(taskId: UUID) async throws -> [Tag] {
        try await manager.fetchTags(for: .task, parentId: taskId)
    }

    func fetchAllTags() async throws -> [Tag] {
        try await manager.fetchTags()
    }

    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws -> TaskDetail {
        try await manager.updateTask(id: id, payload: payload)
        return try await manager.fetchTaskDetail(id: id)
    }

    func updateStatus(id: UUID, status: TaskStatus) async throws -> TaskDetail {
        try await manager.setTaskStatus(id: id, status: status)
        return try await manager.fetchTaskDetail(id: id)
    }

    func createTag(name: String) async throws -> Tag {
        try await manager.createTagDeduplicating(name: name)
    }

    func addTagToTask(taskId: UUID, tagId: UUID) async throws {
        try await manager.addTagId(tagId, to: .task, parentId: taskId)
    }

    func removeTagFromTask(taskId: UUID, tagId: UUID) async throws {
        try await manager.removeTagId(tagId, from: .task, parentId: taskId)
    }
}
