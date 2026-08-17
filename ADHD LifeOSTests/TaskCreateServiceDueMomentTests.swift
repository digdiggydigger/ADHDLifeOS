//
//  TaskCreateServiceDueMomentTests.swift
//  ADHD LifeOSTests
//
//  Covers "FEATURE: Task Due-Moment Notification"'s Task Create wiring — independent of
//  TaskCreateServiceTests.swift's countdown-nudge coverage.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class TaskCreateServiceDueMomentTests: XCTestCase {

    func testCreateTask_withDueDateAndNotificationEnabled_schedulesAfterCreation() async {
        let fake = FakeTaskCreateClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: dueDate)
        fake.createTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskCreateService(client: fake, schedulingClient: scheduling)
        sut.title = "Task"
        sut.dueDate = dueDate
        sut.dueMomentNotificationEnabled = true

        let result = await sut.createTask()

        XCTAssertTrue(result)
        XCTAssertEqual(scheduling.scheduleDueMomentNotificationCallCount, 1)
        XCTAssertEqual(scheduling.lastScheduleDueMomentArguments?.taskId, task.id)
        XCTAssertEqual(scheduling.lastScheduleDueMomentArguments?.dueDate, dueDate)
        XCTAssertNil(sut.warningMessage)
    }

    func testCreateTask_noDueDate_doesNotScheduleEvenIfEnabled() async {
        let fake = FakeTaskCreateClientAdapting()
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: nil)
        fake.createTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskCreateService(client: fake, schedulingClient: scheduling)
        sut.title = "Task"
        sut.dueMomentNotificationEnabled = true

        _ = await sut.createTask()

        XCTAssertEqual(scheduling.scheduleDueMomentNotificationCallCount, 0)
    }

    func testCreateTask_notificationNotEnabled_doesNotSchedule() async {
        let fake = FakeTaskCreateClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: dueDate)
        fake.createTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskCreateService(client: fake, schedulingClient: scheduling)
        sut.title = "Task"
        sut.dueDate = dueDate

        _ = await sut.createTask()

        XCTAssertEqual(scheduling.scheduleDueMomentNotificationCallCount, 0)
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
        sut.dueMomentNotificationEnabled = true

        let result = await sut.createTask()

        XCTAssertTrue(result, "The task is still created even if notification permission is denied")
        XCTAssertEqual(scheduling.scheduleDueMomentNotificationCallCount, 0)
        XCTAssertNotNil(sut.warningMessage)
    }

    /// Countdown nudges and the due-moment notification must be independently schedulable for
    /// the same created task without interfering with each other.
    func testCreateTask_withBothNudgesAndDueMomentNotificationEnabled_schedulesBothIndependently() async {
        let fake = FakeTaskCreateClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = TaskItem(id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p4, dueDate: dueDate)
        fake.createTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskCreateService(client: fake, schedulingClient: scheduling)
        sut.title = "Task"
        sut.dueDate = dueDate
        sut.nudgeSelection = .evenDivision(count: 1)
        sut.dueMomentNotificationEnabled = true

        _ = await sut.createTask()

        XCTAssertEqual(scheduling.scheduleNudgesCallCount, 1)
        XCTAssertEqual(scheduling.scheduleDueMomentNotificationCallCount, 1)
    }
}
