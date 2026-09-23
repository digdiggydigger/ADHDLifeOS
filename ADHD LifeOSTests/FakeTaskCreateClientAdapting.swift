//
//  FakeTaskCreateClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Create only since `F-D1-ComposerBothDoors` pruned the seam's tag methods — the fake and the
/// protocol shrink together, never one without the other.
final class FakeTaskCreateClientAdapting: TaskCreateClientAdapting, @unchecked Sendable {
    var createTaskResult: Result<TaskItem, Error> = .success(
        TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: nil)
    )

    private(set) var createTaskCallCount = 0
    private(set) var lastCreateTaskInput: NormalizedCreateTaskInput?

    func createTask(_ input: NormalizedCreateTaskInput) async throws -> TaskItem {
        createTaskCallCount += 1
        lastCreateTaskInput = input
        return try createTaskResult.get()
    }
}
