//
//  HomeBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface `FirebaseHomeClientAdapter` uses. See `LifeAreaEditorBackingStore` for
/// why the seam exists and why it is one narrow protocol per adapter.
protocol HomeBackingStore {
    func fetchLifeAreas(includeArchived: Bool) async throws -> [LifeArea]
    func fetchOpenTaskSummaries() async throws -> [TaskSummary]
    func fetchTasks() async throws -> [TaskItem]
    /// One atomic batch write of the complete ordering — never N per-row updates (TRAP 2 in
    /// `HomeClientAdapting`).
    func reorderLifeAreas(orderedIds: [UUID]) async throws
}

extension FirebaseManager: HomeBackingStore {}
