//
//  TasksServiceMutationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Covers the row's close write-through: optimistic local flip, the exact adapter call, and the
/// revert-on-failure path that keeps the list in sync with stored truth. Closing is one-way
/// (F-V3-Tasks-rebuild, E's addendum): there is no reopen, and delete lives on the detail screen
/// now, so neither has a service path here.
@MainActor
final class TasksServiceMutationTests: XCTestCase {
    private let work = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)

    private func makeTask(_ title: String, status: TaskStatus = .open) -> TaskItem {
        TaskItem(id: UUID(), lifeAreaId: work.id, title: title, status: status, priority: .p4, dueDate: nil)
    }

    private func loadedService(_ tasks: [TaskItem]) async -> (TasksService, FakeTasksClientAdapting) {
        let fake = FakeTasksClientAdapting()
        fake.lifeAreasResult = .success([work])
        fake.tasksResult = .success(tasks)
        let sut = TasksService(client: fake)
        sut.statusFilter = .all
        await sut.load()
        return (sut, fake)
    }

    private func groupedTasks(_ sut: TasksService) -> [TaskItem] {
        guard case .loaded(let groups) = sut.state else { return [] }
        return groups.flatMap(\.tasks)
    }

    func testClose_openTask_persistsDoneAndUpdatesLocally() async {
        let task = makeTask("Finish report")
        let (sut, fake) = await loadedService([task])

        await sut.close(task)

        XCTAssertEqual(fake.setStatusCalls.count, 1)
        XCTAssertEqual(fake.setStatusCalls.first?.taskId, task.id)
        XCTAssertEqual(fake.setStatusCalls.first?.status, .done)
        XCTAssertEqual(groupedTasks(sut).first(where: { $0.id == task.id })?.status, .done)
    }

    /// Closing stamps `completed_at` locally too — the same rule the write applies — so "Closed
    /// today" can show the task the moment it flips, without waiting on a refetch.
    func testClose_stampsTheCompletionMomentLocally() async {
        let task = makeTask("Finish report")
        let (sut, _) = await loadedService([task])

        await sut.close(task)

        XCTAssertNotNil(groupedTasks(sut).first(where: { $0.id == task.id })?.completedAt)
    }

    /// One-way street: a done task's circle is display-only and there is no reopen path — a stray
    /// call on a done task must not write anything.
    func testClose_doneTask_isANoOp() async {
        let task = makeTask("Already done", status: .done)
        let (sut, fake) = await loadedService([task])

        await sut.close(task)

        XCTAssertTrue(fake.setStatusCalls.isEmpty)
        XCTAssertEqual(groupedTasks(sut).first(where: { $0.id == task.id })?.status, .done)
    }

    func testClose_failure_revertsToServerTruthAndSurfacesError() async {
        let task = makeTask("Flaky close")
        let (sut, fake) = await loadedService([task])
        fake.setStatusError = TasksServiceError.fetchFailed("network down")

        await sut.close(task)

        // A failed write reloads; the reload returns the original (still-open) task.
        XCTAssertEqual(groupedTasks(sut).first(where: { $0.id == task.id })?.status, .open)
        XCTAssertEqual(sut.mutationErrorMessage, "network down")
        XCTAssertEqual(fake.fetchAllTasksCallCount, 2)  // initial load + reload-on-failure
    }

    func testClose_beforeLoad_isNoOp() async {
        let fake = FakeTasksClientAdapting()
        let sut = TasksService(client: fake)
        let task = makeTask("Never loaded")

        await sut.close(task)

        XCTAssertTrue(fake.setStatusCalls.isEmpty)
    }
}
