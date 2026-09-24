//
//  TasksAnytimeRowRenderUITests.swift
//  ADHD LifeOSUITests
//
//  `F-D3-TasksAnytimeRow`'s evidence harness — the frames for `screenshots/tasks-anytime-row/`.
//
//  Round 6, E's words: *"The Tasks board gains one collapsed 'Anytime · N' row at the bottom: the
//  tail stays folded, but a new task is visible where it was added."* A unit test proves undated
//  tasks reach the bucket; only the real screen shows the fold applied to real data: the row
//  folded on a fresh account, the COUNT carrying a new task while its row stays hidden, and the
//  rows scrolling under the pinned header once opened.
//
//  A fresh emulator account is seeded as production seeds one: two undated starter tasks and one
//  due tomorrow — so the board opens on "Tomorrow · 1" and "Anytime · 2".
//
//  Run deliberately, one appearance per run, the way `ComposerKeyboardBarUITests` is: set the
//  simulator's appearance and text size with `xcrun simctl ui`, and name the frames with
//  `ANYTIME_RENDER_TAG` (L / D / A), passed as `TEST_RUNNER_ANYTIME_RENDER_TAG`.
//

import XCTest

final class TasksAnytimeRowRenderUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRenderTheAnytimeRow() throws {
        try UITestEmulator.skipUnlessRunning()
        let tag = ProcessInfo.processInfo.environment["ANYTIME_RENDER_TAG"] ?? "X"
        let app = try UITestSession.launchSignedIn(label: "d3anytime")
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )
        UITestSession.openTab("Tasks", in: app)

        // The fold is a DEVICE-wide stored preference, so a previous run may have left it open.
        let seeded = app.staticTexts["Check off your first task"]
        let header = anytimeHeader(in: app)
        XCTAssertTrue(header.waitForExistence(timeout: UITestSession.timeout), "No Anytime row on Momentum")
        if seeded.exists {
            XCTAssertTrue(UITestSession.tap(header, untilGone: seeded), "Could not fold a fold a previous run left open")
        }

        // 1 — folded by default: the count, and none of the rows.
        XCTAssertEqual(header.label, "Anytime · 2", "A fresh account holds two undated starter tasks")
        XCTAssertFalse(seeded.exists, "Folded means the rows are not drawn at all")
        print("MEASURE anytime-\(tag) header=\(header.frame)")
        XCTAssertGreaterThanOrEqual(header.frame.height, 43.5, "The fold's target is \(header.frame.height)pt tall")
        attach(app, named: "collapsed-\(tag)")

        // 2 — a new undated task: counted where it was added, its row still folded.
        let title = "Book the MOT \(UUID().uuidString.prefix(4))"
        try addAnUndatedTask(titled: title, in: app)
        let counted = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Anytime · 3"), object: header
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [counted], timeout: UITestSession.timeout), .completed,
            "The new undated task never reached the Anytime count (header reads \"\(header.label)\")"
        )
        XCTAssertFalse(app.staticTexts[title].exists, "The fold stays closed when a task lands in it")
        attach(app, named: "new-task-counted-\(tag)")

        // 3 — opened: the new task is there, under the other two.
        XCTAssertTrue(UITestSession.tap(header, untilExists: app.staticTexts[title]), "Opening the fold showed no new task")
        XCTAssertTrue(seeded.exists)
        print("MEASURE anytime-\(tag) expanded header=\(header.frame) new=\(app.staticTexts[title].frame)")
        attach(app, named: "expanded-\(tag)")

        // 4 — the header is pinned: scrolled, the rows pass UNDER it and must not show through.
        app.scrollViews.firstMatch.swipeUp()
        print("MEASURE anytime-\(tag) scrolled header=\(header.frame)")
        attach(app, named: "scrolled-\(tag)")

        // Leave the device's fold as it was found — closed — for the next run.
        app.scrollViews.firstMatch.swipeDown()
        XCTAssertTrue(UITestSession.tap(anytimeHeader(in: app), untilGone: app.staticTexts[title]), "Could not re-fold")
    }

    // MARK: - Plumbing

    /// By LABEL: `tasksAnytimeHeader` sits on the header's container, and a container's identifier
    /// is inherited by what is inside it, so the button is found by what it says.
    @MainActor
    private func anytimeHeader(in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Anytime")).firstMatch
    }

    @MainActor
    private func addAnUndatedTask(titled title: String, in app: XCUIApplication) throws {
        let field = app.descendants(matching: .any).matching(identifier: "taskCreateTitleField").firstMatch
        XCTAssertTrue(
            UITestSession.tap(app.buttons["taskCreateButton"], untilExists: field),
            "The task composer never opened from Tasks"
        )
        UITestSession.focusAndType(field, text: title, in: app)
        let submit = app.buttons["taskCreateSubmitButton"]
        XCTAssertTrue(submit.isEnabled, "Add stayed disabled with a title entered")
        submit.tap()
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: field)
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: UITestSession.timeout), .completed, "The composer never closed")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
