//
//  FirebaseTasksClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `TasksClientAdapting` backed by Firestore through `TasksBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests).
struct FirebaseTasksClientAdapter: TasksClientAdapting {
    private let store: TasksBackingStore
    /// Where the task was closed (block 3 remainder). Taken in the ADAPTER rather than in each
    /// caller, unlike captures: FOUR surfaces close a task (list swipe, detail, Home Momentum,
    /// life-area detail) and two of them are views with no service in between — one seam stamps
    /// them all. A closure so tests hand over a fixed stamp; the default's enabled-gate is the
    /// global Settings toggle (`RecordLocationStamp` — there is no per-task switch).
    private let locationStamp: @MainActor () async -> LocationStamp?

    init(
        store: TasksBackingStore = FirebaseManager.shared,
        locationStamp: (@MainActor () async -> LocationStamp?)? = nil
    ) {
        self.store = store
        self.locationStamp = locationStamp ?? { await RecordLocationStamp.current() }
    }

    func fetchLifeAreas() async throws -> [LifeArea] {
        try await store.fetchLifeAreas(includeArchived: true)
    }

    func fetchAllTasks() async throws -> [TaskItem] {
        try await store.fetchTasks()
    }

    func setStatus(taskId: UUID, status: TaskStatus) async throws {
        // Additive only: a nil stamp — tagging off, no permission, no fix — never blocks the
        // status write itself.
        let stamp = status == .done ? await locationStamp() : nil
        try await store.setTaskStatus(id: taskId, status: status, locationStamp: stamp, now: .now)
    }
}
