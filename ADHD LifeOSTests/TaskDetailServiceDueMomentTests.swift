//
//  TaskDetailServiceDueMomentTests.swift
//  ADHD LifeOSTests
//
//  Covers "FEATURE: Task Due-Moment Notification"'s Task Detail wiring — independent of
//  TaskDetailServiceNudgeTests.swift's countdown-nudge coverage.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class TaskDetailServiceDueMomentTests: XCTestCase {

    private func makeTask(
        id: UUID = UUID(),
        title: String = "Task",
        status: TaskStatus = .open,
        dueDate: Date? = nil
    ) -> TaskDetail {
        TaskDetail(
            id: id, lifeAreaId: nil, title: title, notes: nil,
            status: status, priority: .p4, dueDate: dueDate, createdAt: Date()
        )
    }

    func testLoad_setsHasDueMomentNotificationFromAdapter() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask()
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        scheduling.hasDueMomentNotificationScheduledResult = true
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)

        await sut.load()

        XCTAssertTrue(sut.hasDueMomentNotification)
    }

    func testUpdateDueMomentNotification_enabled_schedulesAndMarksAsScheduled() async {
        let fake = FakeTaskDetailClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(title: "Buy milk", dueDate: dueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()

        await sut.updateDueMomentNotification(enabled: true, dueDate: dueDate)

        XCTAssertEqual(scheduling.scheduleDueMomentNotificationCallCount, 1)
        XCTAssertEqual(scheduling.lastScheduleDueMomentArguments?.taskId, task.id)
        XCTAssertEqual(scheduling.lastScheduleDueMomentArguments?.taskTitle, "Buy milk")
        XCTAssertEqual(scheduling.lastScheduleDueMomentArguments?.dueDate, dueDate)
        XCTAssertTrue(sut.hasDueMomentNotification)
    }

    func testUpdateDueMomentNotification_disabled_cancels() async {
        let fake = FakeTaskDetailClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(dueDate: dueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()
        await sut.updateDueMomentNotification(enabled: true, dueDate: dueDate)

        await sut.updateDueMomentNotification(enabled: false, dueDate: dueDate)

        XCTAssertEqual(scheduling.cancelDueMomentNotificationCallCount, 1)
        XCTAssertEqual(scheduling.lastCancelDueMomentTaskId, task.id)
        XCTAssertFalse(sut.hasDueMomentNotification)
    }

    func testUpdateDueMomentNotification_permissionDenied_surfacesWarningAndDoesNotSchedule() async {
        let fake = FakeTaskDetailClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(dueDate: dueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        scheduling.authorizationGranted = false
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()

        await sut.updateDueMomentNotification(enabled: true, dueDate: dueDate)

        XCTAssertEqual(scheduling.scheduleDueMomentNotificationCallCount, 0)
        XCTAssertNotNil(sut.warningMessage)
        XCTAssertFalse(sut.hasDueMomentNotification)
    }

    func testSave_dueDateChanged_withDueMomentNotificationScheduled_cancelsItOutright() async {
        let fake = FakeTaskDetailClientAdapting()
        let originalDueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(dueDate: originalDueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()
        await sut.updateDueMomentNotification(enabled: true, dueDate: originalDueDate)

        let newDueDate = Date().addingTimeInterval(3600)
        let edited = TaskEditedFields(
            title: task.title, notes: "", lifeAreaId: nil, priority: .p4, dueDate: newDueDate
        )
        _ = await sut.save(edited: edited)

        XCTAssertEqual(scheduling.cancelDueMomentNotificationCallCount, 1)
        XCTAssertFalse(sut.hasDueMomentNotification)
    }

    func testSave_dueDateUnchanged_withDueMomentNotificationScheduled_doesNotCancel() async {
        let fake = FakeTaskDetailClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(title: "Original", dueDate: dueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()
        await sut.updateDueMomentNotification(enabled: true, dueDate: dueDate)

        let edited = TaskEditedFields(
            title: "Updated", notes: "", lifeAreaId: nil, priority: .p4, dueDate: dueDate
        )
        _ = await sut.save(edited: edited)

        XCTAssertEqual(scheduling.cancelDueMomentNotificationCallCount, 0)
        XCTAssertTrue(sut.hasDueMomentNotification)
    }

    func testToggleStatus_openToDone_withDueMomentNotificationScheduled_cancelsIt() async {
        let fake = FakeTaskDetailClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(status: .open, dueDate: dueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()
        await sut.updateDueMomentNotification(enabled: true, dueDate: dueDate)

        await sut.toggleStatus()

        XCTAssertEqual(scheduling.cancelDueMomentNotificationCallCount, 1)
        XCTAssertFalse(sut.hasDueMomentNotification)
    }

    func testToggleStatus_doneToOpen_withNoDueMomentNotificationScheduled_doesNotCancel() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask(status: .done)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()

        await sut.toggleStatus()

        XCTAssertEqual(scheduling.cancelDueMomentNotificationCallCount, 0)
    }

    /// Countdown nudges and the due-moment notification must not interfere with each other:
    /// enabling one leaves the other's state and call counts untouched.
    func testDueMomentNotification_andCountdownNudges_areIndependent() async {
        let fake = FakeTaskDetailClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(dueDate: dueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()

        await sut.updateNudgeSelection(.evenDivision(count: 1), dueDate: dueDate)

        XCTAssertTrue(sut.hasScheduledNudges)
        XCTAssertFalse(sut.hasDueMomentNotification)
        XCTAssertEqual(scheduling.scheduleDueMomentNotificationCallCount, 0)

        await sut.updateDueMomentNotification(enabled: true, dueDate: dueDate)

        XCTAssertTrue(sut.hasScheduledNudges)
        XCTAssertTrue(sut.hasDueMomentNotification)
        XCTAssertEqual(scheduling.cancelNudgesCallCount, 0)
    }
}
