//
//  UndoCapsuleRenderUITests.swift
//  ADHD LifeOSUITests
//
//  TEMPORARY — a render harness for `F-C1-UndoCapsule`, not a test. It asserts only enough to fail
//  loudly when it photographs the wrong thing; its job is to drive the REAL app to each surface
//  the capsule appears on and attach a frame, so E settles the shape by looking.
//
//  **Why the real app rather than a preview.** Two of the frames E is owed cannot be produced any
//  other way: the Journal's disc row, where the capsule has to stand in for the pencil while the +
//  disc stays put, and compact-height landscape with a sprint card up, where
//  `RootBottomOverlayLayout` puts the cards BESIDE the disc row and the row takes its own width. A
//  preview of the capsule in isolation shows neither — the whole question is what the capsule does
//  to the furniture around it.
//
//  Follows `RenderHarnessUITests`: skip without the emulator, create an account, drive, attach.
//  **Delete this file before the block commits, or commit it deliberately — do not leave it
//  behind.** (Committed deliberately: E asked for the two unrendered cases, and the next arc-C
//  block reuses the capsule.)
//

import XCTest

final class UndoCapsuleRenderUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Every portrait surface in one run, because the expensive part is the account and the sign-in,
    /// not the navigation. Appearance is whatever the simulator is set to
    /// (`xcrun simctl ui booted appearance light|dark`), and the text size is whatever
    /// `-UIPreferredContentSizeCategoryName` was launched with, so the same journey produces the
    /// light, dark and AX3 sets without three copies of it.
    @MainActor
    func testRenderTheCapsuleOnEverySurface() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "undocapsule")
        // **Text size comes from the SIMULATOR, not from a launch argument.** The first AX pass
        // passed `-UIPreferredContentSizeCategoryName` and produced frames a size or two up from
        // default in which the capsule never stacked — `isAccessibilitySize` was false, so it was
        // photographing the ordinary layout and calling it AX3. Set it with
        // `xcrun simctl ui <udid> content_size accessibility-extra-large` before the run instead.
        let app = try UITestSession.launchSignedIn(as: account)
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        // **Order matters, and this is the second arrangement.** The first ran Today LAST and it
        // never rendered: first-run seeding leaves two open tasks, the earlier surfaces had closed
        // both, and Today's hero is "the one task worth doing next" — with none left there is no
        // hero and no close button. So Today goes first, and every surface that closes something
        // takes it back before moving on, except the one whose capsule the NEXT surface needs.
        renderToday(app)
        renderTasks(app)
        renderJournal(app)
        renderCaptureInbox(app)
        renderCollision(app)
    }

    /// Taps the capsule's own Undo, restoring whatever the last frame closed so the next surface
    /// still has something to close. This is the harness using the feature it is photographing,
    /// which is a decent smoke test of it in passing.
    @MainActor
    private func takeItBack(_ app: XCUIApplication) {
        let undo = app.buttons["undoCapsuleButton"]
        guard undo.waitForExistence(timeout: 5) else { return }
        undo.tap()
        _ = app.otherElements["undoCapsule"].waitForNonExistence(timeout: UITestSession.timeout)
    }

    // MARK: - Tasks — the capsule standing in for the search row

    @MainActor
    private func renderTasks(_ app: XCUIApplication) {
        UITestSession.openTab("Tasks", in: app)
        let searchRow = app.buttons["appSearchRow"]
        XCTAssertTrue(
            searchRow.waitForExistence(timeout: UITestSession.timeout),
            "Tasks never showed the search row, so there is nothing for the capsule to stand in for"
        )
        attach(app, named: "01-tasks-before-the-close")

        guard let circle = firstCloseCircle(in: app) else {
            return XCTFail("Tasks has no open task to close — first-run seeding did not land")
        }
        circle.tap()
        XCTAssertTrue(
            app.otherElements["undoCapsule"].waitForExistence(timeout: UITestSession.timeout),
            "Closing a task on Tasks showed no capsule"
        )
        attach(app, named: "02-tasks-capsule-stands-in-for-search")
        // Deliberately NOT taken back: the Journal frame below needs this very capsule still
        // pending, because the Journal is where it has to displace the PENCIL.
    }

    // MARK: - Journal — the capsule against the pencil disc (board 54 never rendered this)

    @MainActor
    private func renderJournal(_ app: XCUIApplication) {
        UITestSession.openTab("Journal", in: app)
        // The capsule from the Tasks close above is still pending — that is the whole point: the
        // Journal is where the capsule has to displace the PENCIL rather than a search row.
        XCTAssertTrue(
            app.otherElements["undoCapsule"].waitForExistence(timeout: UITestSession.timeout),
            "The capsule did not survive the tab switch, so the Journal case cannot be photographed"
        )
        attach(app, named: "03-journal-capsule-displaces-the-pencil")
        takeItBack(app)
    }

    // MARK: - The Capture Inbox — the migrated bar

    @MainActor
    private func renderCaptureInbox(_ app: XCUIApplication) {
        UITestSession.openTab("Captures", in: app)
        // **Skip rather than Sorted, deliberately.** Sorting needs an area chip picked first, and
        // which chips exist depends on what first-run seeding wrote — a frame that can be lost to
        // a seeding difference is a frame that will be missing on the run that matters. Skip is
        // one tap and exercises the same slot; `UndoCapsulePresentationTests` holds the Sorted
        // verb's own words, which is the only thing this frame would have added.
        // First-run seeding writes life areas, tasks and a journal entry but **no capture**, so
        // the inbox is empty on a fresh account and there is nothing to triage. The harness writes
        // one itself rather than photographing an empty screen — and the capture it writes is what
        // makes the collision frame below a real collision rather than an empty slot.
        let skip = app.buttons["captureInboxSkipButton"]
        if !skip.waitForExistence(timeout: 6) {
            writeACapture(app)
            UITestSession.openTab("Captures", in: app)
            guard skip.waitForExistence(timeout: UITestSession.timeout) else {
                attach(app, named: "04-inbox-EMPTY-nothing-to-triage")
                return
            }
        }
        skip.tap()
        XCTAssertTrue(
            app.otherElements["undoCapsule"].waitForExistence(timeout: UITestSession.timeout),
            "Triaging a capture showed no capsule — the inbox's own bar was retired onto it"
        )
        attach(app, named: "04-inbox-capsule-and-header-arrow")
    }

    // MARK: - The collision E is owed a look at

    /// One slot, one occupant: a task close SPENDS a pending capture undo. This is the consequence
    /// of E's own "one bottom bar everywhere" and the block report names it; the frame is so E can
    /// see what it actually looks like rather than read about it.
    @MainActor
    private func renderCollision(_ app: XCUIApplication) {
        UITestSession.openTab("Tasks", in: app)
        guard let circle = firstCloseCircle(in: app) else { return }
        circle.tap()
        XCTAssertTrue(app.otherElements["undoCapsule"].waitForExistence(timeout: UITestSession.timeout))
        attach(app, named: "05-collision-the-close-spent-the-captures-undo")

        UITestSession.openTab("Captures", in: app)
        // The header ↶ reads the SAME slot (E's Step 0 answer 2), so a task close spending the
        // capture's undo takes the arrow with it. That is the half of the collision a frame of
        // Tasks alone cannot show.
        _ = app.buttons["captureInboxUndoHeaderButton"].waitForNonExistence(timeout: 5)
        attach(app, named: "06-inbox-header-arrow-gone-with-the-spent-undo")
    }

    /// One note capture through the fan, the recipe `RenderHarnessUITests` already proved out.
    @MainActor
    private func writeACapture(_ app: XCUIApplication) {
        let noteTile = app.buttons["captureFan-note"]
        guard UITestSession.tap(app.buttons["quickCaptureButton"], untilExists: noteTile) else { return }
        guard UITestSession.tap(noteTile, untilExists: app.textFields["quickCaptureContentField"]) else { return }
        UITestSession.focusAndType(
            app.textFields["quickCaptureContentField"], text: "Ask Sam about the spare key", in: app
        )
        _ = UITestSession.tap(
            app.buttons["quickCaptureSubmitButton"],
            untilGone: app.textFields["quickCaptureContentField"]
        )
    }

    // MARK: - Today — the hero's close, and the retired celebration card

    @MainActor
    private func renderToday(_ app: XCUIApplication) {
        UITestSession.openTab("Today", in: app)
        // Photographed on ARRIVAL, before anything is looked for. Today is a `LazyVStack` and the
        // first two attempts at this frame reached for the hero's button and then scrolled to find
        // it — which walked PAST it, because the hero is near the top, and left a frame of the
        // bottom of the page labelled "no hero". The page as the user meets it is the frame.
        // **`descendants`, not `app.buttons`.** The identifier is applied inside a
        // `CelebrationPopSource` wrapper, so it lands on a container and the button query misses
        // it — the same correction `SprintBarFurnitureUITests` makes for `focusTimerBar`. The dark
        // run photographed a hero with a perfectly visible "Close it" on it and reported that
        // Today had no close button, which is how this was found.
        // **By LABEL, with the identifier as the fallback.** The button is wrapped in a
        // `CelebrationPopSource` and sits inside a `.bentoCard()`, and an ancestor that combines
        // its children takes every descendant identifier with it — so neither `app.buttons[id]`
        // nor a `descendants` match finds it, and both dark and light photographed a hero with a
        // perfectly visible "Close it" on it while reporting there was none. The label is what
        // survives (`sprint-seed-harness-traps`: find by label when a container owns the id).
        var close = app.buttons["Close it"]
        if !close.waitForExistence(timeout: 10) {
            close = app.descendants(matching: .any).matching(identifier: "homeCloseTaskButton").firstMatch
            _ = close.waitForExistence(timeout: 5)
        }
        attach(app, named: "07-today-hero-before-the-close")
        guard close.exists else { return }
        // The RETRYING tap, not a bare one. The element reports itself as "not hittable" on the
        // first attempt often enough to fail a run outright — the hero has just been laid out and
        // the scroll view is still settling — and this frame is not worth losing the four after it.
        guard UITestSession.tap(close, untilExists: app.otherElements["undoCapsule"]) else {
            attach(app, named: "08-today-CLOSE-NEVER-LANDED")
            return
        }
        XCTAssertFalse(
            app.otherElements["homeClosureCelebration"].exists,
            "The retired in-place closure card is still being drawn"
        )
        attach(app, named: "08-today-capsule-replaces-the-closure-card")
        takeItBack(app)
    }

    // MARK: - Compact-height landscape with a sprint card up (the second unrendered case)

    @MainActor
    func testRenderLandscapeWithASprintRunning() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "undocapsulelandscape")
        // A SEEDED sprint, not a driven one: a running sprint is what makes
        // `RootBottomOverlayLayout` choose `.besideTheDisc`, and seeding it through the launch
        // arguments takes the start flow's own reliability out of a frame that is about layout.
        let app = try UITestSession.launchSignedIn(
            as: account,
            launchArguments: UITestSession.pausedSprintLaunchArguments(
                taskTitle: "undo capsule landscape", collapsed: true
            )
        )
        XCTAssertTrue(app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout))

        let bar = app.descendants(matching: .any).matching(identifier: "focusTimerBar").firstMatch
        XCTAssertTrue(
            bar.waitForExistence(timeout: UITestSession.timeout),
            "The seeded sprint's timer bar never appeared, so the layout will not choose"
                + " `.besideTheDisc` and this frame would photograph the ordinary arrangement."
        )

        UITestSession.openTab("Tasks", in: app)
        if let circle = firstCloseCircle(in: app) {
            circle.tap()
            _ = app.otherElements["undoCapsule"].waitForExistence(timeout: UITestSession.timeout)
        }
        attach(app, named: "09-landscape-portrait-reference")

        XCUIDevice.shared.orientation = .landscapeLeft
        _ = app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout)
        attach(app, named: "10-landscape-capsule-beside-the-sprint-card")
        // **`app.screenshot()` LIES on a rotated simulator** (F-LandscapeFix): the attachment
        // above comes back letterboxed portrait with the content squeezed into a column, and the
        // first landscape run produced exactly that. The ground-truth frame is
        // `xcrun simctl io <udid> screenshot` taken from OUTSIDE the test while it holds the pose.
        // This is the pose being held; the attachment stays as the record that it was reached.
        Thread.sleep(forTimeInterval: 25)
        // Orientation outlives the whole RUN (`ui-test-cross-run-state`), so it is put back here
        // rather than left for whichever test happens to go next.
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Driving

    /// The first open task's tap-circle, by identifier prefix — the rows carry
    /// `taskCheckbox-<uuid>` and the harness cannot know which uuid seeding produced.
    @MainActor
    private func firstCloseCircle(in app: XCUIApplication) -> XCUIElement? {
        let circles = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'taskCheckbox-'")
        )
        guard circles.firstMatch.waitForExistence(timeout: UITestSession.timeout) else { return nil }
        let circle = circles.firstMatch
        return circle.isHittable ? circle : nil
    }

    @MainActor
    private func attach(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
