//
//  FirebaseHomeClientAdapter.swift
//  ADHD LifeOS
//

import Foundation

/// Production `HomeClientAdapting` backed by Firestore via `FirebaseManager`. Honors both reorder
/// traps from the protocol: the complete ordering (active + archived) lands in ONE atomic batch
/// write, never N per-row updates — and there is no server-side `validate_reorder` anymore, so
/// completeness is the client's responsibility alone.
struct FirebaseHomeClientAdapter: HomeClientAdapting {
    private let manager: FirebaseManager

    init(manager: FirebaseManager = .shared) {
        self.manager = manager
    }

    func fetchLifeAreas() async throws -> [LifeArea] {
        try await manager.fetchLifeAreas(includeArchived: true)
    }

    func fetchOpenTasks() async throws -> [TaskSummary] {
        try await manager.fetchOpenTaskSummaries()
    }

    func reorder(order: [UUID]) async throws {
        try await manager.reorderLifeAreas(orderedIds: order)
    }
}
