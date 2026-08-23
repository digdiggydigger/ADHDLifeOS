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

    /// Home needs archived areas too: the reorder payload must carry the COMPLETE ordering, so an
    /// archived area missing from the fetch would be missing from the write.
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

    /// TRAP 2 from `HomeClientAdapting`: one bulk write, never N per-row updates. The store's
    /// `reorderLifeAreas` is a single atomic batch, so "one call" is the assertion that protects it.
    func testReorder_isASingleBulkWriteCarryingTheWholeOrdering() async throws {
        let order = [UUID(), UUID(), UUID()]

        try await adapter.reorder(order: order)

        XCTAssertEqual(store.reorderCalls.count, 1, "must never fan out into per-row writes")
        XCTAssertEqual(store.reorderCalls.first, order, "the complete ordering is passed through unchanged")
    }

    func testReorder_propagatesFailure() async {
        store.reorderError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.reorder(order: [UUID()])) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }
}
