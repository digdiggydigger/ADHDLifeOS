//
//  FirebaseJournalClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class FirebaseJournalClientAdapterTests: XCTestCase {
    private var store: FakeJournalBackingStore!
    private var adapter: FirebaseJournalClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeJournalBackingStore()
        adapter = FirebaseJournalClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    func testFetchLifeAreas_includesArchivedAreas() async throws {
        _ = try await adapter.fetchLifeAreas()

        XCTAssertEqual(store.includeArchivedArguments, [true], "an entry filed under an archived area must still label")
    }

    func testFetchLifeAreas_wrapsFailureAsAJournalError() async {
        store.fetchLifeAreasError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchLifeAreas()) { error in
            XCTAssertEqual(error as? JournalServiceError, .fetchFailed(Self.notSignedInMessage))
        }
    }

    func testFetchLogs_wrapsFailureAsAJournalError() async {
        store.fetchLogsError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchLogs()) { error in
            XCTAssertEqual(error as? JournalServiceError, .fetchFailed(Self.notSignedInMessage))
        }
    }

    // MARK: - Creating an entry

    /// The composer has no date picker, so `entryDate` is stamped client-side as "now" — and the
    /// same instant is used for `createdAt`, matching the old server-side default.
    func testCreateLog_stampsEntryDateAndCreatedAtWithTheSameInstant() async throws {
        let before = Date()

        let log = try await adapter.createLog(Self.input())

        XCTAssertEqual(log.entryDate, log.createdAt, "one instant, not two clock reads")
        XCTAssertGreaterThanOrEqual(log.entryDate, before)
        XCTAssertLessThanOrEqual(log.entryDate, Date())
    }

    func testCreateLog_persistsTheEntryItReturns() async throws {
        let log = try await adapter.createLog(Self.input(body: "Slept badly, still shipped"))

        XCTAssertEqual(store.appendedLogs, [log])
        XCTAssertEqual(log.body, "Slept badly, still shipped")
    }

    func testCreateLog_carriesTheJournalOnlyFieldsThrough() async throws {
        let lifeAreaId = UUID()
        let input = NormalizedCreateLogInput(
            body: "Reflective entry",
            type: .journal,
            lifeAreaId: lifeAreaId,
            energyLevel: .low,
            moodEmoji: "😮‍💨"
        )

        let log = try await adapter.createLog(input)

        XCTAssertEqual(log.type, .journal)
        XCTAssertEqual(log.lifeAreaId, lifeAreaId)
        XCTAssertEqual(log.energyLevel, .low)
        XCTAssertEqual(log.moodEmoji, "😮‍💨")
    }

    func testCreateLog_wrapsAppendFailureAsAJournalError() async {
        store.appendError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.createLog(Self.input())) { error in
            XCTAssertEqual(error as? JournalServiceError, .fetchFailed(Self.notSignedInMessage))
        }
    }

    private static let notSignedInMessage = FirebaseManagerError.notSignedIn.errorDescription ?? ""

    private static func input(body: String = "Quick log") -> NormalizedCreateLogInput {
        NormalizedCreateLogInput(body: body, type: .log, lifeAreaId: nil, energyLevel: nil, moodEmoji: nil)
    }
}
