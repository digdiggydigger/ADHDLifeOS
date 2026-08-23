//
//  FirebaseRemindersClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class FirebaseRemindersClientAdapterTests: XCTestCase {
    private var store: FakeRemindersBackingStore!
    private var adapter: FirebaseRemindersClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeRemindersBackingStore()
        adapter = FirebaseRemindersClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    /// `users/{uid}/reminders` starts empty and stays empty until something writes to it. That must
    /// read as an empty list, not an error — the screen renders its empty state rather than 404ing.
    func testFetchReminders_anEmptyCollectionIsNotAnError() async throws {
        let reminders = try await adapter.fetchReminders()

        XCTAssertTrue(reminders.isEmpty)
        XCTAssertEqual(store.fetchCallCount, 1)
    }

    func testFetchReminders_returnsWhatTheCollectionHolds() async throws {
        let reminder = Reminder(id: "abc", type: .reminder, title: "Ring the dentist")
        store.reminders = [reminder]

        let reminders = try await adapter.fetchReminders()

        XCTAssertEqual(reminders, [reminder])
    }

    func testFetchReminders_wrapsFailure() async {
        store.fetchError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchReminders()) { error in
            XCTAssertEqual(
                error as? RemindersServiceError,
                .fetchFailed(FirebaseManagerError.notSignedIn.errorDescription ?? "")
            )
        }
    }
}
