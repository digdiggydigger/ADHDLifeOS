//
//  TasksServiceTests.swift
//  ADHD LifeOSTests
//

import Combine
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
        let dueToday = TaskItem(
            id: UUID(), lifeAreaId: work.id, title: "Finish report",
            status: .open, priority: .p4, dueDate: .now
        )
        fake.lifeAreasResult = .success([work])
        fake.tasksResult = .success([dueToday])
        let sut = TasksService(client: fake)

        await sut.load()

        // The default filter is the Momentum board (M3), so a due-today task loads into that
        // bucket; the life-area grouping is exercised through the Open/Done/All filters.
        XCTAssertEqual(sut.state, .loaded([
            LifeAreaTaskGroup(
                lifeAreaId: nil, lifeAreaName: "Due today · 1", tasks: [dueToday],
                customId: "momentum-dueToday"
            )
        ]))
        XCTAssertEqual(fake.fetchLifeAreasCallCount, 1)
        XCTAssertEqual(fake.fetchAllTasksCallCount, 1)
    }

    /// F-V3-Tasks-rebuild: the Momentum board shows only Due today / Tomorrow / Closed today —
    /// an undated open task is NOT on it, and lives under the Open filter instead (E's b11 call).
    func testLoad_momentumExcludesUndatedTasks_openFilterShowsThem() async {
        let fake = FakeTasksClientAdapting()
        let work = LifeArea(id: UUID(), name: "Work", colour: "#123456", sortOrder: 0)
        let undated = makeTask(lifeAreaId: work.id, title: "No due date")
        fake.lifeAreasResult = .success([work])
        fake.tasksResult = .success([undated])
        let sut = TasksService(client: fake)

        await sut.load()
        XCTAssertEqual(sut.state, .loaded([]), "Momentum has nothing to say about the long tail")

        sut.statusFilter = .open
        XCTAssertEqual(sut.state, .loaded([
            LifeAreaTaskGroup(lifeAreaId: work.id, lifeAreaName: "Work", tasks: [undated])
        ]))
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

    func testDefaultStatusFilter_isMomentum() {
        let fake = FakeTasksClientAdapting()
        let sut = TasksService(client: fake)

        XCTAssertEqual(sut.statusFilter, .momentum, "the Momentum board opens first (Concept C, M3)")
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

    /// SUGG-b4's quiet-reload rule (E's checklist, 2026-08-26): once content is on screen, a
    /// reload — pull-to-refresh or the app-wide DataChangeSignal — must not flash the loading
    /// state over it; fresh data replaces stale data in place.
    func testReloadAfterSuccess_neverFlashesLoading() async {
        let sut = TasksService(client: FakeTasksClientAdapting())
        await sut.load()

        var sawLoading = false
        let watcher = sut.$state.dropFirst().sink { state in
            if case .loading = state { sawLoading = true }
        }
        await sut.load()
        watcher.cancel()

        XCTAssertFalse(sawLoading, "a reload over loaded content must not flash .loading")
    }
}
