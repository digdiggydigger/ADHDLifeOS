//
//  TaskDetailServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class TaskDetailServiceTests: XCTestCase {

    private func makeTask(
        id: UUID = UUID(),
        title: String = "Task",
        notes: String? = nil,
        status: TaskStatus = .open,
        priority: TaskPriority = .p4,
        dueDate: Date? = nil
    ) -> TaskDetail {
        TaskDetail(
            id: id, lifeAreaId: nil, title: title, notes: notes,
            status: status, priority: priority, dueDate: dueDate, createdAt: Date()
        )
    }

    func testLoad_success_setsLoadedStateWithTaskAndTags() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask(title: "Buy milk")
        let tag = Tag(id: UUID(), name: "urgent")
        fake.fetchTaskResult = .success(task)
        fake.fetchTagsForTaskResult = .success([tag])
        let sut = TaskDetailService(taskId: task.id, client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded(task))
        XCTAssertEqual(sut.tags, [tag])
    }

    func testLoad_fetchFails_setsFailedState() async {
        let fake = FakeTaskDetailClientAdapting()
        fake.fetchTaskResult = .failure(TasksServiceError.fetchFailed("Network error"))
        let sut = TaskDetailService(taskId: UUID(), client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .failed("Network error"))
    }

    func testSave_withPartialFields_success_updatesState() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask(title: "Original")
        fake.fetchTaskResult = .success(task)
        let sut = TaskDetailService(taskId: task.id, client: fake)
        await sut.load()

        let edited = TaskEditedFields(
            title: "Updated", notes: "", lifeAreaId: nil, priority: task.priority, dueDate: nil
        )
        let result = await sut.save(edited: edited)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.lastUpdateTaskPayload?.title, "Updated")
        XCTAssertNil(fake.lastUpdateTaskPayload?.priority, "Priority did not change, should be omitted")
        if case .loaded(let updated) = sut.state {
            XCTAssertEqual(updated.title, "Updated")
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testSave_invalidTitle_rejectedBeforeNetworkCall() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask()
        fake.fetchTaskResult = .success(task)
        let sut = TaskDetailService(taskId: task.id, client: fake)
        await sut.load()

        let edited = TaskEditedFields(
            title: "   ", notes: "", lifeAreaId: nil, priority: task.priority, dueDate: nil
        )
        let result = await sut.save(edited: edited)

        XCTAssertFalse(result)
        XCTAssertEqual(sut.errorMessage, TaskCreateValidationError.emptyTitle.errorDescription)
        XCTAssertEqual(fake.updateTaskCallCount, 0)
    }

    func testSave_noChangedFields_succeedsWithoutNetworkCall() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask(title: "Same")
        fake.fetchTaskResult = .success(task)
        let sut = TaskDetailService(taskId: task.id, client: fake)
        await sut.load()

        let edited = TaskEditedFields(
            title: "Same", notes: "", lifeAreaId: nil, priority: task.priority, dueDate: nil
        )
        let result = await sut.save(edited: edited)

        XCTAssertTrue(result)
        XCTAssertEqual(fake.updateTaskCallCount, 0)
    }

    func testClose_openTask_becomesDone() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask(status: .open)
        fake.fetchTaskResult = .success(task)
        let sut = TaskDetailService(taskId: task.id, client: fake)
        await sut.load()

        await sut.close()

        XCTAssertEqual(fake.updateStatusCallCount, 1)
        if case .loaded(let updated) = sut.state {
            XCTAssertEqual(updated.status, .done)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    /// One-way street (F-V3-Tasks-rebuild, E's addendum): closed tasks never reopen, so a stray
    /// call on a done task must not write anything.
    func testClose_doneTask_isANoOp() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask(status: .done)
        fake.fetchTaskResult = .success(task)
        let sut = TaskDetailService(taskId: task.id, client: fake)
        await sut.load()

        await sut.close()

        XCTAssertEqual(fake.updateStatusCallCount, 0)
        XCTAssertEqual(sut.state, .loaded(task))
    }

    // MARK: - Delete (moved here from the list's swipe in F-V3-Tasks-rebuild)

    func testDelete_success_callsTheClientAndReturnsTrue() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask()
        fake.fetchTaskResult = .success(task)
        let sut = TaskDetailService(taskId: task.id, client: fake)
        await sut.load()

        let result = await sut.delete()

        XCTAssertTrue(result)
        XCTAssertEqual(fake.deleteTaskCalls, [task.id])
    }

    func testDelete_failure_surfacesTheErrorAndReturnsFalse() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask()
        fake.fetchTaskResult = .success(task)
        fake.deleteTaskError = TasksServiceError.fetchFailed("delete refused")
        let sut = TaskDetailService(taskId: task.id, client: fake)
        await sut.load()

        let result = await sut.delete()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.errorMessage, "delete refused")
    }

    func testAddTag_existingMatchFound_attachesExistingTagWithoutCreating() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask()
        let existingTag = Tag(id: UUID(), name: "urgent")
        fake.fetchTaskResult = .success(task)
        fake.fetchAllTagsResult = .success([existingTag])
        let sut = TaskDetailService(taskId: task.id, client: fake)
        await sut.load()

        await sut.addTag(name: "urgent")

        XCTAssertEqual(fake.createTagCallCount, 0)
        XCTAssertEqual(fake.addTagToTaskCallCount, 1)
        XCTAssertEqual(fake.lastAddTagArguments?.tagId, existingTag.id)
        XCTAssertTrue(sut.tags.contains(existingTag))
    }

    func testAddTag_noMatch_createsThenAttaches() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask()
        let newTag = Tag(id: UUID(), name: "focus")
        fake.fetchTaskResult = .success(task)
        fake.fetchAllTagsResult = .success([])
        fake.createTagResult = .success(newTag)
        let sut = TaskDetailService(taskId: task.id, client: fake)
        await sut.load()

        await sut.addTag(name: "focus")

        XCTAssertEqual(fake.createTagCallCount, 1)
        XCTAssertEqual(fake.addTagToTaskCallCount, 1)
        XCTAssertEqual(fake.lastAddTagArguments?.tagId, newTag.id)
        XCTAssertTrue(sut.tags.contains(newTag))
    }

    func testRemoveTag_removesFromTagsList() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask()
        let tag = Tag(id: UUID(), name: "urgent")
        fake.fetchTaskResult = .success(task)
        fake.fetchTagsForTaskResult = .success([tag])
        let sut = TaskDetailService(taskId: task.id, client: fake)
        await sut.load()

        await sut.removeTag(tag)

        XCTAssertEqual(fake.removeTagFromTaskCallCount, 1)
        XCTAssertEqual(fake.lastRemoveTagArguments?.tagId, tag.id)
        XCTAssertFalse(sut.tags.contains(tag))
    }
}
