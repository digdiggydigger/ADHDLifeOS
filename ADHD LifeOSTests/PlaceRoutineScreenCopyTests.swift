//
//  PlaceRoutineScreenCopyTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Every word on the routine screen (F-Routines-3, the canvas Main board), plus the call-site
/// pins that prove the door is WIRED — the dead-shared-component rule: a router nothing
/// connects and a screen nothing presents would pass every unit test while shipping nothing.
final class PlaceRoutineScreenCopyTests: XCTestCase {

    private func run(direction: PlaceTriggerEvent.Kind = .arrival) -> RoutineRun {
        RoutineRun(
            id: UUID(), placeId: UUID(), direction: direction,
            startedAt: Date(timeIntervalSince1970: 1_756_296_000),
            displayName: "Gym 🏋️", customMessage: "Time to train", steps: []
        )
    }

    // MARK: - The words

    func testTheChrome() {
        XCTAssertEqual(PlaceRoutineScreenCopy.eyebrow, "ROUTINE")
        XCTAssertEqual(PlaceRoutineScreenCopy.skipLabel, "Skip this step")
        XCTAssertEqual(PlaceRoutineScreenCopy.undoLabel, "Undo")
        XCTAssertEqual(PlaceRoutineScreenCopy.doneSubtitle, "Done")
        XCTAssertEqual(PlaceRoutineScreenCopy.skippedSubtitle, "Skipped")
    }

    func testMomentTitle_matchesTheNotificationsVoice() {
        XCTAssertEqual(PlaceRoutineScreenCopy.momentTitle(for: run()), "You're at Gym 🏋️")
        XCTAssertEqual(
            PlaceRoutineScreenCopy.momentTitle(for: run(direction: .departure)),
            "Leaving Gym 🏋️"
        )
    }

    func testMomentPrefix_switchesByDirection() {
        XCTAssertEqual(PlaceRoutineScreenCopy.momentPrefix(for: .arrival), "arrived")
        XCTAssertEqual(PlaceRoutineScreenCopy.momentPrefix(for: .departure), "left")
    }

    /// It used to switch on direction — "when you arrived" / "when you left" — because the
    /// crossing was when the step ran. Under deferred logging (Block A) the step runs when the
    /// routine STARTS, which is the tap that opened this screen: the same moment either way.
    func testAutoRanSubtitle_namesTheStart_notTheCrossing() {
        XCTAssertEqual(
            PlaceRoutineScreenCopy.autoRanSubtitle, "Ran by itself when you started"
        )
        XCTAssertFalse(
            PlaceRoutineScreenCopy.autoRanSubtitle.contains("arrived"),
            "nothing runs at the crossing any more — this row would be claiming it did"
        )
    }

    func testStepLines() {
        XCTAssertEqual(PlaceRoutineScreenCopy.nextEyebrow(stepNumber: 3, of: 4), "NEXT — STEP 3 OF 4")
        XCTAssertEqual(PlaceRoutineScreenCopy.upcomingSubtitle(stepNumber: 4, of: 4), "Step 4 of 4")
    }

    // MARK: - The wiring (source-read, the clearance-tests mould)

    func testTheDelegate_asksTheRoutineRouterAfterPlaceActionsAndBeforeFocus() throws {
        let source = try Self.appSource("ADHD_LifeOSApp.swift")

        let placeAction = try XCTUnwrap(source.range(of: "PlaceActionNotificationRouter.shared.handle"))
        let routine = try XCTUnwrap(
            source.range(of: "PlaceRoutineNotificationRouter.shared.handle"),
            "the routine router must be in the delegate chain — an unwired router is the"
                + " dead-shared-component shape at the tap layer"
        )
        let focus = try XCTUnwrap(source.range(of: "FocusNotificationRouter.shared.handle"))
        XCTAssertLessThan(
            placeAction.lowerBound, routine.lowerBound,
            "place-action greed is pinned — it goes first, and the routine prefix dodges it"
        )
        XCTAssertLessThan(
            routine.lowerBound, focus.lowerBound,
            "everything unclaimed still falls through to the focus router"
        )
    }

    func testRootView_connectsTheRouterAndPresentsTheCover() throws {
        let doors = try Self.appSource("RootView+Doors.swift")
        let root = try Self.appSource("RootView.swift")

        XCTAssertTrue(
            root.contains("PlaceRoutineNotificationRouter.shared.connect"),
            "nothing connects the router — pending taps would sit forever"
        )
        // `F-CTACelebrations-3` gave this cover an `onDismiss:` — it tells the celebration centre
        // its surface has gone — so the presenter is written over several lines now. Read flattened,
        // because how a call is WRAPPED is not the property this guard is about.
        let flattened = root
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
        XCTAssertTrue(
            flattened.contains("fullScreenCover( item: $presentedRoutineRun"),
            "nothing presents the routine screen"
        )
        XCTAssertTrue(
            doors.contains("func openRoutineDoor"),
            "the door lives in RootView+Doors (the 396/400 split)"
        )
        XCTAssertTrue(
            doors.contains("selectedTab = .today"),
            "the stale-tap rule: a mismatched or missing run key opens Today, nothing else"
        )
    }

    private static func appSource(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw NSError(domain: "PlaceRoutineScreenCopyTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not read \(url.path) — this test reads the"
                    + " tree it was compiled from (#filePath)."
            ])
        }
        return text
    }
}
