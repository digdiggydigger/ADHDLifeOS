//
//  FirebaseTasksClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TasksClientAdapting` backed by Firestore via `FirebaseManager`.
struct FirebaseTasksClientAdapter: TasksClientAdapting {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    func fetchLifeAreas() async throws -> [LifeArea] {
        try await manager.fetchLifeAreas(includeArchived: true)
    }

    func fetchAllTasks() async throws -> [TaskItem] {
        try await manager.fetchTasks()
    }
}
