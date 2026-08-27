//
//  FakeTaskDetailClientAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

final class FakeTaskDetailClientAdapting: TaskDetailClientAdapting, @unchecked Sendable {
    var fetchTaskResult: Result<TaskDetail, Error> = .success(
        TaskDetail(
            id: UUID(), lifeAreaId: nil, title: "Task", notes: nil,
            status: .open, priority: .p4, dueDate: nil, createdAt: Date()
        )
    )
    var fetchTagsForTaskResult: Result<[Tag], Error> = .success([])
    var fetchAllTagsResult: Result<[Tag], Error> = .success([])
    var updateTaskResult: Result<TaskDetail, Error>?
    var updateStatusResult: Result<TaskDetail, Error>?
    var createTagResult: Result<Tag, Error> = .success(Tag(id: UUID(), name: "new-tag"))
    var addTagToTaskResult: Result<Void, Error> = .success(())
    var removeTagFromTaskResult: Result<Void, Error> = .success(())
    var deleteTaskError: Error?

    private(set) var fetchTaskCallCount = 0
    private(set) var updateTaskCallCount = 0
    private(set) var updateStatusCallCount = 0
    private(set) var createTagCallCount = 0
    private(set) var addTagToTaskCallCount = 0
    private(set) var removeTagFromTaskCallCount = 0
    private(set) var lastUpdateTaskPayload: TaskUpdatePayload?
    private(set) var lastAddTagArguments: (taskId: UUID, tagId: UUID)?
    private(set) var lastRemoveTagArguments: (taskId: UUID, tagId: UUID)?
    private(set) var deleteTaskCalls: [UUID] = []

    func fetchTask(id: UUID) async throws -> TaskDetail {
        fetchTaskCallCount += 1
        return try fetchTaskResult.get()
    }

    func fetchTagsForTask(taskId: UUID) async throws -> [Tag] {
        try fetchTagsForTaskResult.get()
    }

    func fetchAllTags() async throws -> [Tag] {
        try fetchAllTagsResult.get()
    }

    func updateTask(id: UUID, payload: TaskUpdatePayload) async throws -> TaskDetail {
        updateTaskCallCount += 1
        lastUpdateTaskPayload = payload
        guard let result = updateTaskResult else {
            var updated = try fetchTaskResult.get()
            if let title = payload.title { updated.title = title }
            if let notes = payload.notes { updated.notes = notes }
            if let lifeAreaId = payload.lifeAreaId { updated.lifeAreaId = lifeAreaId }
            if let priority = payload.priority { updated.priority = priority }
            if let dueDate = payload.dueDate { updated.dueDate = dueDate }
            return updated
        }
        return try result.get()
    }

    func updateStatus(id: UUID, status: TaskStatus) async throws -> TaskDetail {
        updateStatusCallCount += 1
        guard let result = updateStatusResult else {
            var updated = try fetchTaskResult.get()
            updated.status = status
            return updated
        }
        return try result.get()
    }

    func createTag(name: String) async throws -> Tag {
        createTagCallCount += 1
        return try createTagResult.get()
    }

    func addTagToTask(taskId: UUID, tagId: UUID) async throws {
        addTagToTaskCallCount += 1
        lastAddTagArguments = (taskId, tagId)
        _ = try addTagToTaskResult.get()
    }

    func removeTagFromTask(taskId: UUID, tagId: UUID) async throws {
        removeTagFromTaskCallCount += 1
        lastRemoveTagArguments = (taskId, tagId)
        _ = try removeTagFromTaskResult.get()
    }

    func deleteTask(id: UUID) async throws {
        deleteTaskCalls.append(id)
        if let deleteTaskError { throw deleteTaskError }
    }
}
