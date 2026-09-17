//
//  FanOverAwayCardUITests.swift
//  ADHD LifeOSUITests
//
//  F-FanCardsFade's journey — the regression camera for the finding E photographed on 2026-09-17
//  (`screenshots/landscape-fab-overlap/12`): with the away card up, opening the capture fan drew
//  the card crisp above the fan's scrim and, in portrait, the LINK and TASK tiles were behind it
//  and could not be tapped. E's call: *"Fade the cards out while the fan's open."*
//
//  So the journey holds the away card, opens the fan, and asserts the things that matter: the
//  tiles that were buried are hittable; the card's own button is NOT (faded out and no longer
//  taking touches); and the disc — now the fan's × — is at its RESTING corner, clear of every
//  tile. Then it dismisses and asserts the card is back and the disc is back above it. Portrait,
//  where `app.screenshot()` is truthful. The away card is raised the way
//  `LandscapeAwayCardUITests` raises it (`UITestUserDefaultsSeeds.swift`).
//
//  **REVERSED 2026-09-17 by `F-FanXAtRest`.** This journey used to assert that the disc did NOT
//  move when the fan opened — `F-FanCardsFade`'s "the × stays where the + was". E's GIF
//  (`screenshots/landscape-fab-overlap/21`) showed what that costs: any card pushes the × up in
//  portrait, the tiles are placed from the resting corner, and the × lands on one. With this card
//  up it sat between PHOTO and LINK. E called it a bug and chose shape B, *"× drops to its
//  corner"*, so the assertion is now the opposite one.
//

import XCTest

final class FanOverAwayCardUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOpeningTheFanFadesTheAwayCardAndFreesTheTilesBehindIt() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "fanaway")
        let app = try UITestSession.launchSignedIn(
            as: account,
            launchArguments: UITestSession.unacknowledgedCompletionLaunchArguments(
                taskTitle: "celebration sound testing"
            )
        )

        let card = app.descendants(matching: .any)["offlineSprintSummaryCard"]
        let gotIt = app.buttons["offlineSprintSummaryDismissButton"]
        let disc = app.buttons["quickCaptureButton"]
        XCTAssertTrue(
            card.waitForExistence(timeout: UITestSession.timeout),
            "The away card never appeared, so the premise of the finding is missing."
        )
        XCTAssertTrue(disc.waitForExistence(timeout: UITestSession.timeout), "No capture disc")
        sweepSystemPrompts(app, wait: 5)
        settle()
        XCTAssertTrue(waitUntilHittable(gotIt, in: app), "Fan closed: Got it is not tappable — the control failed")
        let discBeforeOpening = disc.frame
        // Read while the card is plainly on screen: its bottom is the column's bottom line, which
        // is the disc's resting line (the overlay pads the whole column up by the same lift).
        let cardBeforeOpening = card.frame
        attach(app, "00-portrait-away-card-fan-closed")

        // Open the fan. The tiles exist only while it is open, so TASK's arrival is the landmark.
        let task = app.buttons["captureFan-task"]
        let link = app.buttons["captureFan-link"]
        XCTAssertTrue(UITestSession.tap(disc, untilExists: task), "The fan did not open")
        settle()
        attach(app, "01-portrait-fan-open-over-away-card")
        print("[FAN-AWAY] disc before=\(discBeforeOpening) after=\(disc.frame)"
            + " task=\(task.frame) link=\(link.frame) card=\(card.frame)")

        // The finding, as E met it: TASK and LINK sit inside the card's frame and were unreachable.
        XCTAssertTrue(
            card.frame.contains(CGPoint(x: task.frame.midX, y: task.frame.midY)),
            "TASK is not inside the card's frame, so this journey is not exercising the overlap E found."
        )
        XCTAssertTrue(waitUntilHittable(task, in: app), "Fan open: the TASK tile behind the away card cannot be tapped")
        XCTAssertTrue(waitUntilHittable(link, in: app), "Fan open: the LINK tile behind the away card cannot be tapped")
        // The card is faded out AND out of the hit-test — its button must not take the tap instead.
        XCTAssertFalse(gotIt.isHittable, "Fan open: the away card's Got it still takes touches")
        assertTheXIsAtRestAndClearOfEveryTile(disc, columnBottom: cardBeforeOpening.maxY, in: app)

        // Dismiss by tapping the × (the disc itself); the card comes back, and so does the push.
        XCTAssertTrue(UITestSession.tap(disc, untilGone: task), "The fan did not close")
        settle()
        attach(app, "02-portrait-fan-closed-card-back")
        XCTAssertTrue(waitUntilHittable(gotIt, in: app), "Fan closed again: Got it did not come back")
        XCTAssertEqual(
            disc.frame.midY, discBeforeOpening.midY, accuracy: 1,
            "Fan closed: the disc did not return above the card"
        )
    }

    // MARK: - The × (F-FanXAtRest)

    /// E's shape B: the × is clear of every tile, because it is at its resting corner — on the
    /// column's bottom line. A tile is 62pt and the disc 60pt, so centres under 61pt apart overlap.
    /// On the unfixed tree the × is pushed up over the tiles and the collision is where the journey
    /// fails (it sat 35pt from PHOTO); the collision is asserted FIRST so that is what the red says.
    @MainActor
    private func assertTheXIsAtRestAndClearOfEveryTile(
        _ disc: XCUIElement, columnBottom: CGFloat, in app: XCUIApplication
    ) {
        let xCentre = CGPoint(x: disc.frame.midX, y: disc.frame.midY)
        for kind in ["note", "voice", "photo", "link", "task"] {
            let tile = app.buttons["captureFan-\(kind)"].frame
            let distance = hypot(tile.midX - xCentre.x, tile.midY - xCentre.y)
            XCTAssertGreaterThanOrEqual(
                distance, 61,
                "Fan open: the × (centre \(xCentre)) sits on the \(kind.uppercased()) tile, \(distance)pt apart"
            )
        }
        XCTAssertEqual(
            disc.frame.maxY, columnBottom, accuracy: 1,
            "Fan open: the × is not on the column's bottom line, so a card is still pushing it up"
        )
    }

    // MARK: - Hittability

    @MainActor
    private func waitUntilHittable(_ element: XCUIElement, in app: XCUIApplication, seconds: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(seconds)
        repeat {
            UITestSession.dismissSystemPasswordPromptIfPresent()
            if element.isHittable { return true }
            Thread.sleep(forTimeInterval: 0.5)
        } while Date() < deadline
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "hierarchy-when-\(element.identifier)-was-not-hittable"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        return false
    }

    // MARK: - Capture

    private func settle() {
        Thread.sleep(forTimeInterval: 1.0)
    }

    @MainActor
    private func sweepSystemPrompts(_ app: XCUIApplication, wait: TimeInterval) {
        UITestSession.dismissSystemAlertIfPresent(timeout: wait)
        let passwordSheet = app.sheets.matching(NSPredicate(format: "label CONTAINS[c] 'password'")).firstMatch
        _ = passwordSheet.waitForExistence(timeout: wait)
        UITestSession.dismissSystemPasswordPromptIfPresent()
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        sweepSystemPrompts(app, wait: 0.5)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
