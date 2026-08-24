//
//  FirebaseHomeClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `HomeClientAdapting` backed by Firestore through `HomeBackingStore`
/// (`FirebaseManager` in the app, a recording fake in tests). Honors both reorder
/// traps from the protocol: the complete ordering (active + archived) lands in ONE atomic batch
/// write, never N per-row updates — and there is no server-side `validate_reorder` anymore, so
/// completeness is the client's responsibility alone.
struct FirebaseHomeClientAdapter: HomeClientAdapting {
    private let store: HomeBackingStore

    init(store: HomeBackingStore = FirebaseManager.shared) {
        self.store = store
    }

    func fetchLifeAreas() async throws -> [LifeArea] {
        try await store.fetchLifeAreas(includeArchived: true)
    }

    func fetchOpenTasks() async throws -> [TaskSummary] {
        try await store.fetchOpenTaskSummaries()
    }

    func fetchAllTasks() async throws -> [TaskItem] {
        try await store.fetchTasks()
    }

    func reorder(order: [UUID]) async throws {
        try await store.reorderLifeAreas(orderedIds: order)
    }
}
