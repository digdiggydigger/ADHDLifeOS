//
//  FirebaseHomeClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class FirebaseHomeClientAdapterTests: XCTestCase {
    private var store: FakeHomeBackingStore!
    private var adapter: FirebaseHomeClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeHomeBackingStore()
        adapter = FirebaseHomeClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    /// Home needs archived areas too: the pickers Home feeds must still be able to name an area
    /// that has been archived. (The reorder payload that also needed them left with Today's life
    /// areas in `F-E3-OneCardToday`.)
    func testFetchLifeAreas_includesArchivedAreas() async throws {
        store.lifeAreas = [LifeArea(id: UUID(), name: "Admin", colour: "🗂", sortOrder: 0, archived: true)]

        let areas = try await adapter.fetchLifeAreas()

        XCTAssertEqual(store.includeArchivedArguments, [true])
        XCTAssertEqual(areas, store.lifeAreas)
    }

    func testFetchOpenTasks_returnsTheOpenTaskProjection() async throws {
        let summary = TaskSummary(
            id: UUID(), lifeAreaId: UUID(), status: .open, title: "Draft the brief",
            priority: .p1, notes: nil, dueDate: nil
        )
        store.openTasks = [summary]

        let tasks = try await adapter.fetchOpenTasks()

        XCTAssertEqual(tasks, [summary])
    }

    /// `fetchAllTasks` was the Home adapter's 3 uncovered lines (12/15 on 2026-09-07) — the only
    /// method here with no test. Unlike `fetchOpenTasks` it is deliberately UNFILTERED: the daily
    /// summary and the momentum scoreboard both count done work, so a status filter creeping in
    /// here would silently empty them.
    func testFetchAllTasks_returnsEveryTaskIncludingCompletedOnes() async throws {
        let open = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Draft the brief", status: .open, priority: .p2, dueDate: nil
        )
        let done = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Ship it", status: .done, priority: .p1, dueDate: nil
        )
        store.allTasks = [open, done]

        let tasks = try await adapter.fetchAllTasks()

        XCTAssertEqual(tasks, [open, done], "unfiltered — a done task must survive the hop")
        XCTAssertEqual(tasks.filter { $0.status == .done }.count, 1)
    }

    // The two `testReorder_*` pinned Today's arrange-mode write. It left with Today's life areas
    // (`F-E3-OneCardToday`); `TodayOneCardCallSiteTests` holds `reorderLifeAreas(`'s absence.
}
