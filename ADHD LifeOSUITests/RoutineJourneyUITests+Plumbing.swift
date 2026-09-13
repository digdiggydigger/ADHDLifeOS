//
//  RoutineJourneyUITests+Plumbing.swift
//  ADHD LifeOSUITests
//
//  `RoutineJourneyUITests`' mechanical helpers, split out in `F-CTACelebrations-6` when E's R1
//  grew the journey past the 400-line file bar: a Close no longer ends a routine, so the journey
//  had to gain a whole second visit — close, find the card still there, come back in, and only
//  then confirm.
//
//  **Nothing here is about routines.** Every one of these is a lesson about XCUITest that cost
//  this project a run: a tab tap swallowed mid-settle, a `LazyVStack` row that does not merely
//  fail to be hittable but does not EXIST, an element addressed by the wrong TYPE. They live
//  together so the journey file reads as the journey.
//

import XCTest

extension RoutineJourneyUITests {

    /// Taps a tab until it is actually SELECTED. A tab tap taken while the previous screen is
    /// still settling is a silent no-op — the lesson `SignedInJourneySupport.openTab` records,
    /// and the exact way this journey failed on its first run.
    @MainActor
    func openTab(_ name: String, in app: XCUIApplication) {
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
    func fireCrossing(_ app: XCUIApplication, named button: String) {
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
    func scrollUntilFound(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
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
    func waitForGone(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
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
    func named(_ identifier: String, _ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
