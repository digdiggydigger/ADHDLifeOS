//
//  FakeTaskCreateClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeTaskCreateClientAdapting: TaskCreateClientAdapting, @unchecked Sendable {
    var tagsResult: Result<[Tag], Error> = .success([])
    var createTagResult: Result<Tag, Error> = .success(Tag(id: UUID(), name: "new-tag"))
    var createTaskResult: Result<TaskItem, Error> = .success(
        TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: nil)
    )
    var attachTagsResult: Result<Void, Error> = .success(())

    private(set) var fetchTagsCallCount = 0
    private(set) var createTagCallCount = 0
    private(set) var createTaskCallCount = 0
    private(set) var attachTagsCallCount = 0
    private(set) var lastCreateTaskInput: NormalizedCreateTaskInput?
    private(set) var lastAttachTagsArguments: (taskId: UUID, tagIds: [UUID])?

    func fetchTags() async throws -> [Tag] {
        fetchTagsCallCount += 1
        return try tagsResult.get()
    }

    func createTag(name: String) async throws -> Tag {
        createTagCallCount += 1
        return try createTagResult.get()
    }

    func createTask(_ input: NormalizedCreateTaskInput) async throws -> TaskItem {
        createTaskCallCount += 1
        lastCreateTaskInput = input
        return try createTaskResult.get()
    }

    func attachTags(taskId: UUID, tagIds: [UUID]) async throws {
        attachTagsCallCount += 1
        lastAttachTagsArguments = (taskId, tagIds)
        _ = try attachTagsResult.get()
    }
}
