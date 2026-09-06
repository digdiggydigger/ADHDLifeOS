//
//  FirebaseRoutineRunRecorderTests.swift
//  ADHD LifeOSTests
//
//  The production `RoutineRunRecording` over its `RoutineRunsBackingStore` (the house adapter
//  seam, F-RoutineRecord-1). The offer is a whole-document create through the codec; every
//  later transition is a PARTIAL update whose keys are literals in `FirestoreFieldPayloads`,
//  asserted here by spelling because a wrong key writes a field nothing reads and raises
//  nothing. The partial updates are what keep a swipe from clobbering a tap.
//

import XCTest
@testable import ADHD_LifeOS

final class FirebaseRoutineRunRecorderTests: XCTestCase {
    private let noon = Date(timeIntervalSince1970: 1_756_296_000)
    private var store: FakeRoutineRunsBackingStore!
    private var sut: FirebaseRoutineRunRecorder!

    override func setUp() {
        super.setUp()
        store = FakeRoutineRunsBackingStore()
        sut = FirebaseRoutineRunRecorder(store: store)
    }

    func testOffered_createsTheWholeDocument() async throws {
        let record = RoutineRunRecord.offered(gymRun(), now: noon)

        try await sut.offered(record)

        XCTAssertEqual(store.created, [record])
        XCTAssertTrue(store.updates.isEmpty, "an offer is a create, never an update")
    }

    func testStarted_isAPartialUpdateStampingTheTap() async throws {
        let runId = UUID()

        try await sut.started(runId: runId, at: noon)

        let update = try XCTUnwrap(store.updates.first)
        XCTAssertEqual(update.id, runId)
        XCTAssertEqual(update.fields.keys.sorted(), ["dismissal_method", "started_at", "status", "updated_at"])
        XCTAssertEqual(update.fields["status"] as? String, "started")
        XCTAssertEqual(update.fields["dismissal_method"] as? String, "tap")
        XCTAssertEqual(FirestoreDocumentCoder.date(from: update.fields["started_at"]), noon)
        XCTAssertTrue(store.created.isEmpty)
    }

    func testDismissed_isAPartialUpdateNamingTheSwipe() async throws {
        let runId = UUID()

        try await sut.dismissed(runId: runId, at: noon)

        let update = try XCTUnwrap(store.updates.first)
        XCTAssertEqual(update.fields.keys.sorted(), ["dismissal_method", "dismissed_at", "status", "updated_at"])
        XCTAssertEqual(update.fields["status"] as? String, "dismissed")
        XCTAssertEqual(update.fields["dismissal_method"] as? String, "swipe")
        XCTAssertEqual(FirestoreDocumentCoder.date(from: update.fields["dismissed_at"]), noon)
    }

    func testExpired_isAPartialUpdateNamingTheTimeout() async throws {
        let runId = UUID()

        try await sut.expired(runId: runId, at: noon)

        let update = try XCTUnwrap(store.updates.first)
        XCTAssertEqual(update.fields.keys.sorted(), ["dismissal_method", "expired_at", "status", "updated_at"])
        XCTAssertEqual(update.fields["status"] as? String, "expired")
        XCTAssertEqual(update.fields["dismissal_method"] as? String, "timeout")
        XCTAssertEqual(FirestoreDocumentCoder.date(from: update.fields["expired_at"]), noon)
    }

    func testProgressed_writesTheStepsAndEveryCountFromTheRun() async throws {
        var run = gymRun()
        run.activatedAt = noon
        run = PlaceRoutineProgress.marking(run, stepAt: 1, as: .done, at: noon.addingTimeInterval(90))
        run = PlaceRoutineProgress.marking(run, stepAt: 2, as: .skipped, at: noon.addingTimeInterval(100))

        try await sut.progressed(run, at: noon.addingTimeInterval(100))

        let update = try XCTUnwrap(store.updates.first)
        XCTAssertEqual(update.id, run.id)
        XCTAssertEqual(update.fields.keys.sorted(), [
            "auto_steps_count", "completed_steps_count", "last_interaction_at", "skipped_steps_count",
            "steps", "time_spent_seconds", "total_steps_count", "updated_at"
        ])
        XCTAssertEqual(update.fields["completed_steps_count"] as? Int, 2)
        XCTAssertEqual(update.fields["skipped_steps_count"] as? Int, 1)
        XCTAssertEqual(update.fields["time_spent_seconds"] as? Int, 100)
        XCTAssertEqual(
            FirestoreDocumentCoder.date(from: update.fields["last_interaction_at"]),
            noon.addingTimeInterval(100)
        )
        let steps = try XCTUnwrap(update.fields["steps"] as? [[String: Any]])
        XCTAssertEqual(steps.map { $0["state"] as? String }, ["autoDone", "done", "skipped"])
        XCTAssertEqual(steps[1]["action_id"] as? String, run.steps[1].action.id.uuidString)
        XCTAssertEqual(
            FirestoreDocumentCoder.date(from: steps[1]["resolved_at"]), noon.addingTimeInterval(90)
        )
        XCTAssertNil(update.fields["status"], "progress never moves the phase")
        XCTAssertNil(update.fields["started_at"], "and never re-stamps the tap")
    }

    func testEnded_isAPartialUpdateWithTheReason() async throws {
        let runId = UUID()

        try await sut.ended(runId: runId, reason: .leftPlace, at: noon)

        let update = try XCTUnwrap(store.updates.first)
        XCTAssertEqual(update.fields.keys.sorted(), ["end_reason", "ended_at", "status", "updated_at"])
        XCTAssertEqual(update.fields["status"] as? String, "ended")
        XCTAssertEqual(update.fields["end_reason"] as? String, "left_place")
        XCTAssertEqual(FirestoreDocumentCoder.date(from: update.fields["ended_at"]), noon)
    }

    func testErrors_propagateSoTheSiteCanDecideWhatToDoWithThem() async {
        store.updateError = URLError(.notConnectedToInternet)

        do {
            try await sut.started(runId: UUID(), at: noon)
            XCTFail("a failed write must not be swallowed here — the site owns that decision")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }

    // MARK: - Fixture

    private func gymRun() -> RoutineRun {
        let gymId = UUID()
        let actions = [
            PlaceAction(id: UUID(), direction: .arrival, kind: .journalLine(body: "Leg day")),
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "spotify", displayName: "Spotify")),
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "gym", displayName: "Gym"))
        ]
        return RoutineRun.make(
            event: PlaceTriggerEvent(placeId: gymId, kind: .arrival, occurredAt: noon.addingTimeInterval(-60)),
            entry: AtPlaceSnapshot.PlaceEntry(
                placeId: gymId, displayName: "Gym 🏋️", openTaskTitles: [],
                arrivalMessage: nil, actions: actions, latitude: nil, longitude: nil
            ),
            plan: PlaceRoutinePlan.make(actions, for: .arrival)
        )
    }
}
