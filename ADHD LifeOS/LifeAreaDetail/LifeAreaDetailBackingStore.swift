//
//  LifeAreaDetailBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface `FirebaseLifeAreaDetailClientAdapter` uses. See
/// `LifeAreaEditorBackingStore` for why the seam exists and why it is one narrow protocol per
/// adapter.
///
/// Both reads are scoped server-side by a `life_area_id` equality query, and both come back
/// unordered — a `whereField` combined with an order on a different field needs a composite index,
/// so callers sort.
protocol LifeAreaDetailBackingStore {
    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem]
    func fetchLogs(lifeAreaId: UUID) async throws -> [Log]
}

extension FirebaseManager: LifeAreaDetailBackingStore {}
