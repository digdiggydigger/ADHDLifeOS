//
//  FirebaseTasksClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TasksClientAdapting` backed by Firestore through `TasksBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests).
struct FirebaseTasksClientAdapter: TasksClientAdapting {
    private let store: TasksBackingStore

    init(store: TasksBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func fetchLifeAreas() async throws -> [LifeArea] {
        try await store.fetchLifeAreas(includeArchived: true)
    }

    func fetchAllTasks() async throws -> [TaskItem] {
        try await store.fetchTasks()
    }

    func setStatus(taskId: UUID, status: TaskStatus) async throws {
        try await store.setTaskStatus(id: taskId, status: status, now: .now)
    }

    func deleteTask(taskId: UUID) async throws {
        try await store.deleteTask(id: taskId)
    }
}
