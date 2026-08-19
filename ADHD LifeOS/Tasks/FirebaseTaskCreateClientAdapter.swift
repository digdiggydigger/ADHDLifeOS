//
//  FirebaseTaskCreateClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TaskCreateClientAdapting` backed by Firestore via `FirebaseManager`. Mirrors the
/// feature's two-step flow (create the task, then attach tags — no cross-document transaction),
/// and the old backend's tag dedup: `createTag` hands back the existing tag on a name match
/// instead of creating a duplicate.
struct FirebaseTaskCreateClientAdapter: TaskCreateClientAdapting {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    func fetchTags() async throws -> [Tag] {
        try await manager.fetchTags()
    }

    func createTag(name: String) async throws -> Tag {
        try await manager.createTagDeduplicating(name: name)
    }

    func createTask(_ input: NormalizedCreateTaskInput) async throws -> TaskItem {
        let task = TaskDetail(
            id: UUID(),
            lifeAreaId: input.lifeAreaId,
            title: input.title,
            notes: input.notes,
            status: .open,
            priority: input.priority,
            dueDate: input.dueDate,
            createdAt: Date()
        )
        try await manager.createTask(task)
        return TaskItem(
            id: task.id,
            lifeAreaId: task.lifeAreaId,
            title: task.title,
            status: task.status,
            priority: task.priority,
            dueDate: task.dueDate
        )
    }

    func attachTags(taskId: UUID, tagIds: [UUID]) async throws {
        for tagId in tagIds {
            try await manager.addTagId(tagId, to: .task, parentId: taskId)
        }
    }
}
