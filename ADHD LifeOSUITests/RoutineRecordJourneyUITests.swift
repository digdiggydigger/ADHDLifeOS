//
//  RoutineRecordJourneyUITests.swift
//  ADHD LifeOSUITests
//
//  The routine record end to end (F-RoutineRecord-2-Surfaces), driven on the simulator
//  against the Firebase emulator — which loads the repo's OWN rules, so this is also the
//  proof that `routine_runs` is writable through them.
//
//  Unit tests pin every word and rule; this walks what a person walks: fire a crossing, take
//  the routine, finish it, and then READ what the app now says about it — the Journal's
//  started and finished rows, the Tools row's last-run line, and the offer nobody took, which
//  must stay hidden until the "All activity" switch reveals it.
//

import XCTest

final class RoutineRecordJourneyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - The seeded places

    private let gymId = UUID()
    private let officeId = UUID()

    /// A place whose ARRIVAL clears the routine threshold. The gym carries one silent step
    /// too, so its finished row can say "1 of 4 done" after the three tap-steps are skipped.
    private func seedPlace(uid: String, id: UUID, name: String, emoji: String, withJournalStep: Bool) throws {
        let action = { (fields: [String: Any]) -> [String: Any] in
            var all: [String: Any] = [
                "id": UITestEmulator.string(UUID().uuidString),
                "direction": UITestEmulator.string("arrival")
            ]
            fields.forEach { all[$0.key] = $0.value }
            return UITestEmulator.map(all)
        }
        var actions: [[String: Any]] = []
        if withJournalStep {
            actions.append(action([
                "kind": UITestEmulator.string("journal_line"),
                "journal_body": UITestEmulator.string("Leg day")
            ]))
        }
        actions += [
            action([
                "kind": UITestEmulator.string("open_app"),
                "scheme": UITestEmulator.string("snapchat"),
                "display_name": UITestEmulator.string("Snapchat")
            ]),
            action([
                "kind": UITestEmulator.string("open_app"),
                "scheme": UITestEmulator.string("gymapp"),
                "display_name": UITestEmulator.string("Gym")
            ]),
            action([
                "kind": UITestEmulator.string("open_app"),
                "scheme": UITestEmulator.string("spotify"),
                "display_name": UITestEmulator.string("Spotify")
            ])
        ]
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/places/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "name": UITestEmulator.string(name),
                "latitude": UITestEmulator.double(51.5152),
                "longitude": UITestEmulator.double(-0.1418),
                "radius_metres": UITestEmulator.double(150),
                "emoji": UITestEmulator.string(emoji),
                "created_at": UITestEmulator.timestamp(Date()),
                "nudge_on_arrival": UITestEmulator.bool(true),
                "nudge_on_departure": UITestEmulator.bool(true),
                "actions": UITestEmulator.array(actions)
            ]
        )
    }

    // MARK: - The journey

    @MainActor
    func testARoutineLeavesItsRecordOnTheJournalAndTools_andAnOfferHidesBehindTheSwitch() throws {
        try UITestEmulator.skipUnlessRunning()

        let account = try UITestSession.createAccount(label: "routine-record")
        try seedPlace(uid: account.uid, id: gymId, name: "Gym", emoji: "🏋️", withJournalStep: true)
        try seedPlace(uid: account.uid, id: officeId, name: "Office", emoji: "💼", withJournalStep: false)
        let app = try UITestSession.launchSignedIn(as: account)
        XCTAssertTrue(
            app.buttons["quickCaptureButton"].waitForExistence(timeout: UITestSession.timeout),
            "The signed-in tabs never appeared"
        )

        // 1. Take the gym routine and finish it — the record's started and ended moments.
        takeAndFinishTheGymRoutine(app)

        // 2. Offer the office routine and take nothing — the record's offered-only moment.
        fireCrossing(app, placeId: officeId, named: "Simulate arrival")
        UITestSession.dismissSystemAlertIfPresent()

        // 3. The Journal, switch OFF (E's device-walk call): the crossings alone — no routine
        //    row of any kind, started and finished included.
        openTab("Journal", in: app)
        let started = routineRow("started", in: app)
        let ended = routineRow("ended", in: app)
        let offered = routineRow("offered", in: app)
        XCTAssertTrue(
            app.staticTexts["Arrived at Gym 🏋️"].waitForExistence(timeout: UITestSession.timeout),
            "The Journal never showed the arrival row"
        )
        XCTAssertFalse(started.exists, "switch off: no started row")
        XCTAssertFalse(ended.exists, "switch off: no finished row")
        XCTAssertFalse(offered.exists, "switch off: no offered row")
        attach(app, "1-journal-switch-off")

        // 4. The switch reveals the whole story: E's two rows for the taken routine, and the
        //    untaken offer muted and honest.
        let allActivity = app.buttons["journalAllActivitySwitch"]
        XCTAssertTrue(
            UITestSession.tap(allActivity, untilExists: started),
            "The All activity switch never revealed the started row"
        )
        XCTAssertTrue(started.label.contains("Started routine at Gym 🏋️"), started.label)
        XCTAssertTrue(ended.exists, "The finished row is missing beside the started one")
        XCTAssertTrue(ended.label.contains("Finished routine at Gym 🏋️ · 1 of 4 done"), ended.label)
        XCTAssertTrue(offered.exists, "The offered row is missing with the switch on")
        XCTAssertTrue(offered.label.contains("Routine offered at Office 💼 · not opened"), offered.label)
        attach(app, "2-journal-switch-on")

        // 5. Tools remembers the last run on the routine's own row. The tab kept its stack, so
        //    it is still inside Places from the test-fire; the Routines section is on the root.
        openTab("Tools", in: app)
        let gymRow = app.descendants(matching: .any)
            .matching(identifier: "toolsRoutineRow-\(gymId.uuidString)-arrival").firstMatch
        if !gymRow.waitForExistence(timeout: 2) {
            let back = app.navigationBars.buttons.firstMatch
            if back.waitForExistence(timeout: UITestSession.timeout) {
                back.tap()
            }
        }
        XCTAssertTrue(
            scrollUntilFound(gymRow, in: app),
            "The Tools Routines row for the gym never appeared"
        )
        XCTAssertTrue(gymRow.label.contains("last run today, 1 of 4"), gymRow.label)
        attach(app, "3-tools-last-run")
    }

    // MARK: - Helpers

    /// Fires the gym arrival, opens its banner, skips every tap-step and closes — the run ends
    /// `completed` with "1 of 4 done" (the auto step), which is what the Journal row must say.
    @MainActor
    private func takeAndFinishTheGymRoutine(_ app: XCUIApplication) {
        fireCrossing(app, placeId: gymId, named: "Simulate arrival")
        UITestSession.dismissSystemAlertIfPresent()
        fireCrossing(app, placeId: gymId, named: "Open the routine notification")
        XCTAssertTrue(
            app.buttons["Open Snapchat"].waitForExistence(timeout: UITestSession.timeout),
            "The tapped routine notification never presented the routine screen"
        )
        let skip = app.buttons["Skip this step"]
        for _ in 0..<3 where skip.exists {
            skip.tap()
            _ = app.buttons["Open Spotify"].waitForExistence(timeout: 2)
        }
        XCTAssertFalse(skip.exists, "every step should be resolved")
        XCTAssertTrue(
            UITestSession.tap(app.buttons["Close"], untilGone: named("routineProgress", app)),
            "Close did not dismiss the routine screen"
        )
    }

    @MainActor
    private func routineRow(_ kind: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "journalRoutineRow-\(kind)-"))
            .firstMatch
    }

    /// Taps a tab until it is actually SELECTED — `RoutineJourneyUITests`' helper, verbatim.
    @MainActor
    private func openTab(_ name: String, in app: XCUIApplication) {
        let tab = UITestSession.tabButton(name, in: app)
        XCTAssertTrue(
            tab.waitForExistence(timeout: UITestSession.timeout),
            "The \(name) tab is missing from the tab bar"
        )
        for attempt in 1...4 {
            if tab.isSelected { return }
            if attempt == 1 {
                tab.tap()
            } else {
                tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "isSelected == true"), object: tab
            )
            if XCTWaiter().wait(for: [selected], timeout: 4) == .completed { return }
        }
        XCTAssertTrue(tab.isSelected, "The \(name) tab never became selected")
    }

    @MainActor
    private func fireCrossing(_ app: XCUIApplication, placeId: UUID, named button: String) {
        openTab("Tools", in: app)
        let fire = app.buttons["placeTestFireButton-\(placeId)"]
        if !fire.exists {
            let placesDoor = app.buttons["toolsCard.places"]
            XCTAssertTrue(
                placesDoor.waitForExistence(timeout: UITestSession.timeout),
                "The Tools tab never showed the Places door"
            )
            // The tab-root not-hittable defect (register B3): a settled, ON-screen card that
            // XCUITest still calls not hittable. `element.tap()` on such a card FAILS THE TEST
            // outright, so the check has to come first — a coordinate tap bypasses hittability
            // resolution entirely, the same fallback `openTab` uses from its second attempt.
            if placesDoor.isHittable {
                _ = UITestSession.tap(placesDoor, untilExists: fire)
            } else {
                placesDoor.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            XCTAssertTrue(
                fire.waitForExistence(timeout: UITestSession.timeout),
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

    /// The Journal and Tools are lazy stacks: a row below the fold does not exist yet.
    @MainActor
    private func scrollUntilFound(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        if element.waitForExistence(timeout: UITestSession.timeout) { return true }
        for _ in 0..<8 {
            app.swipeUp()
            if element.waitForExistence(timeout: 2) { return true }
        }
        return element.exists
    }

    @MainActor
    private func named(_ identifier: String, _ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
