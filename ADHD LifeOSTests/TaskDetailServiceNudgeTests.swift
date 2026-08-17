//
//  TaskDetailServiceNudgeTests.swift
//  ADHD LifeOSTests
//
//  Split out from TaskDetailServiceTests.swift to keep that file under SwiftLint's
//  type_body_length limit — covers "FEATURE: Task Due-Time Nudges"' Task Detail wiring.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class TaskDetailServiceNudgeTests: XCTestCase {

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

    func testLoad_setsHasScheduledNudgesFromAdapter() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask()
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        scheduling.hasScheduledNudgesResult = true
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)

        await sut.load()

        XCTAssertTrue(sut.hasScheduledNudges)
    }

    func testUpdateNudgeSelection_evenDivision_schedulesAndMarksAsScheduled() async {
        let fake = FakeTaskDetailClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(dueDate: dueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()

        await sut.updateNudgeSelection(.evenDivision(count: 2), dueDate: dueDate)

        XCTAssertEqual(scheduling.scheduleNudgesCallCount, 1)
        XCTAssertEqual(scheduling.lastScheduleArguments?.taskId, task.id)
        XCTAssertEqual(scheduling.lastScheduleArguments?.fireDates.count, 2)
        XCTAssertTrue(sut.hasScheduledNudges)
    }

    /// Reproduces the original bug: the task's persisted due date is `A`, but the caller (mirroring
    /// `TaskDetailView`'s live `@State dueDate`, staged and unsaved) passes a different due date
    /// `B` — the fire date must be computed from `B`, never from the stale `task.dueDate`. Uses
    /// checkpoint mode (due dates far enough out to require it) since `fireDate(for:dueDate:)` is a
    /// pure function of `dueDate` alone, unlike even-division's `now`-relative math — this keeps
    /// the assertion deterministic instead of racing the test's own clock reads.
    func testUpdateNudgeSelection_usesPassedInDueDate_notStaleTaskSnapshot() async {
        let fake = FakeTaskDetailClientAdapting()
        let staleDueDate = Date().addingTimeInterval(10 * 24 * 3600)
        let liveEditedDueDate = Date().addingTimeInterval(20 * 24 * 3600)
        let task = makeTask(dueDate: staleDueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()

        await sut.updateNudgeSelection(.checkpoints([.oneWeekBefore]), dueDate: liveEditedDueDate)

        let expectedFireDate = TaskCountdownNudgeScheduling.fireDate(
            for: .oneWeekBefore, dueDate: liveEditedDueDate
        )
        let staleFireDate = TaskCountdownNudgeScheduling.fireDate(for: .oneWeekBefore, dueDate: staleDueDate)
        XCTAssertEqual(scheduling.lastScheduleArguments?.fireDates.map(\.date), [expectedFireDate])
        XCTAssertNotEqual(scheduling.lastScheduleArguments?.fireDates.map(\.date), [staleFireDate])
    }

    func testUpdateNudgeSelection_none_cancelsNudges() async {
        let fake = FakeTaskDetailClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(dueDate: dueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()
        await sut.updateNudgeSelection(.evenDivision(count: 1), dueDate: dueDate)

        await sut.updateNudgeSelection(.none, dueDate: dueDate)

        XCTAssertEqual(scheduling.cancelNudgesCallCount, 1)
        XCTAssertEqual(scheduling.lastCancelTaskId, task.id)
        XCTAssertFalse(sut.hasScheduledNudges)
    }

    func testUpdateNudgeSelection_permissionDenied_surfacesWarningAndDoesNotSchedule() async {
        let fake = FakeTaskDetailClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(dueDate: dueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        scheduling.authorizationGranted = false
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()

        await sut.updateNudgeSelection(.evenDivision(count: 1), dueDate: dueDate)

        XCTAssertEqual(scheduling.scheduleNudgesCallCount, 0)
        XCTAssertNotNil(sut.warningMessage)
        XCTAssertFalse(sut.hasScheduledNudges)
    }

    func testDisableNudges_cancelsScheduledNudges() async {
        let fake = FakeTaskDetailClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(dueDate: dueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()
        await sut.updateNudgeSelection(.evenDivision(count: 1), dueDate: dueDate)

        await sut.disableNudges()

        XCTAssertEqual(scheduling.cancelNudgesCallCount, 1)
        XCTAssertFalse(sut.hasScheduledNudges)
    }

    func testToggleStatus_openToDone_withScheduledNudges_cancelsThem() async {
        let fake = FakeTaskDetailClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(status: .open, dueDate: dueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()
        await sut.updateNudgeSelection(.evenDivision(count: 1), dueDate: dueDate)

        await sut.toggleStatus()

        XCTAssertEqual(scheduling.cancelNudgesCallCount, 1)
        XCTAssertFalse(sut.hasScheduledNudges)
    }

    func testToggleStatus_doneToOpen_withNoScheduledNudges_doesNotCancel() async {
        let fake = FakeTaskDetailClientAdapting()
        let task = makeTask(status: .done)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()

        await sut.toggleStatus()

        XCTAssertEqual(scheduling.cancelNudgesCallCount, 0)
    }

    /// Per E's 2026-07-19 design call: a due-date change on a task with nudges attached always
    /// cancels them outright — no silent reschedule against the old selection, regardless of
    /// whether that selection is known from this session.
    func testSave_dueDateChanged_withScheduledNudges_cancelsThemOutright() async {
        let fake = FakeTaskDetailClientAdapting()
        let originalDueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(dueDate: originalDueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()
        await sut.updateNudgeSelection(.evenDivision(count: 1), dueDate: originalDueDate)

        let newDueDate = Date().addingTimeInterval(3600)
        let edited = TaskEditedFields(
            title: task.title, notes: "", lifeAreaId: nil, priority: .p4, dueDate: newDueDate
        )
        _ = await sut.save(edited: edited)

        XCTAssertEqual(scheduling.cancelNudgesCallCount, 1, "No silent reschedule — always cancel outright")
        XCTAssertEqual(scheduling.scheduleNudgesCallCount, 1, "Only the original updateNudgeSelection call scheduled")
        XCTAssertFalse(sut.hasScheduledNudges)
    }

    /// Simulates nudges scheduled in a previous app session: `hasScheduledNudges` is true from
    /// `load()`, but this session never called `updateNudgeSelection` — the fix's cancel-outright
    /// behavior doesn't depend on knowing the prior selection, so this still cancels cleanly.
    func testSave_dueDateChanged_withNudgesFromPriorSession_cancelsThemOutright() async {
        let fake = FakeTaskDetailClientAdapting()
        let originalDueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(dueDate: originalDueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        scheduling.hasScheduledNudgesResult = true
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()

        let newDueDate = Date().addingTimeInterval(3600)
        let edited = TaskEditedFields(
            title: task.title, notes: "", lifeAreaId: nil, priority: .p4, dueDate: newDueDate
        )
        _ = await sut.save(edited: edited)

        XCTAssertEqual(scheduling.cancelNudgesCallCount, 1)
        XCTAssertFalse(sut.hasScheduledNudges)
    }

    func testSave_dueDateUnchanged_withScheduledNudges_doesNotCancel() async {
        let fake = FakeTaskDetailClientAdapting()
        let dueDate = Date().addingTimeInterval(42 * 60)
        let task = makeTask(title: "Original", dueDate: dueDate)
        fake.fetchTaskResult = .success(task)
        let scheduling = FakeTaskCountdownNudgeSchedulingAdapting()
        let sut = TaskDetailService(taskId: task.id, client: fake, schedulingClient: scheduling)
        await sut.load()
        await sut.updateNudgeSelection(.evenDivision(count: 1), dueDate: dueDate)

        let edited = TaskEditedFields(
            title: "Updated", notes: "", lifeAreaId: nil, priority: .p4, dueDate: dueDate
        )
        _ = await sut.save(edited: edited)

        XCTAssertEqual(scheduling.cancelNudgesCallCount, 0)
        XCTAssertTrue(sut.hasScheduledNudges)
    }
}
