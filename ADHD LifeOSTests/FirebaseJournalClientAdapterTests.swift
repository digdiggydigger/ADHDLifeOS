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

    // MARK: - Composer tags (E's 2026-08-25 note)

    /// Tags ride the CREATE payload — `firestore.rules` denies update on logs, so there is no
    /// arrayUnion path; the document is born with its membership or never has one.
    func testCreateLog_carriesTagsOntoTheStoredLog() async throws {
        let tagIds = [UUID(), UUID()]
        let input = NormalizedCreateLogInput(
            body: "Tagged", type: .log, lifeAreaId: nil, tagIds: tagIds
        )

        let created = try await adapter.createLog(input)

        XCTAssertEqual(created.tagIds, tagIds)
        XCTAssertEqual(store.appendedLogs.first?.tagIds, tagIds)
    }

    func testCreateLog_noTagsStoresNilNotAnEmptyArray() async throws {
        let input = NormalizedCreateLogInput(body: "Plain", type: .log, lifeAreaId: nil)

        let created = try await adapter.createLog(input)

        XCTAssertNil(created.tagIds, "an untagged entry must not write an empty tag_ids field")
    }

    func testFetchAllTags_passesTheStoreListThrough() async throws {
        let tag = Tag(id: UUID(), name: "errands")
        store.allTags = [tag]

        let fetched = try await adapter.fetchAllTags()

        XCTAssertEqual(fetched, [tag])
    }

    func testCreateTag_passesTheDedupedTagThrough() async throws {
        let tag = Tag(id: UUID(), name: "deep-work")
        store.createTagResult = tag

        let created = try await adapter.createTag(name: "deep-work")

        XCTAssertEqual(created, tag)
        XCTAssertEqual(store.createdTagNames, ["deep-work"])
    }

    func testTagFetchAndCreate_wrapFailuresAsJournalErrors() async {
        store.fetchAllTagsError = FirebaseManagerError.notSignedIn
        store.createTagError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchAllTags()) { error in
            XCTAssertEqual(error as? JournalServiceError, .fetchFailed(Self.notSignedInMessage))
        }
        await XCTAssertThrowsErrorAsync(try await adapter.createTag(name: "x")) { error in
            XCTAssertEqual(error as? JournalServiceError, .fetchFailed(Self.notSignedInMessage))
        }
    }

    // MARK: - The timeline's side streams (E's 2026-08-25 note)

    func testFetchFocusSessions_passesTheStoreListThrough() async throws {
        let sprint = CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Draft", lifeAreaEmoji: "💼",
            plannedSeconds: 1_500, focusedSeconds: 1_500, checkpointsReached: 0,
            completedNaturally: true, startedAt: Date(timeIntervalSince1970: 0),
            endedAt: Date(timeIntervalSince1970: 1_500)
        )
        store.focusSessions = [sprint]

        let fetched = try await adapter.fetchFocusSessions()

        XCTAssertEqual(fetched, [sprint])
    }

    func testFetchFocusSessions_wrapsFailureAsAJournalError() async {
        store.fetchFocusSessionsError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchFocusSessions()) { error in
            XCTAssertEqual(error as? JournalServiceError, .fetchFailed(Self.notSignedInMessage))
        }
    }

    func testFetchCaptures_passesTheStoreListThrough() async throws {
        let capture = Capture(
            id: UUID(), content: "stray thought", kind: .note, processed: false,
            createdAt: Date(timeIntervalSince1970: 100)
        )
        store.captures = [capture]

        let fetched = try await adapter.fetchCaptures()

        XCTAssertEqual(fetched, [capture])
    }

    func testFetchCaptures_wrapsFailureAsAJournalError() async {
        store.fetchCapturesError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchCaptures()) { error in
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
