//
//  PlaceRoutineDepartureEndTests.swift
//  ADHD LifeOSTests
//
//  Round-2 field walk, check 3 (2026-09-04). The shipped lifecycle test in
//  `PlaceRoutineHandlerTests` pins "the place's departure ends its arrival run" against a
//  fixture whose DEPARTURE has no actions. On the device the same crossing was walked
//  against a place that has BOTH — an arrival routine and a departure routine — and Today
//  kept showing the arrival card after the departure fired.
//
//  These tests reproduce that shape exactly: arrival = one auto step + two tap-steps,
//  departure = two tap-steps. Both directions qualify as routines, so the departure has to
//  end the arrival run AND replace it (newest wins), in that order.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class PlaceRoutineDepartureEndTests: XCTestCase {

    /// The device fixture: "routines test" as it was configured for the round-2 walk.
    private func installBothDirections(_ harness: RoutineHandlerHarness) {
        let arrivalJournal = PlaceAction(
            id: UUID(), direction: .arrival, kind: .journalLine(body: "Leg day")
        )
        let arrivalMaps = PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openApp(scheme: "maps", displayName: "Apple Maps")
        )
        let arrivalYouTube = PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openApp(scheme: "youtube", displayName: "YouTube")
        )
        let departureSpotify = PlaceAction(
            id: UUID(), direction: .departure,
            kind: .openApp(scheme: "spotify", displayName: "Spotify")
        )
        let departureHealth = PlaceAction(
            id: UUID(), direction: .departure,
            kind: .openApp(scheme: "health", displayName: "Health")
        )
        harness.installGym(
            actions: [
                departureSpotify, departureHealth,
                arrivalJournal, arrivalMaps, arrivalYouTube
            ],
            arrivalMessage: "Time to train"
        )
    }

    func testDepartureEndsTheArrivalRunEvenWhenTheDepartureIsItselfARoutine() async {
        let harness = RoutineHandlerHarness()
        installBothDirections(harness)

        await harness.sut.handle(harness.event(.arrival))
        let arrivalRun = harness.runStore.run
        XCTAssertEqual(
            arrivalRun?.direction, .arrival,
            "the arrival crossing should mint an arrival run"
        )

        await harness.sut.handle(
            harness.event(.departure, at: harness.noon.addingTimeInterval(600))
        )

        XCTAssertNotEqual(
            harness.runStore.run?.id, arrivalRun?.id,
            "the arrival run survived its own place's departure — Today keeps the stale card"
        )
        XCTAssertGreaterThan(
            harness.runStore.endCount, 0,
            "the departure must END the arrival run before replacing it"
        )
    }

    /// Ordering, not just outcome: end-then-create. A create that landed first would be
    /// wiped by the end, leaving no run at all.
    func testDepartureEndsBeforeItCreatesTheDepartureRun() async {
        let harness = RoutineHandlerHarness()
        installBothDirections(harness)

        await harness.sut.handle(harness.event(.arrival))
        await harness.sut.handle(
            harness.event(.departure, at: harness.noon.addingTimeInterval(600))
        )

        XCTAssertEqual(
            harness.runStore.run?.direction, .departure,
            "newest wins: the departure routine should now be the live run"
        )
        let lifecycle = harness.log.events.filter { $0 == "run-end" || $0 == "run-write" }
        XCTAssertEqual(
            lifecycle, ["run-write", "run-end", "run-write"],
            "expected arrival create, then the departure's end-before-create"
        )
    }
}
