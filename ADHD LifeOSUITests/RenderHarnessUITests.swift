//
//  RenderHarnessUITests.swift
//  ADHD LifeOSUITests
//
//  TEMPORARY — a render harness, not a test. It asserts almost nothing; it drives the app to one
//  screen and attaches screenshots so E can look at a change before it reaches the device. The
//  standing lesson is that three journal-pad colour attempts were rejected on device before a
//  render loop existed (F-PadNightRender).
//
//  Delete this file before the block commits, or commit it deliberately — do not leave it behind.
//

import XCTest

final class RenderHarnessUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Opens the rebuilt New nudge sheet and photographs it in whatever appearance the simulator
    /// is currently set to (`xcrun simctl ui booted appearance light|dark`).
    @MainActor
    func testRenderNewNudgeSheet() throws {
        try UITestEmulator.skipUnlessRunning()

        // Seed a nudge BEFORE launching. First-run seeding creates life areas, tags, tasks and a
        // journal entry but never a nudge, and `loadedNudgesSection` is gated on
        // `!due.isEmpty || scheduled > 0` — so on a fresh account the whole nudges section,
        // door included, does not render at all. The first run of this harness failed on exactly
        // that, and said so accurately: "Today never rendered the nudges door".
        let account = try UITestSession.createAccount(label: "render")
        try seedScheduledNudge(id: UUID(), label: "Drink water", uid: account.uid)
        let app = try UITestSession.launchSignedIn(as: account)

        // Today → the nudges door, using the navigation `CaptureDiscClearanceUITests` proved out:
        // Today is a LazyVStack, so a row below the fold does not merely fail to be hittable, it
        // does not EXIST — scroll it into being, then into reach, and use the header's add button
        // as the arrival landmark rather than anything below the fold.
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )
        let door = app.buttons["homeManageNudgesRow"]
        // Settles between swipes; a tight loop does not scroll at all.
        UITestSession.scrollUntilHittable(door, in: app)
        XCTAssertTrue(door.exists, "Today never rendered the nudges door, even scrolled to the end")
        XCTAssertTrue(
            UITestSession.tap(door, untilExists: app.buttons["nudgeAddButton"]),
            "The nudges screen never opened"
        )

        // The header + button, rather than the row at the bottom of the list: it is present
        // without scrolling, so it cannot be the source of a below-the-fold miss.
        XCTAssertTrue(
            UITestSession.tap(app.buttons["nudgeAddButton"], untilExists: app.textFields["nudgeAddLabelField"]),
            "The New nudge sheet never opened"
        )

        attach(app, named: "1-new-nudge-default")

        // Custom reveals the day row — the part that used to wrap every label mid-word.
        let custom = app.buttons["nudgeAddPreset-custom"]
        XCTAssertTrue(custom.waitForExistence(timeout: UITestSession.timeout), "No Custom chip")
        custom.tap()
        attach(app, named: "2-new-nudge-custom-days")

        // And a named preset, so the summary line is shown saying a real sentence.
        //
        // Settled on a real CONDITION before capturing, not a sleep. The first attempt shot
        // immediately after the tap and caught the spring mid-flight — the day row ghosting as it
        // collapsed, the chip half-filled, its label washed out. The state was right and the
        // picture was a lie, which is worse than no picture. Choosing Weekdays closes the day row,
        // so the row's own disappearance is the thing to wait on.
        let weekdays = app.buttons["nudgeAddPreset-weekdays"]
        XCTAssertTrue(weekdays.waitForExistence(timeout: UITestSession.timeout), "No Weekdays chip")
        XCTAssertTrue(
            UITestSession.tap(weekdays, untilGone: app.buttons["nudgeAddWeekdayToggle-0"]),
            "Choosing Weekdays did not close the Custom day row"
        )
        attach(app, named: "3-new-nudge-weekdays")
    }

    /// One ACTIVE, not-yet-due nudge — enough to make the door render in its quiet state.
    ///
    /// Deliberately not overdue: an overdue nudge puts a due card above the door and pushes it
    /// further down the scroll for no benefit here. The schedule fires daily at 23:59 and
    /// `created_at` is now, so its next fire is always ahead of the reference date.
    private func seedScheduledNudge(id: UUID, label: String, uid: String) throws {
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/nudges/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "label": UITestEmulator.string(label),
                "schedule": UITestEmulator.string("59 23 * * 0,1,2,3,4,5,6"),
                "active": UITestEmulator.bool(true),
                "created_at": UITestEmulator.timestamp(Date()),
                "updated_at": UITestEmulator.timestamp(Date())
            ]
        )
    }

    /// The first-run nudges door: muted card, lit "Add your first nudge".
    ///
    /// Seeds NOTHING — the whole point is what a brand-new account sees.
    @MainActor
    func testRenderFirstRunNudgesDoor() throws {
        try UITestEmulator.skipUnlessRunning()

        let app = try UITestSession.launchSignedIn(label: "firstrunrender")
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )
        let door = app.buttons["homeManageNudgesRow"]
        // Settles between swipes; a tight loop does not scroll at all.
        UITestSession.scrollUntilHittable(door, in: app)
        XCTAssertTrue(door.exists, "No nudges door on a fresh account")
        XCTAssertTrue(
            app.buttons["homeNudgesFirstRunDirective"].waitForExistence(timeout: UITestSession.timeout),
            "The first-run door showed no 'Add your first nudge' direction"
        )
        attach(app, named: "4-first-run-nudges-door")
    }

    /// The Create-account form with the keyboard UP — the two things E marked on device:
    /// no Done bar floating above the keyboard, and a password card the same height as the others.
    @MainActor
    func testRenderSignUpForm() throws {
        let app = UITestSession.launchSignedOut()

        let email = app.textFields["loginEmailField"]
        XCTAssertTrue(email.waitForExistence(timeout: UITestSession.timeout), "No login form")

        // Switch to Create account so the name field is in play and the password card sits
        // between two others — which is what makes an uneven height visible.
        // A segmented Picker: its segments are buttons labelled by the mode titles, addressed
        // through the control rather than by an identifier of their own.
        let createAccount = app.segmentedControls["authModePicker"].buttons["Create account"]
        XCTAssertTrue(
            createAccount.waitForExistence(timeout: UITestSession.timeout),
            "No Create account segment on the mode picker"
        )
        XCTAssertTrue(
            UITestSession.tap(createAccount, untilExists: app.textFields["signUpNameField"]),
            "Create account did not reveal the sign-up fields"
        )

        // Focus the PASSWORD field: the keyboard has to be up for the Done bar to be visible at
        // all, so a shot with it dismissed would prove nothing about the thing being fixed.
        let password = app.secureTextFields["loginPasswordField"]
        XCTAssertTrue(password.waitForExistence(timeout: UITestSession.timeout), "No password field")
        password.tap()
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 10), "Keyboard never appeared")

        attach(app, named: "5-signup-keyboard-up")
    }

    /// F-LandscapeFix's scout: every tab plus both composers, photographed in landscape, so the
    /// sweep the block promises is a set of renders rather than a set of guesses. Both composers
    /// are dismissed by SUBMITTING — the throwaway emulator account absorbs the entry and the
    /// capture, and submitting exercises the landscape flow instead of tiptoeing around it.
    @MainActor
    func testRenderLandscapeSweep() throws {
        try UITestEmulator.skipUnlessRunning()
        let app = try UITestSession.launchSignedIn(label: "landsweep")

        addTeardownBlock { @MainActor in
            UITestSession.resetToPortrait()
        }
        XCTAssertTrue(
            UITestSession.rotateToLandscape(app),
            "The window never went landscape — these stills would photograph portrait"
        )

        attach(app, named: "landscape-1-today")
        try sweepFanAndNoteComposer(app)

        for tab in ["Tasks", "Areas", "Captures"] {
            let button = UITestSession.tabButton(tab, in: app)
            XCTAssertTrue(button.waitForExistence(timeout: UITestSession.timeout), "No \(tab) tab")
            button.tap()
            attach(app, named: "landscape-\(tab.lowercased())")
        }
        try sweepJournalPad(app)
    }

    /// The fan opens and the note tile is tapped IN LANDSCAPE — F-FanLandscape's whole point.
    /// This exact step used to be impossible (the portrait arc put Note at y = −168 and the
    /// first sweep run died on it with kAXErrorCannotComplete), and the sweep had to detour
    /// through portrait; the horizontal-left fan is what makes the direct route exist. If this
    /// tap ever fails off-screen again, the wiring between `CaptureFan.horizontalSlots` and the
    /// overlay is gone — the table alone proves nothing (the dead-shared-component trap).
    @MainActor
    private func sweepFanAndNoteComposer(_ app: XCUIApplication) throws {
        let fab = app.buttons["quickCaptureButton"]
        let noteTile = app.buttons["captureFan-note"]
        XCTAssertTrue(
            UITestSession.tap(fab, untilExists: noteTile),
            "The capture fan never opened"
        )
        attach(app, named: "landscape-2-capture-fan")
        XCTAssertTrue(
            UITestSession.tap(noteTile, untilExists: app.textFields["quickCaptureContentField"]),
            "The note composer never opened from the fan tile tapped in landscape"
        )
        attach(app, named: "landscape-3-note-composer")
        UITestSession.focusAndType(
            app.textFields["quickCaptureContentField"], text: "Landscape sweep capture", in: app
        )
        attach(app, named: "landscape-4-note-composer-keyboard")
        XCTAssertTrue(
            UITestSession.tap(
                app.buttons["quickCaptureSubmitButton"],
                untilGone: app.textFields["quickCaptureContentField"]
            ),
            "The note composer never submitted, so the sweep cannot continue past it"
        )
    }

    @MainActor
    private func sweepJournalPad(_ app: XCUIApplication) throws {
        let journalTab = UITestSession.tabButton("Journal", in: app)
        XCTAssertTrue(journalTab.waitForExistence(timeout: UITestSession.timeout), "No Journal tab")
        journalTab.tap()
        attach(app, named: "landscape-5-journal")
        XCTAssertTrue(
            UITestSession.tap(
                app.buttons["journalComposeButton"],
                untilExists: app.textFields["logComposerBodyField"]
            ),
            "The journal pad never opened"
        )
        attach(app, named: "landscape-6-journal-pad")
        UITestSession.focusAndType(
            app.textFields["logComposerBodyField"], text: "Landscape sweep entry", in: app
        )
        attach(app, named: "landscape-7-journal-pad-keyboard")
        XCTAssertTrue(
            UITestSession.tap(
                app.buttons["logComposerSubmitButton"],
                untilGone: app.textFields["logComposerBodyField"]
            ),
            "The journal pad never submitted"
        )
    }

    @MainActor
    private func attach(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
