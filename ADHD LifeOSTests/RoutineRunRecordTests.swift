//
//  RoutineRunRecordTests.swift
//  ADHD LifeOSTests
//
//  The durable routine record (F-RoutineRecord-1-Ledger): what one `routine_runs` document
//  says, derived from the live `RoutineRun` and never re-deciding anything the screen already
//  decided. Every wire spelling is a literal here on purpose — deriving it from `CodingKeys`
//  would make the test agree with the bug (the `FirestoreDocumentCoderTests` rule).
//

import XCTest
@testable import ADHD_LifeOS

final class RoutineRunRecordTests: XCTestCase {
    private let noon = Date(timeIntervalSince1970: 1_756_296_000)
    private let gymId = UUID()

    // MARK: - Offered: frozen from the run

    func testOffered_freezesTheRunAndStartsInTheOfferedPhase() {
        let run = gymRun()

        let record = RoutineRunRecord.offered(run, now: noon.addingTimeInterval(1))

        XCTAssertEqual(record.id, run.id, "the document id IS the run key — one key everywhere")
        XCTAssertEqual(record.placeId, gymId)
        XCTAssertEqual(record.direction, .arrival)
        XCTAssertEqual(record.displayName, "Gym 🏋️")
        XCTAssertEqual(record.customMessage, "Time to train")
        XCTAssertEqual(record.offeredAt, noon, "offered_at is the CROSSING, not the write")
        XCTAssertEqual(record.phase, .offered)
        XCTAssertEqual(record.status, .offered)
        XCTAssertNil(record.startedAt)
        XCTAssertNil(record.dismissalMethod)
        XCTAssertEqual(record.createdAt, noon.addingTimeInterval(1))
    }

    func testOffered_carriesEveryStepWithItsTitleKindAndState() {
        let run = gymRun()

        let record = RoutineRunRecord.offered(run, now: noon)

        XCTAssertEqual(record.steps.map(\.actionId), run.steps.map(\.action.id))
        XCTAssertEqual(record.steps.map(\.title), ["Journal \u{201C}Leg day\u{201D}", "Open Spotify", "Open Gym"])
        XCTAssertEqual(record.steps.map(\.kind), ["journal_line", "open_app", "open_app"])
        XCTAssertEqual(record.steps.map(\.state), [.autoDone, .pending, .pending])
        XCTAssertEqual(record.steps.map(\.resolvedAt), [nil, nil, nil])
    }

    func testOffered_countsAutoStepsAsCompletedFromTheStart() {
        let record = RoutineRunRecord.offered(gymRun(), now: noon)

        XCTAssertEqual(record.totalStepsCount, 3)
        XCTAssertEqual(record.autoStepsCount, 1)
        XCTAssertEqual(record.completedStepsCount, 1, "auto-done counts — the screen's own rule")
        XCTAssertEqual(record.skippedStepsCount, 0)
        XCTAssertEqual(record.timeSpentSeconds, 0)
        XCTAssertNil(record.lastInteractionAt)
    }

    // MARK: - Transitions

    func testStarted_stampsTheTapAndNamesItAsTheDismissalMethod() {
        var record = RoutineRunRecord.offered(gymRun(), now: noon)

        record.started(at: noon.addingTimeInterval(60))

        XCTAssertEqual(record.startedAt, noon.addingTimeInterval(60))
        XCTAssertEqual(record.dismissalMethod, .tap)
        XCTAssertEqual(record.status, .started)
        XCTAssertEqual(record.phase, .started)
    }

    func testDismissed_isASwipe() {
        var record = RoutineRunRecord.offered(gymRun(), now: noon)

        record.dismissed(at: noon.addingTimeInterval(60))

        XCTAssertEqual(record.dismissedAt, noon.addingTimeInterval(60))
        XCTAssertEqual(record.dismissalMethod, .swipe)
        XCTAssertEqual(record.phase, .dismissed)
    }

    func testExpired_isATimeout() {
        var record = RoutineRunRecord.offered(gymRun(), now: noon)

        record.expired(at: noon.addingTimeInterval(7_200))

        XCTAssertEqual(record.expiredAt, noon.addingTimeInterval(7_200))
        XCTAssertEqual(record.dismissalMethod, .timeout)
        XCTAssertEqual(record.phase, .expired)
    }

    func testEnded_stampsTheReason() {
        var record = RoutineRunRecord.offered(gymRun(), now: noon)
        record.started(at: noon.addingTimeInterval(60))

        record.ended(at: noon.addingTimeInterval(600), reason: .leftPlace)

        XCTAssertEqual(record.endedAt, noon.addingTimeInterval(600))
        XCTAssertEqual(record.endReason, .leftPlace)
        XCTAssertEqual(record.phase, .ended)
    }

    /// The stamps are the truth, `status` is the console's convenience: a document that somehow
    /// carries both a `dismissed_at` and a `started_at` was started — a swipe cannot undo a tap.
    func testPhase_isDerivedFromTheStamps_startedOutranksAStrayDismissal() {
        var record = RoutineRunRecord.offered(gymRun(), now: noon)
        record.dismissed(at: noon.addingTimeInterval(30))
        record.started(at: noon.addingTimeInterval(60))

        XCTAssertEqual(record.phase, .started)
    }

    func testPhase_endedOutranksEverything() {
        var record = RoutineRunRecord.offered(gymRun(), now: noon)
        record.started(at: noon.addingTimeInterval(60))
        record.expired(at: noon.addingTimeInterval(90))
        record.ended(at: noon.addingTimeInterval(120), reason: .completed)

        XCTAssertEqual(record.phase, .ended)
    }

    // MARK: - Progress: one truth with the screen

    func testProgressed_completedCountIsTheScreensDoneCount() {
        let base = gymRun()
        var run = base
        run.activatedAt = noon.addingTimeInterval(60)
        run = PlaceRoutineProgress.marking(run, stepAt: 1, as: .done, at: noon.addingTimeInterval(120))
        run = PlaceRoutineProgress.marking(run, stepAt: 2, as: .skipped, at: noon.addingTimeInterval(150))
        var record = RoutineRunRecord.offered(base, now: noon)
        record.started(at: noon.addingTimeInterval(60))

        record.progressed(to: run)

        XCTAssertEqual(record.completedStepsCount, PlaceRoutineProgress.doneCount(run))
        XCTAssertEqual(record.completedStepsCount, 2)
        XCTAssertEqual(record.skippedStepsCount, 1)
        XCTAssertEqual(record.steps.map(\.state), [.autoDone, .done, .skipped])
        XCTAssertEqual(
            record.steps.map(\.resolvedAt),
            [nil, noon.addingTimeInterval(120), noon.addingTimeInterval(150)]
        )
        XCTAssertEqual(record.lastInteractionAt, noon.addingTimeInterval(150))
    }

    /// `time_spent_seconds` runs to the LAST STEP INTERACTION. A run ended by a departure an
    /// hour later, or left open on a screen, must not claim that hour.
    func testProgressed_timeSpentRunsToTheLastInteractionNotTheEnd() {
        let base = gymRun()
        var run = base
        run.activatedAt = noon.addingTimeInterval(60)
        run = PlaceRoutineProgress.marking(run, stepAt: 1, as: .done, at: noon.addingTimeInterval(180))
        var record = RoutineRunRecord.offered(base, now: noon)
        record.started(at: noon.addingTimeInterval(60))

        record.progressed(to: run)
        record.ended(at: noon.addingTimeInterval(3_660), reason: .leftPlace)

        XCTAssertEqual(record.timeSpentSeconds, 120)
    }

    func testProgressed_undoClearsTheStepsStampAndCounts() {
        let base = gymRun()
        var run = base
        run.activatedAt = noon.addingTimeInterval(60)
        run = PlaceRoutineProgress.marking(run, stepAt: 1, as: .done, at: noon.addingTimeInterval(120))
        run = PlaceRoutineProgress.marking(run, stepAt: 1, as: .pending, at: noon.addingTimeInterval(130))
        var record = RoutineRunRecord.offered(base, now: noon)
        record.started(at: noon.addingTimeInterval(60))

        record.progressed(to: run)

        XCTAssertEqual(record.steps[1].state, .pending)
        XCTAssertNil(record.steps[1].resolvedAt, "an undone step has not been resolved")
        XCTAssertEqual(record.completedStepsCount, 1)
    }

    // MARK: - The wire

    func testEncoding_isSnakeCasedLikeEveryNewCollection() throws {
        var record = RoutineRunRecord.offered(gymRun(), now: noon)
        record.started(at: noon.addingTimeInterval(60))

        let document = try FirestoreDocumentCoder.encode(record)

        XCTAssertEqual(document["place_id"] as? String, gymId.uuidString)
        XCTAssertEqual(document["direction"] as? String, "arrival")
        XCTAssertEqual(document["display_name"] as? String, "Gym 🏋️")
        XCTAssertEqual(document["custom_message"] as? String, "Time to train")
        XCTAssertEqual(document["status"] as? String, "started")
        XCTAssertEqual(FirestoreDocumentCoder.date(from: document["offered_at"]), noon)
        XCTAssertEqual(FirestoreDocumentCoder.date(from: document["started_at"]), noon.addingTimeInterval(60))
        XCTAssertEqual(document["dismissal_method"] as? String, "tap")
        XCTAssertEqual(document["total_steps_count"] as? Int, 3)
        XCTAssertEqual(document["auto_steps_count"] as? Int, 1)
        XCTAssertEqual(document["completed_steps_count"] as? Int, 1)
        XCTAssertEqual(document["skipped_steps_count"] as? Int, 0)
        XCTAssertEqual(document["time_spent_seconds"] as? Int, 0)
        XCTAssertNotNil(document["created_at"])
        XCTAssertNotNil(document["updated_at"])
        let steps = try XCTUnwrap(document["steps"] as? [[String: Any]])
        XCTAssertEqual(steps.count, 3)
        XCTAssertEqual(steps[0]["action_id"] as? String, gymRunActions[0].id.uuidString)
        XCTAssertEqual(steps[0]["kind"] as? String, "journal_line")
        XCTAssertEqual(steps[0]["state"] as? String, "autoDone")

        XCTAssertNil(document["placeId"], "camelCase belongs to captures alone")
        XCTAssertNil(document["offeredAt"])
        XCTAssertNil(document["displayName"])
        XCTAssertNil(document["completedStepsCount"])
        XCTAssertNil(steps[0]["actionId"])
    }

    func testEncoding_endReasonIsSnakeCased() throws {
        var record = RoutineRunRecord.offered(gymRun(), now: noon)
        record.started(at: noon.addingTimeInterval(60))
        record.ended(at: noon.addingTimeInterval(600), reason: .leftPlace)

        let document = try FirestoreDocumentCoder.encode(record)

        XCTAssertEqual(document["end_reason"] as? String, "left_place")
        XCTAssertEqual(FirestoreDocumentCoder.date(from: document["ended_at"]), noon.addingTimeInterval(600))
    }

    func testRoundTrip_throughTheRealCodec() throws {
        let base = gymRun()
        var run = base
        run.activatedAt = noon.addingTimeInterval(60)
        run = PlaceRoutineProgress.marking(run, stepAt: 1, as: .done, at: noon.addingTimeInterval(120))
        var record = RoutineRunRecord.offered(base, now: noon)
        record.started(at: noon.addingTimeInterval(60))
        record.progressed(to: run)
        record.ended(at: noon.addingTimeInterval(600), reason: .completed)

        let document = try FirestoreDocumentCoder.encode(record)
        let decoded = try FirestoreDocumentCoder.decode(RoutineRunRecord.self, from: document)

        XCTAssertEqual(decoded, record)
    }

    /// The step's `kind` is the action's own wire name — the same string the `places` document
    /// stores — so a future reader can join a step back to the action kind without a table.
    func testWireKindName_isTheActionsOwnWireSpelling() {
        XCTAssertEqual(gymRunActions[0].wireKindName, "journal_line")
        XCTAssertEqual(gymRunActions[1].wireKindName, "open_app")
        XCTAssertEqual(
            PlaceAction(id: UUID(), direction: .arrival, kind: .unsupported(rawKind: "teleport", payload: [:]))
                .wireKindName,
            "teleport"
        )
    }

    // MARK: - Fixtures

    private lazy var gymRunActions: [PlaceAction] = [
        PlaceAction(id: UUID(), direction: .arrival, kind: .journalLine(body: "Leg day")),
        PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "spotify", displayName: "Spotify")),
        PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "gym", displayName: "Gym"))
    ]

    private func gymRun() -> RoutineRun {
        RoutineRun.make(
            event: PlaceTriggerEvent(placeId: gymId, kind: .arrival, occurredAt: noon),
            entry: AtPlaceSnapshot.PlaceEntry(
                placeId: gymId, displayName: "Gym 🏋️", openTaskTitles: [],
                arrivalMessage: "Time to train", actions: gymRunActions,
                latitude: nil, longitude: nil
            ),
            plan: PlaceRoutinePlan.make(gymRunActions, for: .arrival)
        )
    }
}
