//
//  FirebaseFocusSessionAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The write and read halves of focus history. Thin, but the collection it targets is the one whose
/// security rules were the last thing pending after the cutover — so "which call goes where" is
/// worth pinning even though there is no branching.
final class FirebaseFocusSessionAdapterTests: XCTestCase {
    private var store: FakeFocusSessionBackingStore!
    private var adapter: FirebaseFocusSessionAdapter!

    override func setUp() {
        super.setUp()
        store = FakeFocusSessionBackingStore()
        adapter = FirebaseFocusSessionAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    func testLogCompletedSession_persistsTheSessionUnchanged() async throws {
        let session = Self.session(taskTitle: "Draft the brief", focusedSeconds: 1_310)

        try await adapter.logCompletedSession(session)

        XCTAssertEqual(store.savedSessions, [session], "a finished sprint is a historical fact — nothing is derived")
    }

    func testLogCompletedSession_propagatesFailure() async {
        store.saveError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.logCompletedSession(Self.session())) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    /// History starts empty and accrues — an empty read is the expected state on a fresh account,
    /// not a failure.
    func testFetchHistory_anEmptyHistoryIsNotAnError() async throws {
        let history = try await adapter.fetchHistory()

        XCTAssertTrue(history.isEmpty)
        XCTAssertEqual(store.fetchCallCount, 1)
    }

    func testFetchHistory_returnsTheStoredSessionsInTheOrderGiven() async throws {
        let newer = Self.session(taskTitle: "Newer")
        let older = Self.session(taskTitle: "Older")
        store.history = [newer, older]

        let history = try await adapter.fetchHistory()

        XCTAssertEqual(history.map(\.taskTitle), ["Newer", "Older"], "ordering is the query's job, not the adapter's")
    }

    func testFetchHistory_propagatesFailure() async {
        store.fetchError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchHistory()) { error in
            XCTAssertEqual(error as? FirebaseManagerError, .notSignedIn)
        }
    }

    private static func session(
        taskTitle: String = "Draft the brief",
        focusedSeconds: Int = 1_500
    ) -> CompletedFocusSession {
        CompletedFocusSession(
            id: UUID(),
            taskId: UUID(),
            taskTitle: taskTitle,
            lifeAreaEmoji: "💼",
            plannedSeconds: 1_500,
            focusedSeconds: focusedSeconds,
            checkpointsReached: 2,
            completedNaturally: focusedSeconds >= 1_500,
            startedAt: Date(timeIntervalSince1970: 1_755_000_000),
            endedAt: Date(timeIntervalSince1970: 1_755_001_500)
        )
    }
}
