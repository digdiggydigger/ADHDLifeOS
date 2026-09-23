//
//  FirebaseTaskCreateClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TaskCreateClientAdapting` backed by Firestore through `TaskCreateBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests). Create only: the tag methods went
/// with the composer's tags in `F-D1-ComposerBothDoors`.
struct FirebaseTaskCreateClientAdapter: TaskCreateClientAdapting {
    private let store: TaskCreateBackingStore

    init(store: TaskCreateBackingStore = FirebaseManager.shared) {
        self.store = store
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
}
