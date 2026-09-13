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

    /// `internal`, not `private`, and that is a consequence rather than a choice: Swift's
    /// `private` is FILE-scoped, and `fireCrossing` moved to `+Plumbing.swift` when E's R1 grew
    /// this file past the 400-line bar. The `PlaceRoutineScreen+Opening.openExternally`
    /// precedent, recorded in the register — an extension that leaves its type's file leaves
    /// same-file `private` access behind with it.
    let placeId = UUID()
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

    /// **RENAMED with the rule it asserts.** This was
    /// `testARoutineIsReachableFromTodayAndEndsWhenItIsFinished`, and "finished" meant CLOSED:
    /// resolving every step and leaving ended the run. E's R1 reversed that — *"the user must
    /// have to confirm by manually tapping a 'Completed' button before any actions such as
    /// logging it to the Journal or running the animation etc are run"* — so a Close now leaves
    /// the run live and its card on Today, and only the tap ends it. A name asserting the old
    /// rule would be a trap for the next reader, so it moved with the behaviour.
    @MainActor
    func testARoutineIsReachableFromTodayAndEndsOnlyWhenItIsConfirmed() throws {
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

        // 6-8. E's R1: a Close leaves the run LIVE, and only the Completed tap ends it.
        closeThenComeBackAndConfirm(app, continueButton: continueButton)
    }

    /// **The half of this journey that used to assert the opposite.** Closing a fully-resolved
    /// routine ended it, so the old shape was Close → card gone. Under E's R1 nothing is written
    /// and nothing celebrates without a deliberate Completed tap, so a Close now leaves the run
    /// live, its card on Today, and its label swapped to "Finish routine".
    @MainActor
    private func closeThenComeBackAndConfirm(
        _ app: XCUIApplication, continueButton: XCUIElement
    ) {
        // `untilGone:` must name something still ON the screen. Naming the Skip button —
        // which had just been asserted ABSENT — made this return true without ever tapping
        // Close, leaving the cover up and every later assertion reading the screen beneath it.
        XCTAssertTrue(
            UITestSession.tap(app.buttons["Close"], untilGone: named("routineProgress", app)),
            "Close did not dismiss the routine screen"
        )
        openTab("Today", in: app)
        XCTAssertTrue(
            scrollUntilFound(continueButton, in: app),
            "Closing a fully-resolved routine took its card with it. Under E's R1 the run is"
                + " still live — nothing has been confirmed — and Today's card is its only way"
                + " back: losing it here strands a routine one tap from finished."
        )
        XCTAssertEqual(
            continueButton.label, "Finish routine",
            "the card still offers to CONTINUE a routine with nothing left to continue (E's"
                + " answer 8 — the label is the difference between a chore and a finish line)"
        )
        attach(app, "6-resolved-but-unconfirmed")

        // 7. Back in through the card, and THIS time confirm it. The Completed card takes the
        //    slot the next step would have had.
        XCTAssertTrue(
            UITestSession.tap(continueButton, untilExists: app.buttons["routineCompletedButton"]),
            "Reopening a fully-resolved routine never offered the Completed card"
        )
        attach(app, "7-completed-card")
        finishAndDismissTheCongratulation(app)

        // 8. Only NOW is the run over, so only now does the card go.
        XCTAssertTrue(
            waitForGone(continueButton, in: app),
            "A confirmed routine left its card on Today — the run never ended"
        )
        attach(app, "8-after-completion")
    }

    /// Taps Completed, waits on the GREETING, and dismisses by tapping a step ROW.
    ///
    /// **It waits on the greeting rather than on confetti, and that is not a preference.** Both
    /// journeys resolve the gym as 1 auto + 3 skipped, so R-f is not earned and neither ever
    /// sees a single piece of paper. A journey waiting on paper that is never coming hangs to
    /// the timeout and reads exactly like a render failure.
    ///
    /// **And it taps a ROW, not the greeting.** The row is inside the `ScrollView` E asked for
    /// when they reversed answer 6, so this tap is the only thing that exercises the claim that
    /// a TAP reaches the parent's gesture while a DRAG goes to the scroller. Tapping the
    /// greeting — which sits outside it — would prove the gesture works and nothing else.
    @MainActor
    private func finishAndDismissTheCongratulation(_ app: XCUIApplication) {
        let greeting = named("routineCongratulationGreeting", app)
        XCTAssertTrue(
            UITestSession.tap(app.buttons["routineCompletedButton"], untilExists: greeting),
            "The Completed tap never produced the congratulation"
        )
        attach(app, "7b-congratulation")
        XCTAssertTrue(
            UITestSession.tap(named("routineCongratulationStep-0", app), untilGone: greeting),
            "Tapping a step row did not close the congratulation — a tap inside the step list"
                + " is being swallowed by the scroller instead of reaching the parent's gesture"
        )
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
}
