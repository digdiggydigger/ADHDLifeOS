//
//  FirebaseLifeAreaDetailClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class FirebaseLifeAreaDetailClientAdapterTests: XCTestCase {
    private var store: FakeLifeAreaDetailBackingStore!
    private var adapter: FirebaseLifeAreaDetailClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeLifeAreaDetailBackingStore()
        adapter = FirebaseLifeAreaDetailClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    /// Both fetches are scoped server-side by a `life_area_id` equality query, per the protocol's
    /// contract — never a fetch-everything-then-filter.
    func testFetchTasks_scopesTheQueryToTheRequestedArea() async throws {
        let lifeAreaId = UUID()

        _ = try await adapter.fetchTasks(lifeAreaId: lifeAreaId)

        XCTAssertEqual(store.taskQueryIds, [lifeAreaId])
    }

    func testFetchTasks_returnsTheQueryResultUnchanged() async throws {
        let task = TaskItem(
            id: UUID(), lifeAreaId: UUID(), title: "Draft the brief",
            status: .open, priority: .p2, dueDate: nil
        )
        store.tasks = [task]

        let tasks = try await adapter.fetchTasks(lifeAreaId: UUID())

        XCTAssertEqual(tasks, [task])
    }

    func testFetchTasks_wrapsFailure() async {
        store.fetchTasksError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchTasks(lifeAreaId: UUID())) { error in
            XCTAssertEqual(error as? LifeAreaDetailServiceError, .fetchFailed(Self.notSignedInMessage))
        }
    }

    func testFetchLogs_scopesTheQueryToTheRequestedArea() async throws {
        let lifeAreaId = UUID()

        _ = try await adapter.fetchLogs(lifeAreaId: lifeAreaId)

        XCTAssertEqual(store.logQueryIds, [lifeAreaId])
    }

    /// The equality query is unordered — a `whereField` combined with an order on a different field
    /// needs a composite index — so newest-first is the adapter's job.
    func testFetchLogs_sortsNewestFirst() async throws {
        store.logs = [
            Self.log(body: "Older", entryDate: Date(timeIntervalSince1970: 1_000)),
            Self.log(body: "Newer", entryDate: Date(timeIntervalSince1970: 2_000))
        ]

        let logs = try await adapter.fetchLogs(lifeAreaId: UUID())

        XCTAssertEqual(logs.map(\.body), ["Newer", "Older"])
    }

    func testFetchLogs_wrapsFailure() async {
        store.fetchLogsError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchLogs(lifeAreaId: UUID())) { error in
            XCTAssertEqual(error as? LifeAreaDetailServiceError, .fetchFailed(Self.notSignedInMessage))
        }
    }

    private static let notSignedInMessage = FirebaseManagerError.notSignedIn.errorDescription ?? ""

    private static func log(body: String, entryDate: Date) -> Log {
        Log(
            id: UUID(),
            lifeAreaId: nil,
            type: .log,
            body: body,
            entryDate: entryDate,
            createdAt: entryDate,
            energyLevel: nil,
            moodEmoji: nil
        )
    }
}
