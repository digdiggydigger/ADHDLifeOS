//
//  ComposerBothDoorsRenderUITests.swift
//  ADHD LifeOSUITests
//
//  A render harness for `F-D1-ComposerBothDoors`, not a test — it produces
//  `screenshots/composer-both-doors/`. It asserts only enough to fail loudly when it photographs
//  the wrong thing.
//
//  **One harness, both sides of the block, and it LABELS ITS OWN FRAMES from what it finds.** The
//  acceptance criterion wants the two doors BEFORE (two unrelated composers) and AFTER (one). So
//  this file was written first, run against the pre-block tree, and run again once the block
//  landed — and rather than a flag saying which tree it is on, it reads the answer off the screen:
//  - the capture disc's Task tile opened `QuickCaptureView` (`quickCaptureContentField`) before,
//    and opens the task composer (`taskCreateTitleField`) after;
//  - the Tasks "+" composer had a notes field (`taskCreateNotesField`) before, and has none after.
//  A frame named `before-` is therefore a claim the hierarchy made, not one the runner was told.
//
//  **Opened EMPTY, keyboard down, on purpose.** The claim is "the same composer, with the settled
//  content" — the whole form has to be in the frame. Typing raises the keyboard over the bottom
//  half and photographs a title field.
//
//  Appearance is whatever the simulator is set to (`xcrun simctl ui booted appearance
//  light|dark`), so one journey makes both sets — `UndoCapsuleRenderUITests`' arrangement.
//

import XCTest

final class ComposerBothDoorsRenderUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRenderTheTaskComposerFromBothDoors() throws {
        try UITestEmulator.skipUnlessRunning()
        let app = try UITestSession.launchSignedIn(label: "composerdoors")
        // Existence, never `settle`: the disc exists from the first frame and is never hittable
        // by XCUITest's measure (`screenshots/recently-deleted-tags/README.md`, trap 1).
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        let afterTasksPlus = renderTheTasksPlusDoor(app)
        let afterDisc = renderTheDiscDoor(app)
        XCTAssertEqual(
            afterTasksPlus, afterDisc,
            "One door shows the pre-block composer and the other the post-block one — this build"
                + " is half-way between the two, which is exactly the state the block exists to end"
        )
    }

    // MARK: - Door 1: the Tasks tab's "+"

    /// Returns whether this is the AFTER tree, read from the composer's own content.
    @MainActor
    private func renderTheTasksPlusDoor(_ app: XCUIApplication) -> Bool {
        UITestSession.openTab("Tasks", in: app)
        let field = app.textFields["taskCreateTitleField"]
        guard UITestSession.tap(app.buttons["taskCreateButton"], untilExists: field) else {
            XCTFail("The task composer never opened from Tasks")
            return false
        }
        // The notes field sat below the fold on the old composer, so absence is only meaningful
        // once the form has had time to build — wait on the Add button, which is pinned.
        _ = app.buttons["taskCreateSubmitButton"].waitForExistence(timeout: UITestSession.timeout)
        let isAfter = !app.textFields["taskCreateNotesField"].exists
            && !app.textViews["taskCreateNotesField"].exists
        attach(app, named: isAfter ? "03-after-tasks-plus-composer" : "01-before-tasks-plus-composer")

        if isAfter {
            renderTheMenus(app)
        }
        close(app, button: app.buttons["taskCreateCloseButton"], field: field)
        return isAfter
    }

    /// Both menus OPEN — the "pop-up chips (menus, not sheets)" half of E's round 6 answer, which
    /// a closed-menu frame cannot show.
    @MainActor
    private func renderTheMenus(_ app: XCUIApplication) {
        let area = app.buttons["taskCreateLifeAreaPicker"]
        let time = app.buttons["taskCreateTimeMenu"]
        // **The one real assertion here, and the first after-run is why.** That build padded each
        // card from OUTSIDE its Menu: the card drew 48pt tall, the Area button measured 338 x 20.3,
        // and a tap anywhere but the line of text did nothing. A frame is the only place that
        // difference exists — the picture looked right.
        for (control, name) in [(area, "Area"), (time, "Time")] {
            XCTAssertTrue(control.waitForExistence(timeout: UITestSession.timeout), "No \(name) control")
            XCTAssertGreaterThanOrEqual(
                control.frame.height, 48,
                "The \(name) menu's tap target is \(control.frame.height)pt tall"
                    + " — round 7 keeps the composer's own controls at 48"
            )
        }
        let none = app.buttons["None"]
        if UITestSession.tap(area, untilExists: none) {
            attach(app, named: "05-after-area-menu-open")
            _ = UITestSession.tap(none, untilGone: none)
        } else {
            XCTFail("The Area control opened no menu with a \"None\" row")
        }

        let hour = app.buttons["1 hr"]
        if UITestSession.tap(time, untilExists: hour) {
            attach(app, named: "06-after-time-menu-open")
            _ = UITestSession.tap(app.buttons["15 min"], untilGone: hour)
        } else {
            XCTFail("The Time control opened no menu with a \"1 hr\" row")
        }
    }

    // MARK: - Door 2: the capture disc's Task tile

    @MainActor
    private func renderTheDiscDoor(_ app: XCUIApplication) -> Bool {
        let tile = app.buttons["captureFan-task"]
        guard UITestSession.tap(app.buttons["quickCaptureButton"], untilExists: tile) else {
            XCTFail("The capture fan never opened")
            return false
        }
        let before = app.textFields["quickCaptureContentField"]
        let after = app.textFields["taskCreateTitleField"]
        tile.tap()
        let opened = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in before.exists || after.exists }, object: nil
        )
        guard XCTWaiter().wait(for: [opened], timeout: UITestSession.timeout) == .completed else {
            attach(app, named: "02-disc-task-OPENED-NOTHING")
            XCTFail("The Task tile opened neither composer")
            return false
        }
        let isAfter = after.exists
        attach(app, named: isAfter ? "04-after-disc-task-composer" : "02-before-disc-task-composer")

        if isAfter {
            close(app, button: app.buttons["taskCreateCloseButton"], field: after)
        } else {
            close(app, button: app.buttons["quickCaptureCloseButton"], field: before)
        }
        return isAfter
    }

    // MARK: - Plumbing

    @MainActor
    private func close(_ app: XCUIApplication, button: XCUIElement, field: XCUIElement) {
        if !UITestSession.tap(button, untilGone: field) {
            XCTFail("Close did not dismiss the composer")
        }
    }

    @MainActor
    private func attach(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
