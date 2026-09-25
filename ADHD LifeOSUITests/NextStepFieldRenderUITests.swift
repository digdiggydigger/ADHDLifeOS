//
//  NextStepFieldRenderUITests.swift
//  ADHD LifeOSUITests
//
//  `F-E2-NextStepField`'s evidence harness — the frames for `screenshots/next-step-field/`.
//
//  E's round 5a: *"Next step → 'A "Next step" field.' One optional line on a task, editable from
//  the card and from task detail."* The card half is `F-E3`'s. Unit tests pin the wire key and the
//  Save diff; only the real screen shows the row where it sits, the line surviving a Save and a
//  fresh fetch, and the row reflowing at an accessibility text size.
//
//  Run deliberately, one appearance per run: set `xcrun simctl ui … appearance` / `content_size`
//  before the run and name the frames with `NEXTSTEP_RENDER_TAG` (L / D / A), passed as
//  `TEST_RUNNER_NEXTSTEP_RENDER_TAG`.
//

import XCTest

final class NextStepFieldRenderUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRenderTheNextStepRow() throws {
        try UITestEmulator.skipUnlessRunning()
        let tag = ProcessInfo.processInfo.environment["NEXTSTEP_RENDER_TAG"] ?? "X"
        let app = try UITestSession.launchSignedIn(label: "e2nextstep")
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        // 1 — an untouched task: the empty row, beside Notes, with nothing to Save.
        try openTheWalk(app)
        let field = row("taskDetailNextStepField", in: app)
        UITestSession.scrollUntilHittable(field, in: app)
        XCTAssertTrue(field.exists, "Task Detail draws no Next Step row")
        print("MEASURE nextstep-\(tag) field=\(field.frame)")
        attach(app, named: "01-empty-row-\(tag)")
        // Save sits below the fold, and a lazily built Form has no element for it until it is
        // scrolled to — the light run failed "no matches" right here while the dark one passed.
        let save = app.buttons["taskDetailSaveButton"].firstMatch
        UITestSession.scrollUntilHittable(save, in: app)
        XCTAssertFalse(save.isEnabled, "An untouched task reads as edited")
        UITestSession.scrollUntilHittable(field, in: app)

        // 2 — typed: Save enables.
        let line = "Put my trainers by the door"
        UITestSession.focusAndType(field, text: line, in: app)
        UITestSession.scrollUntilHittable(save, in: app)
        XCTAssertTrue(save.isEnabled, "A typed next step did not enable Save")
        attach(app, named: "02-typed-\(tag)")

        // 3 — saved, left and reopened: the line came back from the document, not the screen.
        save.tap()
        app.navigationBars.buttons.firstMatch.tap()
        try openTheWalk(app)
        let reopened = row("taskDetailNextStepField", in: app)
        UITestSession.scrollUntilHittable(reopened, in: app)
        let persisted = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", line), object: reopened
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [persisted], timeout: UITestSession.timeout), .completed,
            "The saved line did not come back (field reads \"\(reopened.value ?? "nil")\")"
        )
        print("MEASURE nextstep-\(tag) reopened=\(reopened.frame)")
        attach(app, named: "03-reopened-\(tag)")
    }

    // MARK: - Plumbing

    /// Opens "Take a 10-minute walk" from Tasks — the ON-SCREEN copy, because Today's hero shows
    /// the same seeded task on a tab parked ~10,000pt away that is still in the hierarchy.
    @MainActor
    private func openTheWalk(_ app: XCUIApplication) throws {
        UITestSession.openTab("Tasks", in: app)
        let walk = try XCTUnwrap(
            onScreen(app.staticTexts.matching(NSPredicate(format: "label == %@", "Take a 10-minute walk"))),
            "The seeded task is not on the Tasks board"
        )
        let title = row("taskDetailTitleField", in: app)
        XCTAssertTrue(UITestSession.tap(walk, untilExists: title), "Task detail never opened")
    }

    @MainActor
    private func row(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    private func onScreen(_ query: XCUIElementQuery) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(UITestSession.timeout)
        while Date() < deadline {
            let screen = XCUIApplication().frame
            if let hit = query.allElementsBoundByIndex.first(where: { screen.intersects($0.frame) }) { return hit }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return nil
    }

    @MainActor
    private func attach(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
