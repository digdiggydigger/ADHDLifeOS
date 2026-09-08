//
//  HomeServiceTests.swift
//  ADHD LifeOSTests
//

import Combine
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class HomeServiceTests: XCTestCase {

    func testInitialState_isLoading() {
        let fake = FakeHomeClientAdapting()
        let sut = HomeService(client: fake)

        XCTAssertEqual(sut.state, .loading)
    }

    func testLoad_success_setsLoadedStateWithComputedCounts() async {
        let fake = FakeHomeClientAdapting()
        let work = LifeArea(id: UUID(), name: "Work", colour: "#123456", sortOrder: 0)
        fake.lifeAreasResult = .success([work])
        fake.openTasksResult = .success([TaskSummary(lifeAreaId: work.id, status: .open)])
        let sut = HomeService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([LifeAreaTaskCount(lifeArea: work, openTaskCount: 1)]))
    }

    // MARK: - Momentum scoreboard data

    func testLoad_fetchesAllTasksForTheScoreboard() async {
        let fake = FakeHomeClientAdapting()
        fake.lifeAreasResult = .success([])
        fake.openTasksResult = .success([])
        let done = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Closed", status: .done,
            priority: .p3, dueDate: nil, completedAt: Date()
        )
        fake.allTasksResult = .success([done])
        let sut = HomeService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.allTasks, [done])
    }

    /// The scoreboard is derived decoration over history — its fetch failing must not take the
    /// whole screen down. This is the FIRST-load case, where there is genuinely nothing known
    /// yet, so the ring reads zero; once a load has landed, a later failure keeps what it landed
    /// (`testLoad_scoreboardFetchFailure_keepsTheLastKnownTasks`).
    func testLoad_scoreboardFetchFailure_stillLoadsTheScreen() async {
        let fake = FakeHomeClientAdapting()
        let work = LifeArea(id: UUID(), name: "Work", colour: "#123456", sortOrder: 0)
        fake.lifeAreasResult = .success([work])
        fake.openTasksResult = .success([])
        fake.allTasksResult = .failure(HomeServiceError.fetchFailed("offline"))
        let sut = HomeService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([LifeAreaTaskCount(lifeArea: work, openTaskCount: 0)]))
        XCTAssertEqual(sut.allTasks, [])
    }

    /// A failed scoreboard fetch is "don't know", never "nothing" — the last-known set stays.
    ///
    /// The arrival card is the loudest consumer and the reason this matters: Home refreshes it
    /// deliberately AFTER `load()` (`HomeView.refreshEverything`), and `ArrivalSurface.refreshed`
    /// re-checks the card it is already holding against these tasks. That rule cannot tell "the
    /// work here closed" from "the fetch failed" — and it should not have to — so an emptied
    /// `allTasks` silently destroys a card the user is looking at, on a pull that only hiccuped.
    /// The Momentum ring, streaks, week charts and the week review read the same property and
    /// would all read zero.
    func testLoad_scoreboardFetchFailure_keepsTheLastKnownTasks() async {
        let fake = FakeHomeClientAdapting()
        let work = LifeArea(id: UUID(), name: "Work", colour: "#123456", sortOrder: 0)
        fake.lifeAreasResult = .success([work])
        fake.openTasksResult = .success([])
        let done = TaskItem(
            id: UUID(), lifeAreaId: work.id, title: "Closed", status: .done,
            priority: .p3, dueDate: nil, completedAt: Date()
        )
        fake.allTasksResult = .success([done])
        let sut = HomeService(client: fake)
        await sut.load()
        XCTAssertEqual(sut.allTasks, [done], "precondition: the first load lands the history")

        fake.allTasksResult = .failure(HomeServiceError.fetchFailed("offline"))
        await sut.load()

        XCTAssertEqual(sut.allTasks, [done])
    }

    func testLoad_emptyData_setsLoadedStateWithZeroCounts() async {
        let fake = FakeHomeClientAdapting()
        let work = LifeArea(id: UUID(), name: "Work", colour: "#123456", sortOrder: 0)
        fake.lifeAreasResult = .success([work])
        fake.openTasksResult = .success([])
        let sut = HomeService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([LifeAreaTaskCount(lifeArea: work, openTaskCount: 0)]))
        XCTAssertEqual(fake.fetchLifeAreasCallCount, 1)
        XCTAssertEqual(fake.fetchOpenTasksCallCount, 1)
    }

    func testLoad_lifeAreasFetchFails_setsFailedState() async {
        let fake = FakeHomeClientAdapting()
        fake.lifeAreasResult = .failure(HomeServiceError.fetchFailed("Network error"))
        let sut = HomeService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .failed("Network error"))
    }

    func testLoad_openTasksFetchFails_setsFailedState() async {
        let fake = FakeHomeClientAdapting()
        fake.openTasksResult = .failure(HomeServiceError.fetchFailed("Network error"))
        let sut = HomeService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .failed("Network error"))
    }

    func testLoad_calledAgainAfterFailure_resetsToLoadingThenLoaded() async {
        let fake = FakeHomeClientAdapting()
        fake.lifeAreasResult = .failure(HomeServiceError.fetchFailed("Network error"))
        let sut = HomeService(client: fake)
        await sut.load()
        XCTAssertEqual(sut.state, .failed("Network error"))

        let work = LifeArea(id: UUID(), name: "Work", colour: "#123456", sortOrder: 0)
        fake.lifeAreasResult = .success([work])
        await sut.load()

        XCTAssertEqual(sut.state, .loaded([LifeAreaTaskCount(lifeArea: work, openTaskCount: 0)]))
    }

    // MARK: - Archived-aware load (Home-reorder block)

    func testLoad_gridExcludesArchivedAreas_butFullSetKept() async {
        let fake = FakeHomeClientAdapting()
        let work = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)
        let archived = LifeArea(id: UUID(), name: "Old", colour: "🗂️", sortOrder: 1, archived: true)
        fake.lifeAreasResult = .success([work, archived])
        fake.openTasksResult = .success([])
        let sut = HomeService(client: fake)

        await sut.load()

        // The grid (loaded counts) shows active only...
        XCTAssertEqual(sut.state, .loaded([LifeAreaTaskCount(lifeArea: work, openTaskCount: 0)]))
        XCTAssertEqual(sut.activeAreas.map(\.id), [work.id])
        // ...but the full set (incl. archived) is retained for the pickers fed from Home.
        XCTAssertEqual(sut.lifeAreas.map(\.id), [work.id, archived.id])
        XCTAssertEqual(sut.archivedAreas.map(\.id), [archived.id])
    }

    // MARK: - Reorder serialisation (TRAP 6)

    func testSubmitReorder_serialisesAndCoalescesToLatest() async {
        let fake = FakeHomeClientAdapting()
        fake.blocksReorder = true
        let sut = HomeService(client: fake)
        let orderA = [UUID(), UUID()]
        let orderB = [UUID(), UUID()]

        // First reorder starts and suspends "in flight" at the fake's gate.
        let first = Task { await sut.submitReorder(orderA) }
        await yield(until: { fake.reorderCallCount == 1 })

        // A second ordering submitted while the first is in flight must NOT start a second call —
        // it is coalesced and picked up only after the first finishes.
        await sut.submitReorder(orderB)
        XCTAssertEqual(fake.reorderCallCount, 1, "second reorder must not run while the first is in flight")

        // Release the first; the coalesced latest (orderB) then fires as the one follow-up call.
        fake.releaseOneReorder()
        await yield(until: { fake.reorderCallCount == 2 })
        fake.releaseOneReorder()
        await first.value

        XCTAssertEqual(fake.reorderOrders, [orderA, orderB],
                       "at most two calls; the last carries the latest ordering")
    }

    func testSubmitReorder_buildsCompletePayloadActiveFirstThenArchived() async {
        let fake = FakeHomeClientAdapting()
        let one = LifeArea(id: UUID(), name: "A", colour: "🎯", sortOrder: 0)
        let two = LifeArea(id: UUID(), name: "B", colour: "🎯", sortOrder: 1)
        let archived = LifeArea(id: UUID(), name: "Old", colour: "🗂️", sortOrder: 2, archived: true)
        fake.lifeAreasResult = .success([one, two, archived])
        fake.openTasksResult = .success([])
        let sut = HomeService(client: fake)
        await sut.load()

        await sut.submitReorder(activeInNewOrder: [two, one])

        // TRAP 1: archived id appended so the payload is the complete current set.
        XCTAssertEqual(fake.reorderOrders, [[two.id, one.id, archived.id]])
    }

    func testSubmitReorder_failure_surfacesMessageAndReloadsServerOrder() async {
        let fake = FakeHomeClientAdapting()
        let work = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0)
        fake.lifeAreasResult = .success([work])
        fake.openTasksResult = .success([])
        fake.reorderResult = .failure(HomeServiceError.fetchFailed("order is missing id(s)"))
        let sut = HomeService(client: fake)
        await sut.load()

        await sut.submitReorder(activeInNewOrder: [work])

        XCTAssertEqual(sut.reorderErrorMessage, "order is missing id(s)")
        // Reverted to the server's order (a reload happened after the failure).
        XCTAssertEqual(sut.state, .loaded([LifeAreaTaskCount(lifeArea: work, openTaskCount: 0)]))
    }

    private func yield(until condition: @escaping () -> Bool) async {
        for _ in 0..<10_000 {
            if condition() { return }
            await Task.yield()
        }
        XCTFail("condition was never met")
    }

    /// SUGG-b4's quiet-reload rule (E's checklist, 2026-08-26): once content is on screen, a
    /// reload — pull-to-refresh or the app-wide DataChangeSignal — must not flash the loading
    /// state over it; fresh data replaces stale data in place.
    func testReloadAfterSuccess_neverFlashesLoading() async {
        let sut = HomeService(client: FakeHomeClientAdapting())
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
