//
//  FakeTaskCreateBackingStore.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Recording stand-in for the Firestore surface behind `FirebaseTaskCreateClientAdapter` — the
/// create alone since `F-D1-ComposerBothDoors` narrowed the store.
final class FakeTaskCreateBackingStore: TaskCreateBackingStore {
    var createTaskError: Error?

    private(set) var createdTasks: [TaskDetail] = []

    func createTask(_ task: TaskDetail) async throws {
        createdTasks.append(task)
        if let createTaskError { throw createTaskError }
    }
}
