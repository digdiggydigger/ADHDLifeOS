//
//  FirebaseTasksClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `FirebaseTasksClientAdapter` is genuinely thin — four methods, no branching. These tests pin the
/// two things that can still be wrong in a pass-through: which underlying call it forwards to, and
/// what it forwards. The field dictionary those writes produce is covered separately, in
/// `FirestoreFieldPayloadsTests`.
final class FirebaseTasksClientAdapterTests: XCTestCase {
    private var store: FakeTasksBackingStore!
    private var adapter: FirebaseTasksClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeTasksBackingStore()
        adapter = FirebaseTasksClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    /// Archived areas are included: a task filed under an area archived later must still resolve
    /// its area rather than rendering unlabelled.
    func testFetchLifeAreas_includesArchivedAreas() async throws {
        let area = LifeArea(id: UUID(), name: "Admin", colour: "🗂", sortOrder: 0, archived: true)
        store.lifeAreas = [area]

        let areas = try await adapter.fetchLifeAreas()

        XCTAssertEqual(store.includeArchivedArguments, [true])
        XCTAssertEqual(areas, [area])
    }

    func testFetchAllTasks_returnsTheStoresTasksUnchanged() async throws {
        let tasks = [Self.task(title: "First"), Self.task(title: "Second")]
        store.tasks = tasks

        let fetched = try await adapter.fetchAllTasks()

        XCTAssertEqual(fetched, tasks, "ordering is the query's job — the adapter must not re-sort")
        XCTAssertEqual(store.fetchTasksCallCount, 1)
    }

    func testSetStatus_forwardsTheIdAndStatus() async throws {
        let id = UUID()

        try await adapter.setStatus(taskId: id, status: .done)

        XCTAssertEqual(store.statusWrites.count, 1)
        XCTAssertEqual(store.statusWrites.first?.id, id)
        XCTAssertEqual(store.statusWrites.first?.status, .done)
    }

    /// The completion stamp is the **client's** clock, not `serverTimestamp()` — "completed today"
    /// is day-granular and the day that matters is the user's local one.
    func testSetStatus_stampsWithTheCurrentClientClock() async throws {
        let before = Date()

        try await adapter.setStatus(taskId: UUID(), status: .done)

        let stamped = try XCTUnwrap(store.statusWrites.first?.now)
        XCTAssertGreaterThanOrEqual(stamped, before)
        XCTAssertLessThanOrEqual(stamped, Date())
    }

    func testSetStatus_propagatesFailure() async {
        store.setStatusError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.setStatus(taskId: UUID(), status: .done)) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    func testDeleteTask_forwardsTheId() async throws {
        let id = UUID()

        try await adapter.deleteTask(taskId: id)

        XCTAssertEqual(store.deletedIds, [id])
    }

    func testDeleteTask_propagatesFailure() async {
        store.deleteError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.deleteTask(taskId: UUID())) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    private static func task(title: String) -> TaskItem {
        TaskItem(
            id: UUID(),
            lifeAreaId: nil,
            title: title,
            status: .open,
            priority: .p2,
            dueDate: nil
        )
    }
}
