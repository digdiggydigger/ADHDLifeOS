//
//  TasksServiceMutationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Covers the swipe-card write-through: optimistic local flip/removal, the exact adapter call, and
/// the revert-on-failure paths that keep the list in sync with stored truth.
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

    func testToggleStatus_open_persistsDoneAndUpdatesLocally() async {
        let task = makeTask("Finish report")
        let (sut, fake) = await loadedService([task])

        await sut.toggleStatus(task)

        XCTAssertEqual(fake.setStatusCalls.count, 1)
        XCTAssertEqual(fake.setStatusCalls.first?.taskId, task.id)
        XCTAssertEqual(fake.setStatusCalls.first?.status, .done)
        XCTAssertEqual(groupedTasks(sut).first(where: { $0.id == task.id })?.status, .done)
    }

    func testToggleStatus_done_reopensToOpen() async {
        let task = makeTask("Already done", status: .done)
        let (sut, fake) = await loadedService([task])

        await sut.toggleStatus(task)

        XCTAssertEqual(fake.setStatusCalls.first?.status, .open)
        XCTAssertEqual(groupedTasks(sut).first(where: { $0.id == task.id })?.status, .open)
    }

    func testToggleStatus_failure_revertsToServerTruthAndSurfacesError() async {
        let task = makeTask("Flaky toggle")
        let (sut, fake) = await loadedService([task])
        fake.setStatusError = TasksServiceError.fetchFailed("network down")

        await sut.toggleStatus(task)

        // A failed write reloads; the reload returns the original (still-open) task.
        XCTAssertEqual(groupedTasks(sut).first(where: { $0.id == task.id })?.status, .open)
        XCTAssertEqual(sut.mutationErrorMessage, "network down")
        XCTAssertEqual(fake.fetchAllTasksCallCount, 2)  // initial load + reload-on-failure
    }

    func testDelete_removesLocallyAndPersists() async {
        let keep = makeTask("Keep me")
        let drop = makeTask("Delete me")
        let (sut, fake) = await loadedService([keep, drop])

        await sut.delete(drop)

        XCTAssertEqual(fake.deleteTaskCalls, [drop.id])
        XCTAssertEqual(groupedTasks(sut).map(\.id), [keep.id])
    }

    func testDelete_failure_restoresTaskAndSurfacesError() async {
        let keep = makeTask("Keep me")
        let drop = makeTask("Undeletable")
        let (sut, fake) = await loadedService([keep, drop])
        fake.deleteTaskError = TasksServiceError.fetchFailed("delete refused")

        await sut.delete(drop)

        XCTAssertEqual(Set(groupedTasks(sut).map(\.id)), [keep.id, drop.id])
        XCTAssertEqual(sut.mutationErrorMessage, "delete refused")
    }

    func testMutation_beforeLoad_isNoOp() async {
        let fake = FakeTasksClientAdapting()
        let sut = TasksService(client: fake)
        let task = makeTask("Never loaded")

        await sut.toggleStatus(task)
        await sut.delete(task)

        XCTAssertTrue(fake.setStatusCalls.isEmpty)
        XCTAssertTrue(fake.deleteTaskCalls.isEmpty)
    }
}
