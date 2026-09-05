//
//  PlaceRoutinePlanTests.swift
//  ADHD LifeOSTests
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

/// The pure core of the Routines arc (F-Routines-1-Order, E's design settled 2026-09-03).
///
/// A place's actions, in saved array order, ARE the routine — Option A, place-scoped, no new
/// data. Two claims live here: the ORDER (array order survives the real Firestore codec and a
/// reorder — order is the feature), and the DECISION (a crossing becomes a routine at
/// `RoutineDefaults.stepThreshold` tap-steps; below it, today's per-action notifications are
/// the better shape and must keep firing byte-identically).
final class PlaceRoutinePlanTests: XCTestCase {

    private let coordinate = PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)

    // MARK: - Fixtures

    private func journal() -> PlaceAction {
        PlaceAction(id: UUID(), direction: .arrival, kind: .journalLine(body: "Leg day"))
    }

    private func spotify(_ direction: PlaceActionDirection = .arrival) -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: direction,
            kind: .openApp(scheme: "spotify", displayName: "Spotify")
        )
    }

    private func capture() -> PlaceAction {
        PlaceAction(id: UUID(), direction: .arrival, kind: .createCapture(text: "Check the mail"))
    }

    private func text(_ direction: PlaceActionDirection = .arrival) -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: direction,
            kind: .textContact(contactName: "Ben", phoneNumber: "+44111", messageBody: "Here!")
        )
    }

    private func sprint() -> PlaceAction {
        PlaceAction(id: UUID(), direction: .arrival, kind: .startSprint(minutes: 25))
    }

    private func unsupported() -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .unsupported(rawKind: "teleport", payload: ["speed": .string("fast")])
        )
    }

    // MARK: - The named numbers (RoutineDefaults)

    func testStepThreshold_isTwo() {
        // E's settled call (2026-09-03): one tap-step keeps today's direct notification —
        // routing a single step through a screen adds a tap for nothing.
        XCTAssertEqual(RoutineDefaults.stepThreshold, 2)
    }

    func testDepartureRunWindow_isThirtyMinutes() {
        XCTAssertEqual(RoutineDefaults.departureRunWindow, 30 * 60)
        // A MATCHED default, not a shared constant: it deliberately mirrors the trigger
        // cooldown today, and the two are allowed to drift apart on purpose later. When one
        // moves, this assertion is where that decision gets recorded.
        XCTAssertEqual(RoutineDefaults.departureRunWindow, TriggerCooldown.minimumInterval)
    }

    // MARK: - Order (the feature)

    func testMake_preservesInterleavedArrayOrder() {
        let actions = [journal(), spotify(), capture(), text(), sprint()]

        let plan = PlaceRoutinePlan.make(actions, for: .arrival)

        XCTAssertEqual(
            plan.steps.map(\.action.id), actions.map(\.id),
            "Steps must keep the saved array order, auto and tap interleaved as E arranged them"
        )
        XCTAssertEqual(
            plan.steps.map(\.runsAutomatically), [true, false, true, false, false],
            "journalLine and createCapture run themselves; the rest are tap-steps"
        )
    }

    func testMake_filtersByDirection() {
        let arriving = spotify(.arrival)
        let leaving = text(.departure)
        let actions = [arriving, leaving]

        XCTAssertEqual(PlaceRoutinePlan.make(actions, for: .arrival).steps.map(\.action), [arriving])
        XCTAssertEqual(PlaceRoutinePlan.make(actions, for: .departure).steps.map(\.action), [leaving])
    }

    func testMake_excludesUnsupportedActions() {
        // An unsupported action holds its fence but this build can neither run it nor honour
        // its tap — it must not occupy a step the screen would show as forever-pending.
        let plan = PlaceRoutinePlan.make([spotify(), unsupported(), text()], for: .arrival)

        XCTAssertEqual(plan.steps.count, 2)
        XCTAssertFalse(plan.steps.contains { $0.action.kind == unsupported().kind })
    }

    func testMake_agreesWithThePerActionSplit() {
        // One classification, two consumers. `PlaceActionPlan.split` decides what the handler
        // runs and posts; the routine plan must never disagree with it about membership, or
        // the screen would show a step the crossing never offered (or vice versa).
        let actions = [journal(), spotify(), capture(), text(), sprint(), unsupported()]
        let (autoRun, external) = PlaceActionPlan.split(actions, for: .arrival)

        let plan = PlaceRoutinePlan.make(actions, for: .arrival)

        XCTAssertEqual(plan.autoRunSteps, autoRun)
        XCTAssertEqual(plan.tapSteps, external)
    }

    func testMake_withNilActions_isEmptyAndNotARoutine() {
        let plan = PlaceRoutinePlan.make(nil, for: .arrival)

        XCTAssertTrue(plan.steps.isEmpty)
        XCTAssertFalse(plan.qualifiesAsRoutine)
    }

    // MARK: - The ≥2 decision

    func testTwoTapSteps_qualifyAsARoutine() {
        XCTAssertTrue(PlaceRoutinePlan.make([spotify(), text()], for: .arrival).qualifiesAsRoutine)
    }

    func testOneTapStep_doesNotQualify_evenWithAutoRunsAlongside() {
        // The auto-runs happen either way; ONE tap is served best by today's direct one-tap
        // notification. Only the tap-step count decides.
        let plan = PlaceRoutinePlan.make([journal(), capture(), spotify()], for: .arrival)

        XCTAssertFalse(plan.qualifiesAsRoutine)
        XCTAssertEqual(plan.autoRunSteps.count, 2)
    }

    func testNoTapSteps_doNotQualify() {
        XCTAssertFalse(PlaceRoutinePlan.make([journal(), capture()], for: .arrival).qualifiesAsRoutine)
    }

    // MARK: - Order survives the real Firestore codec (not just JSON)

    private func makeGym(actions: [PlaceAction]) -> Place {
        Place(
            id: UUID(), name: "Gym", coordinate: coordinate, radiusMetres: 150, emoji: "🏋️",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            nudgeOnArrival: true, nudgeOnDeparture: false,
            arrivalMessage: "Time to train", departureMessage: nil,
            actions: actions
        )
    }

    func testActionOrder_survivesTheRealFirestoreCodec() throws {
        let actions = [journal(), spotify(), text(), sprint()]

        let fields = try FirestoreDocumentCoder.encode(makeGym(actions: actions))
        let decoded = try FirestoreDocumentCoder.decode(Place.self, from: fields)

        XCTAssertEqual(decoded.actions, actions, "the embedded array must come back in order")
    }

    func testAReorder_survivesTheRealFirestoreCodec() throws {
        var actions = [journal(), spotify(), text(), sprint()]
        // The editor's `.onMove` is exactly this mutation: drag row 3 to the top.
        actions.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        let fields = try FirestoreDocumentCoder.encode(makeGym(actions: actions))
        let decoded = try FirestoreDocumentCoder.decode(Place.self, from: fields)

        XCTAssertEqual(
            decoded.actions.map(\.id), actions.map(\.id),
            "a reorder is a SAVE of the moved array — the codec must not re-sort it"
        )
    }
}
