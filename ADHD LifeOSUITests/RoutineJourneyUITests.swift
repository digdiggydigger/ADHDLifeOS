//
//  RoutineJourneyUITests.swift
//  ADHD LifeOSUITests
//
//  The Routines arc end to end (blocks 2, 3 and 4 together), driven on the simulator against
//  the Firebase emulator.
//
//  It exists because unit tests prove correctness and never REACHABILITY — this repo's most
//  repeated defect is a helper that is perfect, tested, and called by nothing. So this drives
//  the REAL app: seed a place whose crossing qualifies as a routine, fire the crossing with
//  the DEBUG test-fire button, and then walk the surfaces a person actually walks — Today's
//  card, Continue, the routine screen, Skip, Undo, and the departure that ends the run.
//
//  Screenshots are attached at every stop so the screen can be LOOKED at, not just asserted
//  about (the journal-pad lesson: three colour attempts were rejected on device before a
//  render loop existed).
//

import XCTest

final class RoutineJourneyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - The seeded place

    private let placeId = UUID()
    private let journalId = UUID()
    private let snapchatId = UUID()
    private let gymAppId = UUID()
    private let spotifyId = UUID()

    /// A gym whose ARRIVAL runs one silent step and three tap-steps — over the 2+ threshold,
    /// so the crossing collapses into one routine notification — and whose DEPARTURE has
    /// nothing, so leaving simply ends the run.
    private func seedGym(uid: String) throws {
        let action = { (id: UUID, fields: [String: Any]) -> [String: Any] in
            var all: [String: Any] = [
                "id": UITestEmulator.string(id.uuidString),
                "direction": UITestEmulator.string("arrival")
            ]
            fields.forEach { all[$0.key] = $0.value }
            return UITestEmulator.map(all)
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
                // Order IS the routine: this array's order is the order the screen shows.
                "actions": UITestEmulator.array([
                    action(journalId, [
                        "kind": UITestEmulator.string("journal_line"),
                        "journal_body": UITestEmulator.string("Leg day")
                    ]),
                    action(snapchatId, [
                        "kind": UITestEmulator.string("open_app"),
                        "scheme": UITestEmulator.string("snapchat"),
                        "display_name": UITestEmulator.string("Snapchat")
                    ]),
                    action(gymAppId, [
                        "kind": UITestEmulator.string("open_app"),
                        "scheme": UITestEmulator.string("gymapp"),
                        "display_name": UITestEmulator.string("Gym")
                    ]),
                    action(spotifyId, [
                        "kind": UITestEmulator.string("open_app"),
                        "scheme": UITestEmulator.string("spotify"),
                        "display_name": UITestEmulator.string("Spotify")
                    ])
                ])
            ]
        )
    }

    // MARK: - The journey

    @MainActor
    func testARoutineIsReachableFromTodayAndEndsWhenItIsFinished() throws {
        try UITestEmulator.skipUnlessRunning()

        let account = try UITestSession.createAccount(label: "routine")
        try seedGym(uid: account.uid)
        let app = try UITestSession.launchSignedIn(as: account)
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        // 1. Fire the arrival from the couch — the DEBUG test-fire button drives the REAL
        //    handler, so this is the same code path a fence crossing takes.
        fireCrossing(app, named: "Simulate arrival")

        // 2. Today carries the way back in. The notification is deliberately not tapped here:
        //    the card exists precisely for the person who swiped it away.
        openTab("Today", in: app)
        let continueButton = app.buttons["homeRoutineContinueButton"]
        XCTAssertTrue(
            scrollUntilFound(continueButton, in: app),
            "Today never showed the live-routine card, so a swiped notification is a dead end"
        )
        attach(app, "1-today-routine-card")

        // 3. Continue opens the screen — the same door the notification tap uses.
        let nextButton = app.buttons["Open Snapchat"]
        XCTAssertTrue(
            UITestSession.tap(continueButton, untilExists: nextButton),
            "Continue never presented the routine screen"
        )
        XCTAssertTrue(named("routineHeader", app).exists, "the screen has no header")
        XCTAssertEqual(
            named("routineProgress", app).label, "1 of 4 done",
            "the journal step ran itself on the crossing and opens pre-ticked"
        )
        attach(app, "2-routine-screen")

        // 4. Skip is non-destructive and Undo takes it back — no confirmation anywhere.
        skipThenUndo(app)

        // 5. Resolve the rest. Completion is "no pending steps" — with the last one skipped
        //    the dominant next-step card has nothing left to promote and goes away.
        let skip = app.buttons["Skip this step"]
        for _ in 0..<3 where skip.exists {
            skip.tap()
            _ = app.buttons["Open Spotify"].waitForExistence(timeout: 2)
        }
        XCTAssertFalse(
            skip.exists,
            "every step is resolved, so there is no next step left to offer"
        )
        attach(app, "5-all-steps-resolved")

        // 6. A fully-resolved run ends when the screen is LEFT, not at the final tap — which
        //    is what keeps Undo available until then. So closing it takes the card with it,
        //    and the card is the run's only pull surface: its absence IS the run ending.
        // `untilGone:` must name something still ON the screen. Naming the Skip button —
        // which had just been asserted ABSENT — made this return true without ever tapping
        // Close, leaving the cover up and every later assertion reading the screen beneath it.
        XCTAssertTrue(
            UITestSession.tap(app.buttons["Close"], untilGone: named("routineProgress", app)),
            "Close did not dismiss the routine screen"
        )
        XCTAssertTrue(
            waitForGone(continueButton, in: app),
            "A finished routine left its card on Today — the run never ended"
        )
        attach(app, "6-after-completion")
    }

    // MARK: - Helpers

    /// Skip and Undo, the arc's whole recovery vocabulary: both non-destructive, neither
    /// guarded by an "Are you sure?" (E's settled call #6, Undo over confirm).
    @MainActor
    private func skipThenUndo(_ app: XCUIApplication) {
        XCTAssertTrue(
            UITestSession.tap(app.buttons["Skip this step"], untilExists: app.buttons["Open Gym"]),
            "Skipping did not promote the next step"
        )
        XCTAssertEqual(
            named("routineProgress", app).label, "1 of 4 done",
            "a SKIPPED step is resolved, not done — the wording must not inflate"
        )
        attach(app, "3-after-skip")

        XCTAssertTrue(
            UITestSession.tap(
                app.buttons["Undo Open Snapchat"].firstMatch,
                untilExists: app.buttons["Open Snapchat"]
            ),
            "Undo did not return the skipped step to pending"
        )
        attach(app, "4-after-undo")
    }

    /// Taps a tab until it is actually SELECTED. A tab tap taken while the previous screen is
    /// still settling is a silent no-op — the lesson `SignedInJourneySupport.openTab` records,
    /// and the exact way this journey failed on its first run.
    @MainActor
    private func openTab(_ name: String, in app: XCUIApplication) {
        let tab = UITestSession.tabButton(name, in: app)
        XCTAssertTrue(
            tab.waitForExistence(timeout: UITestSession.timeout),
            "The \(name) tab is missing from the tab bar"
        )
        for attempt in 1...4 {
            if tab.isSelected { return }
            // A plain `.tap()` goes through hittability resolution, which a just-dismissed
            // full-screen cover can still be interfering with — that is exactly where this
            // journey's second Tools tap died. From the second attempt, tap the COORDINATE,
            // which bypasses that resolution entirely.
            if attempt == 1 {
                tab.tap()
            } else {
                tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            // A FRESH expectation per attempt: XCTest allows an expectation to be waited on
            // exactly once, and reusing one across retries raises an API violation rather than
            // retrying — which is how this journey failed on its second Tools tap.
            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "isSelected == true"), object: tab
            )
            if XCTWaiter().wait(for: [selected], timeout: 4) == .completed { return }
        }
        XCTAssertTrue(tab.isSelected, "The \(name) tab never became selected")
    }

    /// Places live on the Tools tab since F-Tools-3-Page. Every tap here is race-proofed: the
    /// first run of this journey died on a swallowed tab tap.
    @MainActor
    private func fireCrossing(_ app: XCUIApplication, named button: String) {
        openTab("Tools", in: app)
        let placesDoor = app.buttons["toolsCard.places"]
        XCTAssertTrue(
            placesDoor.waitForExistence(timeout: UITestSession.timeout),
            "The Tools tab never showed the Places door"
        )
        let fire = app.buttons["placeTestFireButton-\(placeId)"]
        XCTAssertTrue(
            UITestSession.tap(placesDoor, untilExists: fire),
            "The seeded place never appeared in the Places list"
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

    /// Today is a `LazyVStack`, so a row below the fold does not merely fail to be hittable —
    /// it does not EXIST. The card sits at the very top, but a tab can be restored mid-scroll.
    @MainActor
    private func scrollUntilFound(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        // WAIT first: the card arrives on the app-wide change signal, which is debounced, so
        // swiping immediately would decide "absent" before it could ever be present.
        if element.waitForExistence(timeout: UITestSession.timeout) { return true }
        for _ in 0..<8 {
            app.swipeDown()
            if element.waitForExistence(timeout: 2) { return true }
        }
        return element.exists
    }

    @MainActor
    private func waitForGone(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        let gone = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: element
        )
        if XCTWaiter().wait(for: [gone], timeout: UITestSession.timeout) == .completed {
            return true
        }
        for _ in 0..<8 {
            if !element.exists { return true }
            app.swipeDown()
        }
        return !element.exists
    }

    /// Addresses an element by identifier without asserting its TYPE. A SwiftUI element
    /// built with `.accessibilityElement(children: .combine)` is exposed as whatever type the
    /// framework picks — guessing `otherElements` cost this journey a run.
    @MainActor
    private func named(_ identifier: String, _ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
