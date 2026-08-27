//
//  TasksBackingStore.swift
//  ADHD LifeOS
//

import Foundation

/// The Firestore surface `FirebaseTasksClientAdapter` uses. See `LifeAreaEditorBackingStore` for
/// why the seam exists and why it is one narrow protocol per adapter.
///
/// `setTaskStatus` takes `now` explicitly rather than relying on `FirebaseManager`'s default
/// argument — a protocol requirement has to match arity, and passing the clock in is the better
/// shape anyway: the completion stamp is deliberately the client's clock, and a test can pin it.
protocol TasksBackingStore {
    func fetchLifeAreas(includeArchived: Bool) async throws -> [LifeArea]
    func fetchTasks() async throws -> [TaskItem]
    func setTaskStatus(id: UUID, status: TaskStatus, locationStamp: LocationStamp?, now: Date) async throws
}

extension FirebaseManager: TasksBackingStore {}
