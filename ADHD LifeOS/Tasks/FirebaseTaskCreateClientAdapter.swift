//
//  FirebaseTaskCreateClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TaskCreateClientAdapting` backed by Firestore through `TaskCreateBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests). Mirrors the
/// feature's two-step flow (create the task, then attach tags — no cross-document transaction),
/// and the old backend's tag dedup: `createTag` hands back the existing tag on a name match
/// instead of creating a duplicate.
struct FirebaseTaskCreateClientAdapter: TaskCreateClientAdapting {
    private let store: TaskCreateBackingStore

    init(store: TaskCreateBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func fetchTags() async throws -> [Tag] {
        try await store.fetchTags()
    }

    func createTag(name: String) async throws -> Tag {
        try await store.createTagDeduplicating(name: name)
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
            createdAt: Date(),
            atPlaceId: input.atPlaceId
        )
        try await store.createTask(task)
        return TaskItem(
            id: task.id,
            lifeAreaId: task.lifeAreaId,
            title: task.title,
            status: task.status,
            priority: task.priority,
            dueDate: task.dueDate,
            atPlaceId: task.atPlaceId
        )
    }

    func attachTags(taskId: UUID, tagIds: [UUID]) async throws {
        for tagId in tagIds {
            try await store.addTagId(tagId, to: .task, parentId: taskId)
        }
    }
}
