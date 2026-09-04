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

        let continueButton = app.buttons["homeRoutineContinueButton"]

        // 1 & 2. Fire the arrival, then prove nothing came of it — the whole of Block A. E's
        //        rule: a crossing writes NOTHING, so a swiped banner leaves no card, no run
        //        and no journal line.
        arriveWithoutStartingAnything(app, continueButton: continueButton)

        // 3. Open the notification. The DEBUG replay hands the DELIVERED notification's
        //    identifier and userInfo to the same router iOS would, so this is the real tap —
        //    and it is the moment the routine comes into existence.
        fireCrossing(app, named: "Open the routine notification")
        let nextButton = app.buttons["Open Snapchat"]
        XCTAssertTrue(
            nextButton.waitForExistence(timeout: UITestSession.timeout),
            "The tapped routine notification never presented the routine screen"
        )
        XCTAssertTrue(named("routineHeader", app).exists, "the screen has no header")
        XCTAssertEqual(
            named("routineProgress", app).label, "1 of 4 done",
            "the journal step runs when the routine STARTS, so it opens pre-ticked"
        )
        attach(app, "2-routine-screen")

        // 3b. Today's card is the way back in, and it goes out and comes back through it.
        leaveAndReturnThroughTodaysCard(app, continueButton: continueButton, nextButton: nextButton)

        // 3c. The routine follows you out of the app (F-Routines-5). ActivityKit cannot START
        //     an Activity from the background, which is exactly why it begins here, with the
        //     screen open — so backgrounding now is the first moment the card can exist.
        photographTheLiveActivity(app)

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

    /// Fires the arrival and asserts the crossing left NOTHING behind.
    @MainActor
    private func arriveWithoutStartingAnything(
        _ app: XCUIApplication, continueButton: XCUIElement
    ) {
        // The DEBUG test-fire button drives the REAL handler, so this is the same code path a
        // fence crossing takes.
        fireCrossing(app, named: "Simulate arrival")
        // The place-trigger path never asks for notification permission (only focus and nudges
        // do), so the test-fire button asks — and the prompt has to be cleared here.
        UITestSession.dismissSystemAlertIfPresent()
        openTab("Today", in: app)
        XCTAssertFalse(
            continueButton.waitForExistence(timeout: 6),
            "the crossing put a routine card on Today before anyone tapped anything"
        )
        attach(app, "1-today-before-the-tap")
    }

    /// Closes the routine screen, finds Today's card, and comes back in through it.
    ///
    /// Under Block A that card can only exist because the notification was tapped — a swiped
    /// banner leaves nothing behind — which is why this check sits AFTER the tap rather than
    /// having been deleted with the premise it used to carry.
    @MainActor
    private func leaveAndReturnThroughTodaysCard(
        _ app: XCUIApplication, continueButton: XCUIElement, nextButton: XCUIElement
    ) {
        XCTAssertTrue(
            UITestSession.tap(app.buttons["Close"], untilGone: named("routineProgress", app)),
            "Close did not dismiss the routine screen"
        )
        openTab("Today", in: app)
        XCTAssertTrue(
            scrollUntilFound(continueButton, in: app),
            "Today never showed the live-routine card, so a closed routine is a dead end"
        )
        attach(app, "2b-today-routine-card")
        XCTAssertTrue(
            UITestSession.tap(continueButton, untilExists: nextButton),
            "Continue never re-presented the routine screen"
        )
    }

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

    /// Sends the app to the background and photographs the Dynamic Island / Lock Screen, then
    /// brings it back. Deliberately NOT asserted: whether a Live Activity renders depends on
    /// `areActivitiesEnabled` and on the simulator's island support, and a journey that failed
    /// on either would be reporting the environment rather than the code. The screenshot is
    /// the deliverable — the same render-and-look loop the rest of this file uses.
    @MainActor
    private func photographTheLiveActivity(_ app: XCUIApplication) {
        XCUIDevice.shared.press(.home)
        // Wait for the APP to actually leave the foreground. Screenshotting straight after the
        // press captured the app still on screen — the press had not landed yet. And capture
        // the SCREEN rather than springboard's own element tree, which does not include the
        // Activity's rendering.
        _ = app.wait(for: .runningBackground, timeout: 10)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "2b-live-activity"
        shot.lifetime = .keepAlways
        add(shot)
        app.activate()
        XCTAssertTrue(
            app.buttons["Open Snapchat"].waitForExistence(timeout: UITestSession.timeout),
            "the routine screen did not survive a trip to the background"
        )
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
        let fire = app.buttons["placeTestFireButton-\(placeId)"]
        // A tab keeps its navigation stack, so the SECOND visit lands back inside Places with
        // no door to tap. Waiting for the door there hangs to the timeout and reads exactly
        // like a render failure — the sibling journey's trap, and this journey now fires twice.
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
