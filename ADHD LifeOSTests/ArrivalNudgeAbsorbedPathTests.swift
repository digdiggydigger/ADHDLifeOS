//
//  ArrivalNudgeAbsorbedPathTests.swift
//  ADHD LifeOSTests
//
//  The compose table's FIFTH path (F-Routines-2-Notify), in its own file for
//  `ArrivalNudgeTests`'s length budget: when a routine notification fires for the crossing,
//  it ABSORBS the place's custom message and the auto-run report — so the task nudge, the
//  separate species, composes TASKS ONLY, and stays silent when there are none
//  (empty-never-fires holds even here).
//

import XCTest
@testable import ADHD_LifeOS

final class ArrivalNudgeAbsorbedPathTests: XCTestCase {

    private let noon = Date(timeIntervalSince1970: 1_756_296_000)
    private let gymId = UUID()

    private func snapshot(
        taskTitles: [String], arrivalMessage: String? = nil, departureMessage: String? = nil
    ) -> AtPlaceSnapshot {
        AtPlaceSnapshot(entries: [
            AtPlaceSnapshot.PlaceEntry(
                placeId: gymId, displayName: "Gym 🏋️", openTaskTitles: taskTitles,
                arrivalMessage: arrivalMessage, departureMessage: departureMessage
            )
        ])
    }

    private func event(_ kind: PlaceTriggerEvent.Kind) -> PlaceTriggerEvent {
        PlaceTriggerEvent(placeId: gymId, kind: kind, occurredAt: noon)
    }

    func testAbsorbed_composesTasksOnly_droppingMessageAndReport() {
        let content = ArrivalNudgeContent.notification(
            for: event(.arrival),
            snapshot: snapshot(taskTitles: ["Buy protein"], arrivalMessage: "Time to train"),
            executedLines: ["Journaled \u{201C}Leg day\u{201D}"],
            absorbedByRoutine: true
        )

        XCTAssertEqual(content?.title, "You're at Gym 🏋️")
        XCTAssertEqual(
            content?.body, "1 thing lives here — Buy protein",
            "the routine already carries the message and the report — repeating them here"
                + " would make one crossing interrupt twice with the same words"
        )
    }

    func testAbsorbed_withNoTasks_isNil() {
        let content = ArrivalNudgeContent.notification(
            for: event(.arrival),
            snapshot: snapshot(taskTitles: [], arrivalMessage: "Time to train"),
            executedLines: ["Journaled \u{201C}Leg day\u{201D}"],
            absorbedByRoutine: true
        )

        XCTAssertNil(content, "tasks-only means NIL when there are none — empty-never-fires")
    }

    func testAbsorbed_departureComposesItsOwnTaskLine() {
        let content = ArrivalNudgeContent.notification(
            for: event(.departure),
            snapshot: snapshot(taskTitles: ["Return the barbell"], departureMessage: "Towel?"),
            absorbedByRoutine: true
        )

        XCTAssertEqual(content?.title, "Leaving Gym 🏋️")
        XCTAssertEqual(content?.body, "\u{201C}Return the barbell\u{201D} is still open here.")
    }

    func testNotAbsorbed_isByteIdenticalToTheShippedFourPaths() {
        // The fifth path must be additive: with the flag off (the default), the compose table
        // behaves exactly as it ships today, message and report included.
        let content = ArrivalNudgeContent.notification(
            for: event(.arrival),
            snapshot: snapshot(taskTitles: ["Buy protein"], arrivalMessage: "Time to train"),
            executedLines: ["Journaled \u{201C}Leg day\u{201D}"]
        )

        XCTAssertEqual(
            content?.body,
            "Time to train — 1 thing lives here: Buy protein · Journaled \u{201C}Leg day\u{201D}"
        )
    }
}
