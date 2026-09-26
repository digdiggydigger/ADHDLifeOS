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
    }

    // The three `testSubmitReorder_*` pinned Today's arrange-mode reorder writer. Round 3 took the
    // life areas off Today (`F-E3-OneCardToday`) and the Areas tab reorders through its own editor,
    // so the writer, its payload and `archivedAreas` were retired; `TodayOneCardCallSiteTests`
    // holds their absence (`submitReorder(`, `reorderLifeAreas(`, `LifeAreaReorderPayload`).

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
