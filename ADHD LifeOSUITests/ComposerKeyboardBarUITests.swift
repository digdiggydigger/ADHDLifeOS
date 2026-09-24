//
//  ComposerKeyboardBarUITests.swift
//  ADHD LifeOSUITests
//
//  `F-D2-ComposerKeyboardLayout`. Two things only a running app can say about round 7b's L3:
//
//  1. **The pin findings §L asked for** — *"Opening Area, Time or the date picker must NOT dismiss
//     the keyboard, or the bar drops 336pt and jumps back (research §3.2). A test pins it."* The
//     record called this UNVERIFIED: nobody had checked what a SwiftUI `Menu` or a popover does to
//     the first responder.
//  2. **The frames** for `screenshots/composer-l3-layout/`, keyboard up and down, the Date segment
//     before and after a pick, and the stacked form at an accessibility size.
//
//  **While a Menu is open, the app beneath it leaves the accessibility tree** — the text field and
//  the bar cannot be queried until the menu closes. So the pin reads the keyboard (its own window)
//  while a choice is open and the field's focus and the bar's frame once it has closed; and the
//  frames record what the queries cannot.
//
//  Appearance is whatever the simulator is set to (`xcrun simctl ui <udid> appearance
//  light|dark`), so one render run per appearance — `ComposerBothDoorsRenderUITests`' arrangement.
//

import XCTest

final class ComposerKeyboardBarUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - The pin

    @MainActor
    func testTheKeyboardStaysUpWhileAChoiceIsOpen() throws {
        try UITestEmulator.skipUnlessRunning()
        let app = try UITestSession.launchSignedIn(label: "d2keyboard")
        let field = try openTheComposer(app)
        field.tap()
        field.typeText("Rides the keyboard")
        let bar = app.otherElements["taskComposerKeyboardBar"]
        XCTAssertTrue(bar.waitForExistence(timeout: UITestSession.timeout), "The composer has no keyboard bar")
        XCTAssertTrue(
            app.keyboards.element.waitForExistence(timeout: UITestSession.timeout),
            "No software keyboard came up — check the simulator's Connect Hardware Keyboard"
        )
        let raised = bar.frame
        XCTAssertLessThanOrEqual(
            raised.maxY, app.keyboards.element.frame.minY + 1,
            "The bar is not above the keyboard: bar \(raised), keyboard \(app.keyboards.element.frame)"
        )

        let none = app.buttons["None"]
        XCTAssertTrue(
            UITestSession.tap(app.buttons["taskCreateLifeAreaPicker"], untilExists: none), "Area opened no menu"
        )
        assertTheKeyboardIsUp(app, while: "the Area menu is open")
        _ = UITestSession.tap(none, untilGone: none)
        assertStillRaised(app, field: field, bar: bar, at: raised, after: "the Area menu closed")

        let hour = app.buttons["1 hr"]
        XCTAssertTrue(UITestSession.tap(app.buttons["taskCreateTimeMenu"], untilExists: hour), "Time opened no menu")
        assertTheKeyboardIsUp(app, while: "the Time menu is open")
        _ = UITestSession.tap(app.buttons["15 min"], untilGone: hour)
        assertStillRaised(app, field: field, bar: bar, at: raised, after: "the Time menu closed")

        let date = app.buttons["taskCreateDue-Date"]
        XCTAssertEqual(date.label, "Date", "The Date segment does not read \"Date\" before a pick")
        let picker = app.datePickers["taskCreateDueDatePicker"]
        XCTAssertTrue(UITestSession.tap(date, untilExists: picker), "Date opened no picker")
        assertTheKeyboardIsUp(app, while: "the date popover is open")
        pickTheTenthOfNextMonth(in: picker)
        XCTAssertTrue(waitUntilGone(picker), "Picking a day did not close the popover")
        assertStillRaised(app, field: field, bar: bar, at: raised, after: "a day was picked")
        XCTAssertNotEqual(date.label, "Date", "The Date segment did not take the picked day")
        XCTAssertTrue(date.label.contains("10"), "The Date segment reads \"\(date.label)\", not the 10th")
        XCTAssertTrue(date.isSelected, "The picked day did not become the selected segment")
    }

    // MARK: - The frames

    /// A render harness, not a test: it produces `screenshots/composer-l3-layout/` and asserts only
    /// the targets a frame can measure. **Appearance and text size come from the SIMULATOR**
    /// (`xcrun simctl ui <udid> appearance …` / `content_size …`), because a launch argument never
    /// reached an accessibility size in `UndoCapsuleRenderUITests`. Frames are named by the layout
    /// the hierarchy SHOWS (the bar present or not), never by what the runner was told, and suffixed
    /// with `COMPOSER_RENDER_TAG` (passed as `TEST_RUNNER_COMPOSER_RENDER_TAG`).
    @MainActor
    func testRenderTheComposer() throws {
        try UITestEmulator.skipUnlessRunning()
        // Measure everything, then fail: one short target must not cost the rest of the frames.
        continueAfterFailure = true
        let tag = ProcessInfo.processInfo.environment["COMPOSER_RENDER_TAG"] ?? "X"
        let app = try UITestSession.launchSignedIn(label: "d2render")
        let field = try openTheComposer(app)
        XCTAssertTrue(app.buttons["taskCreateSubmitButton"].waitForExistence(timeout: UITestSession.timeout))
        let bar = app.otherElements["taskComposerKeyboardBar"]
        let layout = bar.exists ? "L3" : "L1-stacked"
        measureTheTargets(app, layout: layout)
        attach(app, named: "\(layout)-down-\(tag)")

        field.tap()
        field.typeText("Call the dentist")
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: UITestSession.timeout), "No keyboard came up")
        print("MEASURE \(layout)-\(tag) keyboard=\(app.keyboards.element.frame) bar=\(bar.exists ? bar.frame : .zero)")
        attach(app, named: "\(layout)-up-\(tag)")
        guard bar.exists else { return }

        let none = app.buttons["None"]
        if UITestSession.tap(app.buttons["taskCreateLifeAreaPicker"], untilExists: none) {
            attach(app, named: "\(layout)-area-open-\(tag)")
            _ = UITestSession.tap(none, untilGone: none)
        }
        let hour = app.buttons["1 hr"]
        if UITestSession.tap(app.buttons["taskCreateTimeMenu"], untilExists: hour) {
            attach(app, named: "\(layout)-time-open-\(tag)")
            _ = UITestSession.tap(app.buttons["15 min"], untilGone: hour)
        }
        let date = app.buttons["taskCreateDue-Date"]
        attach(app, named: "\(layout)-date-before-\(tag)")
        let picker = app.datePickers["taskCreateDueDatePicker"]
        if UITestSession.tap(date, untilExists: picker) {
            print("MEASURE \(layout)-\(tag) popover=\(picker.frame) keyboard=\(app.keyboards.element.frame)")
            attach(app, named: "\(layout)-date-popover-\(tag)")
            pickTheTenthOfNextMonth(in: picker)
            _ = waitUntilGone(picker)
            print("MEASURE \(layout)-\(tag) dateSegment=\"\(date.label)\" selected=\(date.isSelected)")
            attach(app, named: "\(layout)-date-after-\(tag)")
        }
    }

    /// Round 7's targets, read off the accessibility tree the way board `62` measured them. Half a
    /// point of slack: SwiftUI lands on 47.99999999999994, which IS 48 on screen.
    @MainActor
    private func measureTheTargets(_ app: XCUIApplication, layout: String) {
        let close = app.buttons["taskCreateCloseButton"]
        print("MEASURE \(layout) close=\(close.frame)")
        XCTAssertGreaterThanOrEqual(close.frame.height, 47.5, "Close is \(close.frame.size), round 7 says 48 x 48")
        XCTAssertGreaterThanOrEqual(close.frame.width, 47.5, "Close is \(close.frame.size), round 7 says 48 x 48")
        for title in ["Not yet", "Today", "Tomorrow", "Date"] {
            let segment = app.buttons["taskCreateDue-\(title)"]
            print("MEASURE \(layout) segment[\(title)]=\(segment.frame)")
            XCTAssertGreaterThanOrEqual(
                segment.frame.height, 47.5, "The \(title) segment is \(segment.frame.height)pt tall"
            )
        }
        for id in ["taskCreateLifeAreaPicker", "taskCreateTimeMenu"] {
            let tile = app.buttons[id]
            print("MEASURE \(layout) \(id)=\(tile.frame)")
            XCTAssertGreaterThanOrEqual(tile.frame.height, 55.5, "\(id) is \(tile.frame.height)pt tall, the tile is 56")
        }
        let add = app.buttons["taskCreateSubmitButton"]
        print("MEASURE \(layout) add=\(add.frame)")
        XCTAssertGreaterThanOrEqual(add.frame.height, 47.5, "Add is \(add.frame.height)pt tall")
    }

    // MARK: - Plumbing

    @MainActor
    private func openTheComposer(_ app: XCUIApplication) throws -> XCUIElement {
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )
        UITestSession.openTab("Tasks", in: app)
        let field = app.textFields["taskCreateTitleField"]
        // `continueAfterFailure = false`, so a composer that never opened ends the test here.
        XCTAssertTrue(
            UITestSession.tap(app.buttons["taskCreateButton"], untilExists: field),
            "The task composer never opened from Tasks"
        )
        return field
    }

    /// The keyboard lives in its own window, so it stays queryable while a menu makes the app modal.
    @MainActor
    private func assertTheKeyboardIsUp(_ app: XCUIApplication, while moment: String) {
        attach(app, named: "keyboard-while-\(moment)")
        XCTAssertTrue(app.keyboards.element.exists, "The keyboard went down while \(moment)")
    }

    @MainActor
    private func assertStillRaised(
        _ app: XCUIApplication, field: XCUIElement, bar: XCUIElement, at raised: CGRect, after moment: String
    ) {
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 2), "The keyboard is down after \(moment)")
        XCTAssertEqual(
            field.value(forKey: "hasKeyboardFocus") as? Bool, true,
            "The title lost focus after \(moment)"
        )
        XCTAssertEqual(bar.frame.minY, raised.minY, accuracy: 1, "The bar moved after \(moment)")
    }

    /// The 10th of NEXT month, whatever today is — a day the Today and Tomorrow segments can never
    /// mean, reached the same way every run.
    @MainActor
    private func pickTheTenthOfNextMonth(in picker: XCUIElement) {
        let next = picker.buttons["Next Month"]
        XCTAssertTrue(next.waitForExistence(timeout: UITestSession.timeout), "The calendar has no Next Month control")
        next.tap()
        let tenth = picker.buttons.matching(NSPredicate(format: "label MATCHES %@", ".*\\b10\\b.*")).firstMatch
        XCTAssertTrue(tenth.waitForExistence(timeout: UITestSession.timeout), "No 10th in next month's grid")
        tenth.tap()
    }

    private func waitUntilGone(_ element: XCUIElement) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [gone], timeout: UITestSession.timeout) == .completed
    }

    @MainActor
    private func attach(_ app: XCUIApplication, named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
