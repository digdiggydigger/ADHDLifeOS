//
//  RoutineRefreshJourneyUITests.swift
//  ADHD LifeOSUITests
//
//  The round-2 field-walk defect (2026-09-04), reproduced. On E's iPhone a departure crossing
//  updated the run store correctly — the app-switcher snapshot proved it — but Today went on
//  showing the ARRIVAL card for as long as it was watched. Only backgrounding and reopening
//  corrected it. An arrival crossing, by contrast, refreshed the card in about 2.5 seconds.
//
//  `PlaceRoutineDepartureEndTests` already rules the handler out: the lifecycle is correct, and
//  `applyRunLifecycle` posts `DataChangeSignal` whenever it changes anything. So the defect is
//  in DELIVERY, which no unit test can reach — Today's card is a SwiftUI body reading a
//  UserDefaults store, and only a running app can show whether the refresh lands.
//
//  The asymmetry is the clue this journey is built to pin. An arrival here also runs a journal
//  auto-step, which writes to Firestore and therefore posts a SECOND DataChangeSignal through
//  the manager's write plumbing. The departure is tap-steps only and writes NOTHING, so the
//  signal from `applyRunLifecycle` is the only one there is — and that is the path under test.
//

import XCTest

final class RoutineRefreshJourneyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private let placeId = UUID()
    private let journalId = UUID()
    private let arriveAppId = UUID()
    private let arriveSecondId = UUID()
    private let leaveAppId = UUID()
    private let leaveSecondId = UUID()

    /// A place with a routine in BOTH directions — the configuration E walked, and the one the
    /// shipped lifecycle test does not cover. Arrival carries a silent journal step plus two
    /// tap-steps; departure carries two tap-steps and nothing silent.
    private func seedBothDirections(uid: String) throws {
        let action = { (id: UUID, direction: String, fields: [String: Any]) -> [String: Any] in
            var all: [String: Any] = [
                "id": UITestEmulator.string(id.uuidString),
                "direction": UITestEmulator.string(direction)
            ]
            fields.forEach { all[$0.key] = $0.value }
            return UITestEmulator.map(all)
        }
        let openApp = { (scheme: String, name: String) -> [String: Any] in
            [
                "kind": UITestEmulator.string("open_app"),
                "scheme": UITestEmulator.string(scheme),
                "display_name": UITestEmulator.string(name)
            ]
        }
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/places/\(placeId.uuidString)",
            fields: [
                "id": UITestEmulator.string(placeId.uuidString),
                "name": UITestEmulator.string("Gym"),
                "latitude": UITestEmulator.double(51.5152),
                "longitude": UITestEmulator.double(-0.1418),
                "radius_metres": UITestEmulator.double(150),
                "emoji": UITestEmulator.string("🏋️"),
                "created_at": UITestEmulator.timestamp(Date()),
                "nudge_on_arrival": UITestEmulator.bool(true),
                "nudge_on_departure": UITestEmulator.bool(true),
                "arrival_message": UITestEmulator.string("Time to train"),
                "actions": UITestEmulator.array([
                    action(journalId, "arrival", [
                        "kind": UITestEmulator.string("journal_line"),
                        "journal_body": UITestEmulator.string("Leg day")
                    ]),
                    action(arriveAppId, "arrival", openApp("snapchat", "Snapchat")),
                    action(arriveSecondId, "arrival", openApp("gymapp", "Gym")),
                    action(leaveAppId, "departure", openApp("spotify", "Spotify")),
                    action(leaveSecondId, "departure", openApp("health", "Health"))
                ])
            ]
        )
    }

    // MARK: - The journey

    @MainActor
    func testADepartureRefreshesTodaysCardWithoutBackgroundingTheApp() throws {
        try UITestEmulator.skipUnlessRunning()

        let account = try UITestSession.createAccount(label: "routineRefresh")
        try seedBothDirections(uid: account.uid)
        let app = try UITestSession.launchSignedIn(as: account)
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        // 1. Arrive. This half is known to work, and it is here as the CONTROL: if it fails the
        //    journey is reporting a broken fixture rather than the defect.
        fireCrossing(app, named: "Simulate arrival")
        openTab("Today", in: app)
        XCTAssertTrue(
            waitForCard(containing: "AT GYM", in: app),
            "Today never showed the arrival card — the fixture, not the defect, is wrong"
        )

        // 2. Leave. The run store now holds a DEPARTURE run (the arrival run ends, newest wins),
        //    and the ONLY thing that can tell Today is the signal `applyRunLifecycle` posts:
        //    a departure of tap-steps writes nothing to Firestore.
        fireCrossing(app, named: "Simulate departure")
        openTab("Today", in: app)

        // 3. The assertion the device failed. No backgrounding, no relaunch — the app has been
        //    in the foreground throughout, which is the state a person is actually in when a
        //    crossing lands while they are looking at Today.
        XCTAssertTrue(
            waitForCard(containing: "LEAVING GYM", in: app),
            "Today kept the stale arrival card after the departure crossing. The run store is "
                + "correct (PlaceRoutineDepartureEndTests pins it), so the change signal never "
                + "reached the card."
        )
        XCTAssertFalse(
            cardText(containing: "AT GYM", in: app),
            "both cards on screen at once — the arrival card was not replaced but added to"
        )
    }

    // MARK: - Helpers

    /// Waits for a Today card whose headline contains `fragment`. Deliberately generous: the
    /// signal is debounced by 600ms and `refreshEverything` sits behind three network loads,
    /// so a short wait would call the defect where there is only latency.
    @MainActor
    private func waitForCard(containing fragment: String, in app: XCUIApplication) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", fragment)
        let element = app.staticTexts.containing(predicate).firstMatch
        return element.waitForExistence(timeout: UITestSession.timeout)
    }

    @MainActor
    private func cardText(containing fragment: String, in app: XCUIApplication) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", fragment)
        return app.staticTexts.containing(predicate).firstMatch.exists
    }

    /// Places live on the Tools tab. Every tap is race-proofed — the sibling journey died twice
    /// on swallowed tab taps before this shape settled.
    ///
    /// This journey fires TWICE with a visit to Today in between, which the sibling never does,
    /// and that turns out to matter: a tab keeps its navigation stack, so returning to Tools
    /// lands back INSIDE the Places list rather than on the Tools root. The door is gone and the
    /// fire button is already there. Waiting for the door on the second pass hangs until the
    /// timeout and reads exactly like the app failing to render it.
    @MainActor
    private func fireCrossing(_ app: XCUIApplication, named button: String) {
        openTab("Tools", in: app)
        let fire = app.buttons["placeTestFireButton-\(placeId)"]
        if !fire.exists {
            let placesDoor = app.buttons["toolsCard.places"]
            XCTAssertTrue(
                placesDoor.waitForExistence(timeout: UITestSession.timeout),
                "The Tools tab never showed the Places door"
            )
            XCTAssertTrue(
                UITestSession.tap(placesDoor, untilExists: fire),
                "The seeded place never appeared in the Places list"
            )
        }
        XCTAssertTrue(
            fire.waitForExistence(timeout: UITestSession.timeout),
            "The seeded place's test-fire button never appeared"
        )
        let choice = app.buttons[button]
        XCTAssertTrue(
            UITestSession.tap(fire, untilExists: choice),
            "The test-fire dialog never offered \(button)"
        )
        XCTAssertTrue(
            UITestSession.tap(choice, untilGone: choice),
            "The test-fire dialog never dismissed"
        )
    }

    /// A tab tap taken while the previous screen is still settling is a silent no-op, and a
    /// fresh expectation is required per attempt — XCTest allows one wait per expectation.
    @MainActor
    private func openTab(_ name: String, in app: XCUIApplication) {
        let tab = UITestSession.tabButton(name, in: app)
        XCTAssertTrue(
            tab.waitForExistence(timeout: UITestSession.timeout),
            "The \(name) tab is missing from the tab bar"
        )
        for attempt in 1...4 {
            if tab.isSelected { return }
            if attempt == 1 {
                tab.tap()
            } else {
                tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "isSelected == true"), object: tab
            )
            if XCTWaiter().wait(for: [selected], timeout: 4) == .completed { return }
        }
        XCTAssertTrue(tab.isSelected, "The \(name) tab never became selected")
    }
}
