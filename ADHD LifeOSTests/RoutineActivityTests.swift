//
//  RoutineActivityTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The routine Live Activity's payload and words (F-Routines-5-LiveActivity).
///
/// A DISPLAY Activity: progress, the next step, and a tap that returns to the screen. No
/// buttons — interactive App Intents are the settled fast-follow. The resolution lives on the
/// SHARED payload precisely so this app-side target can assert it; the widget extension has no
/// test bundle of its own (the `FocusActivityAttributes` precedent).
@available(iOS 16.1, *)
final class RoutineActivityTests: XCTestCase {

    private let noon = Date(timeIntervalSince1970: 1_756_296_000)

    private func step(_ state: RoutineStepState, _ name: String) -> RoutineRun.Step {
        RoutineRun.Step(
            action: PlaceAction(
                id: UUID(), direction: .arrival,
                kind: .openApp(scheme: name.lowercased(), displayName: name)
            ),
            state: state
        )
    }

    private func run(_ states: [(RoutineStepState, String)]) -> RoutineRun {
        RoutineRun(
            id: UUID(), placeId: UUID(), direction: .arrival, startedAt: noon,
            displayName: "Gym 🏋️", customMessage: "Time to train",
            steps: states.map { step($0.0, $0.1) }
        )
    }

    // MARK: - The payload

    func testContentState_mirrorsTheRunsProgress() {
        let subject = run([(.autoDone, "Journal"), (.done, "Snapchat"),
                           (.pending, "Gym"), (.pending, "Spotify")])

        let state = RoutineActivityAttributes.ContentState(run: subject)

        XCTAssertEqual(state.placeName, "Gym 🏋️")
        XCTAssertEqual(state.doneCount, 2)
        XCTAssertEqual(state.totalCount, 4)
        XCTAssertEqual(state.nextStepLabel, "Open Gym")
        XCTAssertEqual(state.progress, 0.5, accuracy: 0.0001)
    }

    func testContentState_progressCountsSkippedAsResolved() {
        // The bar answers "how much of this list is dealt with" — the same semantics the
        // screen's bar uses, so the two can never disagree in front of the user.
        let state = RoutineActivityAttributes.ContentState(
            run: run([(.autoDone, "A"), (.skipped, "B"), (.pending, "C"), (.pending, "D")])
        )

        XCTAssertEqual(state.progress, 0.5, accuracy: 0.0001)
        XCTAssertEqual(state.doneCount, 1, "a skipped step is resolved, never DONE")
    }

    func testContentState_whenFinished_hasNoNextStep() {
        let state = RoutineActivityAttributes.ContentState(
            run: run([(.autoDone, "A"), (.done, "B")])
        )

        XCTAssertNil(state.nextStepLabel)
        XCTAssertEqual(state.progress, 1, accuracy: 0.0001)
    }

    func testContentState_survivesAnArchiveRoundTrip() throws {
        // ActivityKit archives this across processes; a payload that cannot round-trip shows a
        // blank card mid-routine.
        let state = RoutineActivityAttributes.ContentState(
            run: run([(.autoDone, "A"), (.pending, "B")])
        )

        let decoded = try JSONDecoder().decode(
            RoutineActivityAttributes.ContentState.self,
            from: JSONEncoder().encode(state)
        )

        XCTAssertEqual(decoded, state)
    }

    // MARK: - The words

    func testStatusLine() {
        let state = RoutineActivityAttributes.ContentState(
            run: run([(.autoDone, "A"), (.pending, "B"), (.pending, "C")])
        )

        XCTAssertEqual(state.statusLine, "1 of 3 done")
    }

    func testNextLine_readsAsAnInstructionOrACompletion() {
        let running = RoutineActivityAttributes.ContentState(
            run: run([(.autoDone, "A"), (.pending, "Gym")])
        )
        let finished = RoutineActivityAttributes.ContentState(run: run([(.done, "A")]))

        XCTAssertEqual(running.nextLine, "Next: Open Gym")
        XCTAssertEqual(finished.nextLine, "All steps done")
    }

    // MARK: - Tap-to-return

    func testTheActivitysDeepLink_routesToTheRoutineScreen() throws {
        let url = try XCTUnwrap(URL(string: RoutineActivityAttributes.deepLink))

        XCTAssertEqual(AppDeepLink.route(url), .routineScreen)
        XCTAssertTrue(
            AppDeepLink.routineScreen.requiresSignedInUI,
            "the routine screen lives inside the signed-in tabs, so a cold-launch tap must be"
                + " held pending rather than dropped"
        )
    }

    func testAnUnknownWidgetPath_stillJustOpensTheApp() throws {
        // The routine path must not widen the fallback: a path this build doesn't know still
        // launches rather than reaching the auth layer.
        let url = try XCTUnwrap(URL(string: "adhdlifeos://widget/routine/extra"))

        XCTAssertEqual(AppDeepLink.route(url), .focusWidget)
    }
}
