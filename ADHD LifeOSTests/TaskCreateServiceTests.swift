//
//  TaskCreateServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class TaskCreateServiceTests: XCTestCase {

    func testCreateTask_success_withNoTags_createsTaskAndSetsCreatedTask() async {
        let fake = FakeTaskCreateClientAdapting()
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Buy milk", status: .open, priority: .p4, dueDate: nil)
        fake.createTaskResult = .success(task)
        let sut = TaskCreateService(client: fake, schedulingClient: FakeTaskCountdownNudgeSchedulingAdapting())
        sut.title = "Buy milk"

        let result = await sut.createTask()

        XCTAssertTrue(result)
        XCTAssertEqual(sut.createdTask, task)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.warningMessage)
        XCTAssertEqual(fake.createTaskCallCount, 1)
        XCTAssertEqual(fake.attachTagsCallCount, 0)
    }

    func testCreateTask_success_withExistingTagSelected_attachesTag() async {
        let fake = FakeTaskCreateClientAdapting()
        let existingTag = Tag(id: UUID(), name: "urgent")
        fake.tagsResult = .success([existingTag])
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: nil)
        fake.createTaskResult = .success(task)
        let sut = TaskCreateService(client: fake, schedulingClient: FakeTaskCountdownNudgeSchedulingAdapting())
        sut.title = "Task"
        await sut.loadTags()
        sut.toggleTagSelection(existingTag)

        let result = await sut.createTask()

        XCTAssertTrue(result)
        XCTAssertEqual(sut.createdTask, task)
        XCTAssertEqual(fake.attachTagsCallCount, 1)
        XCTAssertEqual(fake.lastAttachTagsArguments?.tagIds, [existingTag.id])
        XCTAssertEqual(fake.createTagCallCount, 0, "Should not create a new tag when selecting an existing one")
    }

    func testCreateTask_success_withNewlyCreatedTag_createsAndAttachesTag() async {
        let fake = FakeTaskCreateClientAdapting()
        fake.tagsResult = .success([])
        let newTag = Tag(id: UUID(), name: "focus")
        fake.createTagResult = .success(newTag)
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: nil)
        fake.createTaskResult = .success(task)
        let sut = TaskCreateService(client: fake, schedulingClient: FakeTaskCountdownNudgeSchedulingAdapting())
        sut.title = "Task"
        await sut.loadTags()
        sut.newTagName = "focus"
        await sut.addNewTag()

        let result = await sut.createTask()

        XCTAssertTrue(result)
        XCTAssertEqual(fake.createTagCallCount, 1)
        XCTAssertEqual(fake.attachTagsCallCount, 1)
        XCTAssertEqual(fake.lastAttachTagsArguments?.tagIds, [newTag.id])
    }

    func testAddNewTag_matchingExistingTagName_selectsExistingTagInsteadOfCreating() async {
        let fake = FakeTaskCreateClientAdapting()
        let existingTag = Tag(id: UUID(), name: "urgent")
        fake.tagsResult = .success([existingTag])
        let sut = TaskCreateService(client: fake, schedulingClient: FakeTaskCountdownNudgeSchedulingAdapting())
        await sut.loadTags()
        sut.newTagName = "urgent"

        await sut.addNewTag()

        XCTAssertEqual(fake.createTagCallCount, 0)
        XCTAssertTrue(sut.selectedTagIds.contains(existingTag.id))
        XCTAssertEqual(sut.newTagName, "")
    }

    func testCreateTask_emptyTitle_failsWithoutCallingClient() async {
        let fake = FakeTaskCreateClientAdapting()
        let sut = TaskCreateService(client: fake, schedulingClient: FakeTaskCountdownNudgeSchedulingAdapting())
        sut.title = "   "

        let result = await sut.createTask()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.errorMessage, TaskCreateValidationError.emptyTitle.errorDescription)
        XCTAssertEqual(fake.createTaskCallCount, 0)
    }

    func testCreateTask_taskInsertFailure_surfacesErrorAndDoesNotSetCreatedTask() async {
        let fake = FakeTaskCreateClientAdapting()
        fake.createTaskResult = .failure(TasksServiceError.fetchFailed("Network error"))
        let sut = TaskCreateService(client: fake, schedulingClient: FakeTaskCountdownNudgeSchedulingAdapting())
        sut.title = "Task"

        let result = await sut.createTask()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.errorMessage, "Network error")
        XCTAssertNil(sut.createdTask)
    }

    func testCreateTask_taskTagsInsertFailure_taskStillConsideredCreated_warningSurfaced() async {
        let fake = FakeTaskCreateClientAdapting()
        let existingTag = Tag(id: UUID(), name: "urgent")
        fake.tagsResult = .success([existingTag])
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: nil)
        fake.createTaskResult = .success(task)
        fake.attachTagsResult = .failure(TasksServiceError.fetchFailed("Network error"))
        let sut = TaskCreateService(client: fake, schedulingClient: FakeTaskCountdownNudgeSchedulingAdapting())
        sut.title = "Task"
        await sut.loadTags()
        sut.toggleTagSelection(existingTag)

        let result = await sut.createTask()

        XCTAssertTrue(result, "The task itself is not rolled back on a task_tags insert failure")
        XCTAssertEqual(sut.createdTask, task)
        XCTAssertNotNil(sut.warningMessage)
        XCTAssertNil(sut.errorMessage)
    }

    func testIsTitleValid_reflectsCurrentTitle() {
        let fake = FakeTaskCreateClientAdapting()
        let sut = TaskCreateService(client: fake, schedulingClient: FakeTaskCountdownNudgeSchedulingAdapting())

        XCTAssertFalse(sut.isTitleValid)

        sut.title = "  "
        XCTAssertFalse(sut.isTitleValid)

        sut.title = "Buy milk"
        XCTAssertTrue(sut.isTitleValid)
    }

    func testLoadTags_failure_setsFailedState() async {
        let fake = FakeTaskCreateClientAdapting()
        fake.tagsResult = .failure(TasksServiceError.fetchFailed("Network error"))
        let sut = TaskCreateService(client: fake, schedulingClient: FakeTaskCountdownNudgeSchedulingAdapting())

        await sut.loadTags()

        XCTAssertEqual(sut.tagsState, .failed("Network error"))
    }

    func testCreateTask_withDueDateAndNudgeSelection_schedulesNudgesAfterCreation() async {
        let fake = FakeTaskCreateClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: dueDate)
        fake.createTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskCreateService(client: fake, schedulingClient: scheduling)
        sut.title = "Task"
        sut.dueDate = dueDate
        sut.nudgeSelection = .evenDivision(count: 2)

        let result = await sut.createTask()

        XCTAssertTrue(result)
        XCTAssertEqual(scheduling.requestAuthorizationCallCount, 1)
        XCTAssertEqual(scheduling.scheduleNudgesCallCount, 1)
        XCTAssertEqual(scheduling.lastScheduleArguments?.taskId, task.id)
        XCTAssertEqual(scheduling.lastScheduleArguments?.fireDates.count, 2)
        XCTAssertNil(sut.warningMessage)
    }

    func testCreateTask_noDueDate_doesNotScheduleNudgesEvenIfSelectionSet() async {
        let fake = FakeTaskCreateClientAdapting()
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: nil)
        fake.createTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskCreateService(client: fake, schedulingClient: scheduling)
        sut.title = "Task"
        sut.nudgeSelection = .evenDivision(count: 1)

        _ = await sut.createTask()

        XCTAssertEqual(scheduling.scheduleNudgesCallCount, 0)
        XCTAssertEqual(scheduling.requestAuthorizationCallCount, 0)
    }

    func testCreateTask_nudgeSelectionNone_doesNotScheduleNudges() async {
        let fake = FakeTaskCreateClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: dueDate)
        fake.createTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskCreateService(client: fake, schedulingClient: scheduling)
        sut.title = "Task"
        sut.dueDate = dueDate

        _ = await sut.createTask()

        XCTAssertEqual(scheduling.scheduleNudgesCallCount, 0)
    }

    func testCreateTask_permissionDenied_surfacesWarningAndDoesNotSchedule() async {
        let fake = FakeTaskCreateClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: dueDate)
        fake.createTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        scheduling.authorizationGranted = false
        let sut = TaskCreateService(client: fake, schedulingClient: scheduling)
        sut.title = "Task"
        sut.dueDate = dueDate
        sut.nudgeSelection = .evenDivision(count: 1)

        let result = await sut.createTask()

        XCTAssertTrue(result, "The task is still created even if nudge permission is denied")
        XCTAssertEqual(scheduling.scheduleNudgesCallCount, 0)
        XCTAssertNotNil(sut.warningMessage)
    }
}
