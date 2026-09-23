//
//  TaskCreateServiceTests.swift
//  ADHD LifeOSTests
//
//  **`F-D1-ComposerBothDoors` reversed five of these.** The composer asked for tags until this
//  block; E's round 6 answer moved them — with notes and the place — onto the task: *"The next
//  step, tags, place and notes live on the task."* The tag tests that stood here
//  (`…withExistingTagSelected_attachesTag`, `…withNewlyCreatedTag_createsAndAttachesTag`,
//  `testAddNewTag_matchingExistingTagName_…`, `…taskTagsInsertFailure_…`,
//  `testLoadTags_failure_setsFailedState`) went with the surface they tested, and the seam they
//  wrote through was PRUNED rather than left dead (`ComposerBothDoorsCallSiteTests` pins that).
//
//  What replaced them is the composer's new secondary write, the Time menu, and it copies the
//  deleted tag-attach failure test's SHAPE on purpose: the create is the commit point, and a
//  failed follow-up write warns rather than failing a task that already exists — a "failed" task
//  the user retried would be created twice.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class TaskCreateServiceTests: XCTestCase {

    private var client: FakeTaskCreateClientAdapting!
    private var detail: FakeTaskDetailClientAdapting!

    override func setUp() {
        super.setUp()
        client = FakeTaskCreateClientAdapting()
        detail = FakeTaskDetailClientAdapting()
    }

    private func makeService(
        lifeAreas: [LifeArea] = [], homeClient: HomeClientAdapting? = nil
    ) -> TaskCreateService {
        TaskCreateService(
            client: client, taskDetailClient: detail, lifeAreas: lifeAreas, homeClient: homeClient
        )
    }

    private static func task(title: String = "Buy milk") -> TaskItem {
        TaskItem(id: UUID(), lifeAreaId: nil, title: title, status: .open, priority: .p4, dueDate: nil)
    }

    // MARK: - The create

    func testCreateTask_success_createsTaskAndSetsCreatedTask() async {
        let task = Self.task()
        client.createTaskResult = .success(task)
        let sut = makeService()
        sut.title = "Buy milk"

        let result = await sut.createTask()

        XCTAssertTrue(result)
        XCTAssertEqual(sut.createdTask, task)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.warningMessage)
        XCTAssertEqual(client.createTaskCallCount, 1)
    }

    /// **CAPT-02 retired** (round 6, *"New tasks have no date unless one is picked"*). The fan's
    /// Task tile used to force `startOfDay(now)`; the one composer both doors now open writes
    /// whatever the when-chips say, and "Not yet" says nothing.
    func testCreateTask_withNoDatePicked_writesNoDate() async {
        let sut = makeService()
        sut.title = "Book the dentist"

        _ = await sut.createTask()

        XCTAssertNotNil(client.lastCreateTaskInput, "the create never happened")
        XCTAssertNil(client.lastCreateTaskInput?.dueDate, "a task nobody dated was given a date")
    }

    func testCreateTask_passesTheChosenAreaThrough() async {
        let area = UUID()
        let sut = makeService()
        sut.title = "Book the dentist"
        sut.lifeAreaId = area

        _ = await sut.createTask()

        XCTAssertEqual(client.lastCreateTaskInput?.lifeAreaId, area)
    }

    func testCreateTask_emptyTitle_failsWithoutCallingClient() async {
        let sut = makeService()
        sut.title = "   "

        let result = await sut.createTask()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.errorMessage, TaskCreateValidationError.emptyTitle.errorDescription)
        XCTAssertEqual(client.createTaskCallCount, 0)
        XCTAssertEqual(detail.updateTaskCallCount, 0)
    }

    func testCreateTask_taskInsertFailure_surfacesErrorAndDoesNotSetCreatedTask() async {
        client.createTaskResult = .failure(TasksServiceError.fetchFailed("Network error"))
        let sut = makeService()
        sut.title = "Task"

        let result = await sut.createTask()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.errorMessage, "Network error")
        XCTAssertNil(sut.createdTask)
    }

    /// The `?? error.localizedDescription` half of the message mapping — an SDK error that is not a
    /// `LocalizedError` still says something rather than nothing. A partial REGION the coverage
    /// sweep found (CLAUDE.md: "the last unit in a file is often a partial region, not a line").
    func testCreateTask_nonLocalizedFailure_fallsBackToTheErrorsOwnDescription() async {
        let error = NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: [
            NSLocalizedDescriptionKey: "The service is currently unavailable."
        ])
        client.createTaskResult = .failure(error)
        let sut = makeService()
        sut.title = "Task"

        _ = await sut.createTask()

        XCTAssertEqual(sut.errorMessage, "The service is currently unavailable.")
    }

    func testIsTitleValid_reflectsCurrentTitle() {
        let sut = makeService()

        XCTAssertFalse(sut.isTitleValid)

        sut.title = "  "
        XCTAssertFalse(sut.isTitleValid)

        sut.title = "Buy milk"
        XCTAssertTrue(sut.isTitleValid)
    }

    // MARK: - The Time menu's write

    /// The create input has no focus fields (`NormalizedCreateTaskInput` is untouched by this
    /// block), so the time lands the way the fan's Task tile always landed it: a follow-up
    /// `updateTask` carrying `focusDurationSeconds` — and NOTHING else, so the follow-up can never
    /// overwrite a field the create just wrote.
    func testCreateTask_writesTheChosenTimeAsFocusDuration() async {
        let task = Self.task()
        client.createTaskResult = .success(task)
        let sut = makeService()
        sut.title = "Buy milk"
        sut.effort = .hour

        _ = await sut.createTask()

        var expected = TaskUpdatePayload()
        expected.focusDurationSeconds = 3600
        XCTAssertEqual(detail.updateTaskCallCount, 1)
        XCTAssertEqual(detail.lastUpdateTaskId, task.id, "the time was written to some other task")
        XCTAssertEqual(detail.lastUpdateTaskPayload, expected)
    }

    /// Left alone, the menu reads "15 min" and means it — the value on every board E approved.
    func testCreateTask_withTheTimeLeftAlone_writesFifteenMinutes() async {
        let sut = makeService()
        sut.title = "Buy milk"

        _ = await sut.createTask()

        XCTAssertEqual(detail.lastUpdateTaskPayload?.focusDurationSeconds, 900)
    }

    /// The reversal of the deleted `testCreateTask_taskTagsInsertFailure_…`, and the spec's named
    /// trap: `QuickCaptureView.saveTask()` put its follow-up write inside the SAME `do` as the
    /// create, so a failed time write reported a task that already existed as not created.
    func testCreateTask_focusDurationUpdateFailure_taskStillConsideredCreated_warningSurfaced() async {
        let task = Self.task()
        client.createTaskResult = .success(task)
        detail.updateTaskResult = .failure(TasksServiceError.fetchFailed("Network error"))
        let sut = makeService()
        sut.title = "Buy milk"

        let result = await sut.createTask()

        XCTAssertTrue(result, "The task itself is not rolled back when only its time fails to save")
        XCTAssertEqual(sut.createdTask, task)
        XCTAssertEqual(sut.warningMessage, "Task created, but couldn't save its time.")
        XCTAssertNil(sut.errorMessage)
    }

    func testCreateTask_createFailure_writesNoTime() async {
        client.createTaskResult = .failure(TasksServiceError.fetchFailed("Network error"))
        let sut = makeService()
        sut.title = "Buy milk"

        _ = await sut.createTask()

        XCTAssertEqual(detail.updateTaskCallCount, 0, "a time was written for a task that was never created")
    }

    // MARK: - The Area menu's list

    /// The capture disc's door has no area list to hand the composer — `RootView` holds a home
    /// client, not an array — so the composer fetches its own, `QuickCaptureView`'s pattern.
    func testLoadLifeAreas_withAHomeClient_fetchesTheAreas() async {
        let home = FakeHomeClientAdapting()
        let area = LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0)
        home.lifeAreasResult = .success([area])
        let sut = makeService(homeClient: home)

        await sut.loadLifeAreas()

        XCTAssertEqual(home.fetchLifeAreasCallCount, 1)
        XCTAssertEqual(sut.offeredLifeAreas, [area])
    }

    /// The Tasks tab and a life area's screen already hold their list, and must not pay a fetch.
    func testLoadLifeAreas_withoutAHomeClient_keepsThePassedAreas() async {
        let area = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)
        let sut = makeService(lifeAreas: [area])

        await sut.loadLifeAreas()

        XCTAssertEqual(sut.offeredLifeAreas, [area])
    }

    /// Garnish, never load-bearing: an areas outage must not stop someone adding a task.
    func testLoadLifeAreas_failureLeavesTheComposerUsable() async {
        let home = FakeHomeClientAdapting()
        home.lifeAreasResult = .failure(TasksServiceError.fetchFailed("Network error"))
        let sut = makeService(homeClient: home)
        sut.title = "Buy milk"

        await sut.loadLifeAreas()
        let created = await sut.createTask()

        XCTAssertTrue(sut.offeredLifeAreas.isEmpty)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(created)
    }

    /// Both old composers hid archived areas from a NEW task, and the shared `LifeAreaPicker` would
    /// otherwise list them greyed. The one exception is the area the composer was opened FILED to
    /// ("Add to <area>" on an archived area's screen), which must still read as selected rather
    /// than blank.
    func testOfferedAreas_hidesArchivedAreasUnlessOneIsTheSelection() {
        let active = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)
        let archived = LifeArea(id: UUID(), name: "Old", colour: "🗂️", sortOrder: 1, archived: true)

        XCTAssertEqual(TaskCreateService.offeredAreas([active, archived], selected: nil), [active])
        XCTAssertEqual(
            TaskCreateService.offeredAreas([active, archived], selected: archived.id), [active, archived]
        )
    }
}
