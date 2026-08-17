//
//  LifeAreaDetailServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class LifeAreaDetailServiceTests: XCTestCase {

    private let lifeAreaId = UUID()

    func testInitialState_isLoading() {
        let fake = FakeLifeAreaDetailClientAdapting()
        let sut = LifeAreaDetailService(lifeAreaId: lifeAreaId, client: fake)

        XCTAssertEqual(sut.state, .loading)
    }

    func testLoad_success_setsLoadedStateAndScopesFetchesToLifeArea() async {
        let fake = FakeLifeAreaDetailClientAdapting()
        let task = TaskItem(
            id: UUID(), lifeAreaId: lifeAreaId, title: "Drink water",
            status: .open, priority: .p2, dueDate: nil
        )
        let log = Log(
            id: UUID(), lifeAreaId: lifeAreaId, type: .journal,
            body: "Felt good today.", entryDate: Date(), createdAt: Date()
        )
        fake.tasksResult = .success([task])
        fake.logsResult = .success([log])
        let sut = LifeAreaDetailService(lifeAreaId: lifeAreaId, client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.filteredTasks, [task])
        XCTAssertEqual(sut.logs, [log])
        XCTAssertEqual(fake.lastFetchTasksLifeAreaId, lifeAreaId)
        XCTAssertEqual(fake.lastFetchLogsLifeAreaId, lifeAreaId)
    }

    func testLoad_emptyTasks_producesEmptyFilteredTasksButKeepsLogs() async {
        let fake = FakeLifeAreaDetailClientAdapting()
        let log = Log(
            id: UUID(), lifeAreaId: lifeAreaId, type: .log,
            body: "Took medication.", entryDate: Date(), createdAt: Date()
        )
        fake.tasksResult = .success([])
        fake.logsResult = .success([log])
        let sut = LifeAreaDetailService(lifeAreaId: lifeAreaId, client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.filteredTasks, [])
        XCTAssertEqual(sut.logs, [log])
    }

    func testLoad_emptyLogs_producesEmptyLogsButKeepsTasks() async {
        let fake = FakeLifeAreaDetailClientAdapting()
        let task = TaskItem(
            id: UUID(), lifeAreaId: lifeAreaId, title: "Drink water",
            status: .open, priority: .p2, dueDate: nil
        )
        fake.tasksResult = .success([task])
        fake.logsResult = .success([])
        let sut = LifeAreaDetailService(lifeAreaId: lifeAreaId, client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.filteredTasks, [task])
        XCTAssertEqual(sut.logs, [])
    }

    func testLoad_bothEmpty_producesEmptyTasksAndLogs() async {
        let fake = FakeLifeAreaDetailClientAdapting()
        fake.tasksResult = .success([])
        fake.logsResult = .success([])
        let sut = LifeAreaDetailService(lifeAreaId: lifeAreaId, client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded)
        XCTAssertEqual(sut.filteredTasks, [])
        XCTAssertEqual(sut.logs, [])
    }

    func testLoad_logsAreSortedNewestFirst() async {
        let fake = FakeLifeAreaDetailClientAdapting()
        let older = Log(
            id: UUID(), lifeAreaId: lifeAreaId, type: .log,
            body: "Older", entryDate: Date(timeIntervalSince1970: 100), createdAt: Date()
        )
        let newer = Log(
            id: UUID(), lifeAreaId: lifeAreaId, type: .log,
            body: "Newer", entryDate: Date(timeIntervalSince1970: 200), createdAt: Date()
        )
        fake.logsResult = .success([older, newer])
        let sut = LifeAreaDetailService(lifeAreaId: lifeAreaId, client: fake)

        await sut.load()

        XCTAssertEqual(sut.logs, [newer, older])
    }

    func testLoad_tasksFetchFails_setsFailedState() async {
        let fake = FakeLifeAreaDetailClientAdapting()
        fake.tasksResult = .failure(LifeAreaDetailServiceError.fetchFailed("Network error"))
        let sut = LifeAreaDetailService(lifeAreaId: lifeAreaId, client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .failed("Network error"))
    }

    func testLoad_logsFetchFails_setsFailedState() async {
        let fake = FakeLifeAreaDetailClientAdapting()
        fake.logsResult = .failure(LifeAreaDetailServiceError.fetchFailed("Network error"))
        let sut = LifeAreaDetailService(lifeAreaId: lifeAreaId, client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .failed("Network error"))
    }

    func testStatusFilter_defaultsToOpen() {
        let fake = FakeLifeAreaDetailClientAdapting()
        let sut = LifeAreaDetailService(lifeAreaId: lifeAreaId, client: fake)

        XCTAssertEqual(sut.statusFilter, .open)
    }

    func testStatusFilter_changingAfterLoad_refiltersWithoutRefetching() async {
        let fake = FakeLifeAreaDetailClientAdapting()
        let openTask = TaskItem(
            id: UUID(), lifeAreaId: lifeAreaId, title: "Open task",
            status: .open, priority: .p2, dueDate: nil
        )
        let doneTask = TaskItem(
            id: UUID(), lifeAreaId: lifeAreaId, title: "Done task",
            status: .done, priority: .p2, dueDate: nil
        )
        fake.tasksResult = .success([openTask, doneTask])
        let sut = LifeAreaDetailService(lifeAreaId: lifeAreaId, client: fake)
        await sut.load()
        XCTAssertEqual(sut.filteredTasks, [openTask])

        sut.statusFilter = .done

        XCTAssertEqual(sut.filteredTasks, [doneTask])
        XCTAssertEqual(fake.fetchTasksCallCount, 1)

        sut.statusFilter = .all

        XCTAssertEqual(sut.filteredTasks, [openTask, doneTask])
        XCTAssertEqual(fake.fetchTasksCallCount, 1)
    }

    func testLoad_calledAgainAfterFailure_resetsToLoadingThenLoaded() async {
        let fake = FakeLifeAreaDetailClientAdapting()
        fake.tasksResult = .failure(LifeAreaDetailServiceError.fetchFailed("Network error"))
        let sut = LifeAreaDetailService(lifeAreaId: lifeAreaId, client: fake)
        await sut.load()
        XCTAssertEqual(sut.state, .failed("Network error"))

        fake.tasksResult = .success([])
        await sut.load()

        XCTAssertEqual(sut.state, .loaded)
    }
}
