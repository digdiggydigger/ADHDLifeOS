//
//  ComposerKeyboardBarUITests.swift
//  ADHD LifeOSUITests
//
//  `F-D2-ComposerKeyboardLayout`. Two things only a running app can say about round 7b's L3:
//
//  1. **The pin — and what it pins changed on E's word.** Findings §L asked for a test that
//     *"Opening Area, Time or the date picker must NOT dismiss the keyboard"*, and called the claim
//     UNVERIFIED. Its first run verified it FALSE: on iOS 27 the SwiftUI menu, a UIKit menu tried in
//     its place and the popover all put the keyboard down, and it does not come back. E chose, on
//     2026-09-24, **"Let it settle"**: the bar rides the keyboard while you type, the first choice
//     lets it rest at the bottom, and it stays there. So this pins what E chose: after every choice
//     the bar is at ONE of its two resting places, the one the keyboard says, and it does not move.
//  2. **The frames** for `screenshots/composer-l3-layout/`, keyboard up and down, the Date segment
//     before and after a pick, and the stacked form at an accessibility size.
//
//  **While a Menu is open, the app beneath it leaves the accessibility tree** — the text field and
//  the bar cannot be queried until the menu closes. So the pin reads the bar once the choice has
//  closed, and the frames record what the queries cannot.
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
    func testAChoiceLetsTheBarSettleAndItStaysSettled() throws {
        try UITestEmulator.skipUnlessRunning()
        // Every choice is checked on its own; the verdict comes after all of them.
        continueAfterFailure = true
        let app = try UITestSession.launchSignedIn(label: "d2keyboard")
        let field = try openTheComposer(app)
        let bar = app.otherElements["taskComposerKeyboardBar"]
        guard bar.waitForExistence(timeout: UITestSession.timeout) else {
            return XCTFail("The composer has no keyboard bar")
        }
        let settled = bar.frame
        focus(field)
        field.typeText("Rides the keyboard")
        guard app.keyboards.element.waitForExistence(timeout: UITestSession.timeout) else {
            return XCTFail("No keyboard at all came up")
        }
        // A simulator in hardware-keyboard mode keeps its keyboard below the screen (y 919 on the 18.0
        // sim), so there is nothing for the bar to ride and nothing to settle from. That is the
        // environment, not the app: skip rather than fail, and say so.
        guard keyboardIsOnScreen(app) else {
            throw XCTSkip("No SOFTWARE keyboard on this simulator (\(app.keyboards.element.frame)) — nothing to ride")
        }
        let places = RestingPlaces(app: app, bar: bar, settled: settled.minY, raised: bar.frame.minY)
        print("MEASURE pin settled=\(settled) raised=\(bar.frame) keys=\(app.keyboards.element.frame)")
        XCTAssertLessThan(
            places.raised, places.settled - 100,
            "The bar did not ride the keyboard: raised at \(places.raised), settled at \(places.settled)"
        )

        choose(app.buttons["taskCreateLifeAreaPicker"], showing: app.buttons["None"], shot: "pin-area-open")
        assertAtRest(places, after: "the Area menu")
        choose(app.buttons["taskCreateTimeMenu"], showing: app.buttons["1 hr"], picking: app.buttons["30 min"])
        assertAtRest(places, after: "the Time menu")
        let date = pickADay(app)
        assertAtRest(places, after: "a day was picked")
        XCTAssertNotEqual(date.label, "Date", "The Date segment did not take the picked day")
        XCTAssertTrue(date.label.contains("10"), "The Date segment reads \"\(date.label)\", not the 10th")
        XCTAssertTrue(date.isSelected, "The picked day did not become the selected segment")
        XCTAssertEqual(field.value as? String, "Rides the keyboard", "A choice lost the typed title")

        // The way back to typing is one tap on the title, and the bar rides the keyboard again.
        focus(field)
        XCTAssertTrue(
            app.keyboards.element.waitForExistence(timeout: UITestSession.timeout), "The title raised no keyboard"
        )
        XCTAssertTrue(waitForBar(bar, at: places.raised), "The bar did not rise with the keyboard: \(bar.frame)")
    }

    /// Opens a menu, photographs it if asked, and closes it by picking a row (the menu's first
    /// row, "None" for Area, when `picking` is nil).
    @MainActor
    private func choose(
        _ control: XCUIElement, showing row: XCUIElement, picking: XCUIElement? = nil, shot: String? = nil
    ) {
        guard UITestSession.tap(control, untilExists: row) else {
            return XCTFail("\(control) opened no menu")
        }
        if let shot { attach(XCUIApplication(), named: shot) }
        let pick = picking ?? row
        _ = UITestSession.tap(pick, untilGone: row)
    }

    /// Opens the Date segment's popover, checks the calendar is whole and on screen, and picks the
    /// 10th of next month. Returns the segment, for the caller to read what it now says.
    @MainActor
    private func pickADay(_ app: XCUIApplication) -> XCUIElement {
        let date = app.buttons["taskCreateDue-Date"]
        XCTAssertEqual(date.label, "Date", "The Date segment does not read \"Date\" before a pick")
        let picker = app.datePickers["taskCreateDueDatePicker"]
        guard UITestSession.tap(date, untilExists: picker) else {
            XCTFail("Date opened no picker")
            return date
        }
        attach(app, named: "pin-date-popover")
        assertOnScreen(picker, in: app)
        pickTheTenthOfNextMonth(in: picker)
        XCTAssertTrue(waitUntilGone(picker), "Picking a day did not close the popover")
        return date
    }

    private struct RestingPlaces {
        let app: XCUIApplication
        let bar: XCUIElement
        let settled: CGFloat
        let raised: CGFloat
    }

    /// E's "Let it settle": once a choice has closed, the bar rests where the KEYBOARD says (down:
    /// the bottom; up: above it) and STAYS there. Sampled twice, a second apart, because the failure
    /// this exists for is the bounce: a title re-focused behind the user's back would bring the
    /// keyboard, and the bar with it, back up after the choice.
    @MainActor
    private func assertAtRest(_ places: RestingPlaces, after moment: String) {
        let first = restingState(places)
        Thread.sleep(forTimeInterval: 1)
        let second = restingState(places)
        print("MEASURE pin after \(moment): keyboard=\(first.keyboard) barY=\(first.barY) then \(second.barY)")
        let expected = first.keyboard ? places.raised : places.settled
        XCTAssertEqual(first.barY, expected, accuracy: 1, "After \(moment) the bar is not at rest: \(first.barY)")
        XCTAssertEqual(first.keyboard, second.keyboard, "After \(moment) the keyboard came and went")
        XCTAssertEqual(first.barY, second.barY, accuracy: 1, "After \(moment) the bar moved on its own")
    }

    @MainActor
    private func restingState(_ places: RestingPlaces) -> (keyboard: Bool, barY: CGFloat) {
        // Give the settle its animation before reading where the bar ended up.
        _ = waitForBar(places.bar, at: places.settled, timeout: 2)
        let keyboard = places.app.keyboards.element.exists
            && places.app.keyboards.element.frame.minY < places.app.frame.maxY
        return (keyboard, places.bar.frame.minY)
    }

    @MainActor
    private func waitForBar(
        _ bar: XCUIElement, at minY: CGFloat, timeout: TimeInterval = UITestSession.timeout
    ) -> Bool {
        let there = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in bar.exists && abs(bar.frame.minY - minY) <= 1 }, object: nil
        )
        return XCTWaiter().wait(for: [there], timeout: timeout) == .completed
    }

    /// The first build's popover drew a calendar about 60pt wide with Next Month past the screen's
    /// right edge. A frame is the only place that shows.
    @MainActor
    private func assertOnScreen(_ element: XCUIElement, in app: XCUIApplication) {
        let screen = app.windows.firstMatch.frame
        print("MEASURE popover=\(element.frame) screen=\(screen)")
        XCTAssertGreaterThanOrEqual(element.frame.width, 300, "The calendar is \(element.frame.width)pt wide")
        XCTAssertTrue(screen.contains(element.frame), "The calendar \(element.frame) runs off the screen \(screen)")
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

        focus(field)
        field.typeText("Call the dentist")
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: UITestSession.timeout), "No keyboard came up")
        print("MEASURE \(layout)-\(tag) keyboard=\(keyboardFrame(app)) bar=\(bar.exists ? bar.frame : .zero)")
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
            print("MEASURE \(layout)-\(tag) popover=\(picker.frame) keyboard=\(keyboardFrame(app))")
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
        // Measured, not asserted: a native bar item sizes itself (72 x 36 on 27.0 with a 48pt
        // label inside it), so round 7's 48 x 48 for Close is F-B1-TouchTargets' to reach.
        print("MEASURE \(layout) close=\(app.buttons["taskCreateCloseButton"].frame)")
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
        // By identifier, not by type: a vertical-axis `TextField` is a text FIELD to XCUITest on
        // 26+ and a text VIEW on iOS 18, so `app.textFields[…]` finds nothing on the floor.
        let field = app.descendants(matching: .any).matching(identifier: "taskCreateTitleField").firstMatch
        // `continueAfterFailure = false`, so a composer that never opened ends the test here.
        XCTAssertTrue(
            UITestSession.tap(app.buttons["taskCreateButton"], untilExists: field),
            "The task composer never opened from Tasks"
        )
        // The field exists from the sheet's first frame; Add is in the bar, which lays out last.
        _ = app.buttons["taskCreateSubmitButton"].waitForExistence(timeout: UITestSession.timeout)
        return field
    }

    /// A tap that lands while the sheet is still presenting leaves the field unfocused, and
    /// `typeText` then fails with "Neither element nor any descendant has keyboard focus" (the
    /// first probe run on 27.0). So tap until the field says it has focus.
    /// Focus is read two ways because either can lag: at xxxLarge `hasKeyboardFocus` stayed false for
    /// three seconds while the keyboard was already up and taking the typing (F-D2's XXXL re-render).
    @MainActor
    private func focus(_ field: XCUIElement) {
        let app = XCUIApplication()
        for _ in 1...3 {
            field.tap()
            let focused = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in
                    (field.value(forKey: "hasKeyboardFocus") as? Bool) == true || self.keyboardIsOnScreen(app)
                },
                object: nil
            )
            if XCTWaiter().wait(for: [focused], timeout: 3) == .completed { return }
        }
        XCTFail("The title field never took focus")
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

    @MainActor
    private func keyboardIsOnScreen(_ app: XCUIApplication) -> Bool {
        app.keyboards.element.exists && app.keyboards.element.frame.minY < app.windows.firstMatch.frame.maxY
    }

    /// A snapshot miss on a gone keyboard THROWS, whatever `continueAfterFailure` says — so every
    /// read that may meet no keyboard goes through here.
    @MainActor
    private func keyboardFrame(_ app: XCUIApplication) -> CGRect {
        app.keyboards.element.exists ? app.keyboards.element.frame : .zero
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
