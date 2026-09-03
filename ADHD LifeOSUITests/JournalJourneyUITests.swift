//
//  JournalJourneyUITests.swift
//  ADHD LifeOSUITests
//
//  The Journal tab's signed-in journey. Its own class rather than a sixth method on
//  `SignedInJourneyUITests`, which was already at its 400-line ceiling — and because this one
//  asserts LAYOUT, which none of the others do.
//

import XCTest

final class JournalJourneyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        try UITestEmulator.skipUnlessRunning()
    }

    /// **Writing a journal entry puts it on the timeline, with what it was written with in the
    /// right PLACE.**
    ///
    /// This journey exists because of a defect a unit test structurally cannot see (E's device
    /// shot, 2026-08-29): `logRow` had the context line, the mood and the energy in one `HStack`,
    /// which reserved a trailing column — wrapping the context, and floating the pair at neither
    /// line's height. Nothing about that is reachable from a `XCTestCase` over pure types, and the
    /// Journal tab had no journey at all, so it shipped.
    ///
    /// So this asserts GEOMETRY, not just existence. `existence` would have passed on the broken
    /// build — the badge was on screen the whole time, just in the wrong place.
    @MainActor
    func testJournal_writtenEntryShowsItsMoodBelowTheContextLine() throws {
        let app = try UITestSession.launchSignedIn(label: "journal")
        let body = writeAJournalEntry(in: app)

        XCTAssertTrue(
            app.staticTexts[body].waitForExistence(timeout: UITestSession.timeout),
            "The entry that was just written is not on the timeline"
        )

        // The timeline is newest-first, so the row just written is the first of each.
        // `descendants(matching: .any)` for the badge, deliberately. `.accessibilityElement(children:
        // .combine)` publishes it as a single element whose TYPE is not guaranteed — querying
        // `otherElements` found nothing even though it was plainly on screen.
        let context = app.staticTexts.matching(identifier: "journalRowContextLine").firstMatch
        let badge = app.descendants(matching: .any).matching(identifier: "energyMoodBadge").firstMatch
        XCTAssertTrue(context.waitForExistence(timeout: UITestSession.timeout), "No context line")
        XCTAssertTrue(badge.waitForExistence(timeout: UITestSession.timeout), "No energy/mood badge")

        // 1. The badge sits BELOW the context line, not beside it. This is the assertion that
        //    fails on the shipped defect: there the badge shared the context's row.
        XCTAssertGreaterThanOrEqual(
            badge.frame.minY, context.frame.maxY - 2,
            "The mood/energy badge overlaps the context line's row — it is beside it, not below it"
        )
        // 2. And it starts at the same left edge, rather than being pushed out to the trailing side.
        XCTAssertEqual(
            badge.frame.minX, context.frame.minX, accuracy: 2,
            "The badge is not left-aligned with the context line"
        )
        // 3. The energy reads `EnergyLevel.chipLabel` — "medium energy", the composer's default —
        //    and not the bare `rawValue` the row used to render.
        XCTAssertTrue(
            badge.label.contains("energy"),
            "The badge reads \(badge.label) — expected the chipLabel wording, e.g. \"medium energy\""
        )
    }

    /// Writes one journal entry and returns its body, leaving the app back on the timeline.
    ///
    /// Split out so neither half exceeds the 50-line function budget, and because the "did we
    /// actually get back?" checks belong with the writing rather than with the layout assertions
    /// they protect.
    @MainActor
    private func writeAJournalEntry(in app: XCUIApplication) -> String {

        // Retried taps throughout. A tab tap taken while Today is still settling is a silent
        // no-op, and this journey failed once with "No compose button" for precisely that reason —
        // a true statement about a screen it had never actually left.
        let journalTab = UITestSession.tabButton("Journal", in: app)
        let compose = app.buttons["journalComposeButton"]
        XCTAssertTrue(
            UITestSession.tap(journalTab, untilExists: compose),
            "The Journal tab never presented its compose control"
        )
        XCTAssertTrue(
            UITestSession.tap(compose, untilExists: app.buttons["logComposerType-journal"]),
            "The composer never opened"
        )

        // Journal, not Log: a Log carries neither energy nor mood, so it would exercise the one
        // case this row leaves alone. The journal composer pre-selects both.
        app.buttons["logComposerType-journal"].tap()

        // A life area lengthens the context line, which is what made it wrap in the first place.
        let areaChips = app.buttons.matching(identifier: "composerAreaChip")
        if areaChips.count > 0 {
            areaChips.element(boundBy: 0).tap()
        }

        let body = "Journey entry \(UUID().uuidString.prefix(6)) — long enough to need a second line"
        UITestSession.focusAndType(app.textFields["logComposerBodyField"], text: body, in: app)

        let submit = app.buttons["logComposerSubmitButton"]
        XCTAssertTrue(submit.waitForExistence(timeout: UITestSession.timeout))
        XCTAssertTrue(submit.isEnabled, "Save was disabled, so the body never took the text")
        submit.tap()

        // Prove we LEFT the composer before asserting anything about the timeline. Without this the
        // queries below can match the composer's own controls and report success from the wrong
        // screen — which is exactly how the throwaway camera that preceded this test lied.
        let composerGone = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: app.buttons["logComposerSubmitButton"]
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [composerGone], timeout: UITestSession.timeout), .completed,
            "The composer never dismissed"
        )
        XCTAssertTrue(
            compose.waitForExistence(timeout: UITestSession.timeout),
            "Never got back to the Journal timeline"
        )
        return body
    }
}
