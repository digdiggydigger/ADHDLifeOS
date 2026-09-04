//
//  HomeRoutineCardTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The Today card that is the way back into a live routine (F-Routines-4-HomeCard, the canvas
/// HomeCard board).
///
/// It exists for one reason: a swiped-away notification would otherwise be a dead end. So the
/// card is a PULL surface — present exactly while a run is live, gone the moment it is not —
/// and every word it shows is pinned here rather than left in a SwiftUI body.
final class HomeRoutineCardTests: XCTestCase {

    private let noon = Date(timeIntervalSince1970: 1_756_296_000)
    private let gymId = UUID()

    private func step(_ state: RoutineStepState, _ name: String) -> RoutineRun.Step {
        RoutineRun.Step(
            action: PlaceAction(
                id: UUID(), direction: .arrival,
                kind: .openApp(scheme: name.lowercased(), displayName: name)
            ),
            state: state
        )
    }

    private func run(
        _ steps: [RoutineRun.Step], direction: PlaceTriggerEvent.Kind = .arrival,
        placeId: UUID? = nil
    ) -> RoutineRun {
        RoutineRun(
            id: UUID(), placeId: placeId ?? gymId, direction: direction, startedAt: noon,
            displayName: "Gym 🏋️", customMessage: "Time to train", steps: steps
        )
    }

    // MARK: - The words (the canvas HomeCard board is the spec)

    func testHeadline_namesThePlaceAndSaysTheRoutineIsLive() {
        XCTAssertEqual(
            HomeRoutineCardModel.headline(for: run([step(.pending, "Gym")])),
            "AT GYM 🏋️ · ROUTINE LIVE"
        )
    }

    func testHeadline_forADepartureRun_saysLeaving() {
        let leaving = run([step(.pending, "Spotify")], direction: .departure)

        XCTAssertEqual(
            HomeRoutineCardModel.headline(for: leaving), "LEAVING GYM 🏋️ · ROUTINE LIVE",
            "a departure routine must not claim you are still there"
        )
    }

    func testStepsLeftLine_countsOnlyPendingSteps() {
        let subject = run([step(.autoDone, "Journal"), step(.done, "Snapchat"),
                           step(.pending, "Gym"), step(.pending, "Spotify")])

        XCTAssertEqual(HomeRoutineCardModel.stepsLeftLine(for: subject), "2 steps left")
    }

    func testStepsLeftLine_singularReadsNaturally() {
        XCTAssertEqual(
            HomeRoutineCardModel.stepsLeftLine(for: run([step(.done, "A"), step(.pending, "B")])),
            "1 step left"
        )
    }

    func testStepsLeftLine_whenEverythingIsResolved_saysSo() {
        // A fully-resolved run stays live until the screen is left (the settled rule, so Undo
        // survives) — so this state IS reachable on Today and must read honestly.
        XCTAssertEqual(
            HomeRoutineCardModel.stepsLeftLine(for: run([step(.done, "A"), step(.skipped, "B")])),
            "All steps done"
        )
    }

    func testNextLine_namesTheFirstPendingStep() {
        let subject = run([step(.done, "Snapchat"), step(.pending, "Gym"), step(.pending, "Spotify")])

        XCTAssertEqual(HomeRoutineCardModel.nextLine(for: subject), "Next: Open Gym")
    }

    func testNextLine_isNilWhenNothingIsPending() {
        XCTAssertNil(HomeRoutineCardModel.nextLine(for: run([step(.done, "A")])))
    }

    func testContinueLabel() {
        XCTAssertEqual(HomeRoutineCardModel.continueLabel, "Continue routine")
    }

    // MARK: - The ArrivalSurfaceCard collision — E VETOED the suppression (2026-09-04)

    /// The build plan had a live routine take Today's slot and stand the arrival card down, on
    /// the grounds that two cards about one place is noise. E's answer was "i want it shown":
    /// the two answer different questions — the routine is the sequence you are part-way
    /// through, the arrival card is the tasks that live here — and hiding one to show the other
    /// hides work.
    ///
    /// A SOURCE pin rather than a value test, because there is no longer a pure function to
    /// call: deleting `suppressesArrivalCard` and leaving the view untouched would compile, and
    /// re-introducing any suppression branch is exactly the regression this guards.
    func testTheArrivalCardIsNotSuppressedByALiveRoutine() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS/Home/HomeRoutineCard.swift")
        let source = try String(contentsOf: url, encoding: .utf8)
        let code = source
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")

        XCTAssertFalse(
            code.contains("suppressesArrivalCard"),
            "E vetoed the suppression — both cards show"
        )
        XCTAssertTrue(
            code.contains("if let arrivalSurface {"),
            "the arrival card's only condition is having a surface at all"
        )
    }
}
