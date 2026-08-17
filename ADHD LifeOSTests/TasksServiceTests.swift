//
//  TasksServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class TasksServiceTests: XCTestCase {

    private func makeTask(
        lifeAreaId: UUID?,
        title: String,
        status: TaskStatus = .open
    ) -> TaskItem {
        TaskItem(id: UUID(), lifeAreaId: lifeAreaId, title: title, status: status, priority: .p4, dueDate: nil)
    }

    func testInitialState_isLoading() {
        let fake = FakeTasksClientAdapting()
        let sut = TasksService(client: fake)

        XCTAssertEqual(sut.state, .loading)
    }

    func testLoad_success_setsLoadedStateWithGroupedTasks() async {
        let fake = FakeTasksClientAdapting()
        let work = LifeArea(id: UUID(), name: "Work", colour: "#123456", sortOrder: 0)
        let task = makeTask(lifeAreaId: work.id, title: "Finish report")
        fake.lifeAreasResult = .success([work])
        fake.tasksResult = .success([task])
        let sut = TasksService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([
            LifeAreaTaskGroup(lifeAreaId: work.id, lifeAreaName: "Work", tasks: [task])
        ]))
        XCTAssertEqual(fake.fetchLifeAreasCallCount, 1)
        XCTAssertEqual(fake.fetchAllTasksCallCount, 1)
    }

    func testLoad_emptyData_setsLoadedStateWithEmptyGroups() async {
        let fake = FakeTasksClientAdapting()
        let sut = TasksService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([]))
    }

    func testLoad_lifeAreasFetchFails_setsFailedState() async {
        let fake = FakeTasksClientAdapting()
        fake.lifeAreasResult = .failure(TasksServiceError.fetchFailed("Network error"))
        let sut = TasksService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .failed("Network error"))
    }

    func testLoad_tasksFetchFails_setsFailedState() async {
        let fake = FakeTasksClientAdapting()
        fake.tasksResult = .failure(TasksServiceError.fetchFailed("Network error"))
        let sut = TasksService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .failed("Network error"))
    }

    func testDefaultStatusFilter_isOpen() {
        let fake = FakeTasksClientAdapting()
        let sut = TasksService(client: fake)

        XCTAssertEqual(sut.statusFilter, .open)
    }

    func testChangingStatusFilter_afterLoad_refiltersWithoutRefetching() async {
        let fake = FakeTasksClientAdapting()
        let work = LifeArea(id: UUID(), name: "Work", colour: "#123456", sortOrder: 0)
        let openTask = makeTask(lifeAreaId: work.id, title: "Open task", status: .open)
        let doneTask = makeTask(lifeAreaId: work.id, title: "Done task", status: .done)
        fake.lifeAreasResult = .success([work])
        fake.tasksResult = .success([openTask, doneTask])
        let sut = TasksService(client: fake)
        await sut.load()

        sut.statusFilter = .done

        XCTAssertEqual(sut.state, .loaded([
            LifeAreaTaskGroup(lifeAreaId: work.id, lifeAreaName: "Work", tasks: [doneTask])
        ]))
        XCTAssertEqual(fake.fetchLifeAreasCallCount, 1)
        XCTAssertEqual(fake.fetchAllTasksCallCount, 1)
    }

    func testChangingStatusFilter_toOptionWithNoMatches_setsLoadedStateWithEmptyGroups() async {
        let fake = FakeTasksClientAdapting()
        let work = LifeArea(id: UUID(), name: "Work", colour: "#123456", sortOrder: 0)
        fake.lifeAreasResult = .success([work])
        fake.tasksResult = .success([makeTask(lifeAreaId: work.id, title: "Open task", status: .open)])
        let sut = TasksService(client: fake)
        await sut.load()

        sut.statusFilter = .done

        XCTAssertEqual(sut.state, .loaded([]))
    }

    func testChangingStatusFilter_beforeLoad_doesNotChangeState() {
        let fake = FakeTasksClientAdapting()
        let sut = TasksService(client: fake)

        sut.statusFilter = .done

        XCTAssertEqual(sut.state, .loading)
        XCTAssertEqual(fake.fetchLifeAreasCallCount, 0)
        XCTAssertEqual(fake.fetchAllTasksCallCount, 0)
    }

    func testLoad_calledAgainAfterFailure_resetsToLoadingThenLoaded() async {
        let fake = FakeTasksClientAdapting()
        fake.lifeAreasResult = .failure(TasksServiceError.fetchFailed("Network error"))
        let sut = TasksService(client: fake)
        await sut.load()
        XCTAssertEqual(sut.state, .failed("Network error"))

        fake.lifeAreasResult = .success([])
        await sut.load()

        XCTAssertEqual(sut.state, .loaded([]))
    }
}
