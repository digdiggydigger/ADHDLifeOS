//
//  FirebaseNudgesClientAdapterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The only adapter that distinguishes *why* a write failed: a Firestore `notFound` becomes
/// `NudgesServiceError.notFound` so the UI can say "this nudge no longer exists" instead of
/// showing a generic failure. Everything else collapses to `.fetchFailed`.
final class FirebaseNudgesClientAdapterTests: XCTestCase {
    private var store: FakeNudgesBackingStore!
    private var adapter: FirebaseNudgesClientAdapter!

    override func setUp() {
        super.setUp()
        store = FakeNudgesBackingStore()
        store.storedNudge = Self.nudge(label: "Stored label")
        adapter = FirebaseNudgesClientAdapter(store: store)
    }

    override func tearDown() {
        adapter = nil
        store = nil
        super.tearDown()
    }

    // MARK: - Fetch

    func testFetchNudges_returnsTheCollection() async throws {
        store.nudges = [Self.nudge(label: "Stretch")]

        let nudges = try await adapter.fetchNudges()

        XCTAssertEqual(nudges, store.nudges)
    }

    func testFetchNudges_wrapsFailure() async {
        store.fetchNudgesError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(try await adapter.fetchNudges()) { error in
            XCTAssertEqual(error as? NudgesServiceError, .fetchFailed(Self.notSignedInMessage))
        }
    }

    // MARK: - Create

    /// A new nudge is active, has never fired, and gets one instant for both `createdAt` and
    /// `updatedAt` — it has not been "updated" separately from being made.
    func testCreateNudge_startsActiveAndUnfired() async throws {
        let schedule = NudgeSchedule(hour: 9, minute: 30, weekdays: [1, 2, 3, 4, 5])

        let nudge = try await adapter.createNudge(label: "Stretch", schedule: schedule)

        XCTAssertEqual(nudge.label, "Stretch")
        XCTAssertEqual(nudge.schedule, "30 9 * * 1,2,3,4,5", "stored as its cron string, not a structured value")
        XCTAssertTrue(nudge.active)
        XCTAssertNil(nudge.lastFiredAt)
        XCTAssertEqual(nudge.createdAt, nudge.updatedAt)
        XCTAssertEqual(store.createdNudges, [nudge], "the returned nudge must be the one persisted")
    }

    // MARK: - Update: write then re-read

    func testUpdateNudge_returnsTheReReadDocumentNotTheLocalEdit() async throws {
        let id = UUID()
        var payload = NudgeUpdatePayload()
        payload.label = "Locally typed"

        let updated = try await adapter.updateNudge(id: id, payload: payload)

        XCTAssertEqual(updated.label, "Stored label", "the re-read wins over the local edit")
        XCTAssertEqual(store.fetchedIds, [id])
    }

    func testUpdateNudge_forwardsThePayloadVerbatim() async throws {
        let id = UUID()
        var payload = NudgeUpdatePayload()
        payload.active = false

        _ = try await adapter.updateNudge(id: id, payload: payload)

        XCTAssertEqual(store.payloadUpdates.count, 1)
        XCTAssertEqual(store.payloadUpdates.first?.id, id)
        XCTAssertEqual(store.payloadUpdates.first?.payload, payload)
    }

    // MARK: - The notFound distinction

    /// Editing a nudge deleted on another device must say so, not fail generically.
    func testUpdateNudge_firestoreNotFoundBecomesTheTypedNotFoundCase() async {
        store.updateError = Self.firestoreNotFound

        await XCTAssertThrowsErrorAsync(
            try await adapter.updateNudge(id: UUID(), payload: NudgeUpdatePayload())
        ) { error in
            XCTAssertEqual(error as? NudgesServiceError, .notFound)
        }
    }

    func testUpdateNudge_anyOtherFailureStaysGeneric() async {
        store.updateError = FirebaseManagerError.notSignedIn

        await XCTAssertThrowsErrorAsync(
            try await adapter.updateNudge(id: UUID(), payload: NudgeUpdatePayload())
        ) { error in
            XCTAssertEqual(error as? NudgesServiceError, .fetchFailed(Self.notSignedInMessage))
        }
    }

    /// A `notFound` raised by the *re-read* rather than the write maps the same way — the nudge is
    /// equally gone either side of the round trip.
    func testUpdateNudge_notFoundOnTheReReadAlsoMapsToNotFound() async {
        store.fetchNudgeError = Self.firestoreNotFound

        await XCTAssertThrowsErrorAsync(
            try await adapter.updateNudge(id: UUID(), payload: NudgeUpdatePayload())
        ) { error in
            XCTAssertEqual(error as? NudgesServiceError, .notFound)
        }
    }

    // MARK: - markFired

    func testMarkFired_writesBothStampsAndReturnsTheReReadDocument() async throws {
        let id = UUID()

        let nudge = try await adapter.markFired(id: id, existingCompletionDates: [])

        XCTAssertEqual(store.fieldUpdates.count, 1)
        XCTAssertEqual(store.fieldUpdates.first?.id, id)
        XCTAssertEqual(
            store.fieldUpdates.first?.fields.keys.sorted(),
            ["completion_dates", "last_fired_at", "updated_at"]
        )
        XCTAssertEqual(store.fetchedIds, [id])
        XCTAssertEqual(nudge.label, "Stored label")
    }

    func testMarkFired_stampsWithTheCurrentClientClock() async throws {
        let before = Date()

        _ = try await adapter.markFired(id: UUID(), existingCompletionDates: [])

        let stamped = try XCTUnwrap(
            FirestoreDocumentCoder.date(from: store.fieldUpdates.first?.fields["last_fired_at"])
        )
        XCTAssertGreaterThanOrEqual(stamped, before)
        XCTAssertLessThanOrEqual(stamped, Date())
    }

    /// The stamping call appends the firing instant to the array it was handed — the whole
    /// array is written, existing stamps included (F-V3-Nudges).
    func testMarkFired_appendsTheFiringToTheExistingStamps() async throws {
        let earlier = Date(timeIntervalSince1970: 1_700_000_000)

        _ = try await adapter.markFired(id: UUID(), existingCompletionDates: [earlier])

        let stored = try XCTUnwrap(
            (store.fieldUpdates.first?.fields["completion_dates"] as? [Any])?.compactMap {
                FirestoreDocumentCoder.date(from: $0)
            }
        )
        XCTAssertEqual(stored.count, 2)
        XCTAssertEqual(stored.first, earlier)
        XCTAssertEqual(
            stored.last,
            FirestoreDocumentCoder.date(from: store.fieldUpdates.first?.fields["last_fired_at"])
        )
    }

    func testMarkFired_firestoreNotFoundBecomesTheTypedNotFoundCase() async {
        store.updateError = Self.firestoreNotFound

        await XCTAssertThrowsErrorAsync(
            try await adapter.markFired(id: UUID(), existingCompletionDates: [])
        ) { error in
            XCTAssertEqual(error as? NudgesServiceError, .notFound)
        }
    }

    private static let notSignedInMessage = FirebaseManagerError.notSignedIn.errorDescription ?? ""

    private static var firestoreNotFound: Error {
        NSError(domain: FirestoreErrorMapping.errorDomain, code: FirestoreErrorMapping.notFoundCode)
    }

    private static func nudge(label: String) -> Nudge {
        let now = Date(timeIntervalSince1970: 1_755_000_000)
        return Nudge(
            id: UUID(),
            label: label,
            schedule: "30 9 * * 1,2,3,4,5",
            active: true,
            lastFiredAt: nil,
            createdAt: now,
            updatedAt: now
        )
    }
}
