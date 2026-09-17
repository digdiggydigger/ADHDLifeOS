//
//  SprintBarFurnitureUITests.swift
//  ADHD LifeOSUITests
//
//  The bottom furniture with a SPRINT up — E's 2026-09-17 device frames were all taken with one
//  (`screenshots/landscape-fab-overlap/16–21`). The sprint is restored at launch from a seeded,
//  PAUSED `focus.sprint.running` (`UITestUserDefaultsSeeds.swift`), so nothing finishes while the
//  journey measures.
//
//  `F-FanXAtRest`: on Tasks the search row shares the disc's row, so when the × drops to its
//  corner the search row must ride down WITH it — the spec's "look at it on Tasks with a sprint
//  running before calling the block done", held as an assertion rather than a glance. Portrait,
//  where `app.screenshot()` is truthful.
//

import XCTest

final class SprintBarFurnitureUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// E's frame 19 on the Tasks tab: a collapsed sprint bar pushes the row up in portrait. With
    /// the fan open the × is clear of every tile, the search row stays centred on it, and both
    /// have dropped by at least the bar's height. Closing the fan puts them back.
    @MainActor
    func testOnTasksTheSearchRowRidesDownWithTheXWhileTheFanIsOpen() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "sprinttasks")
        let app = try UITestSession.launchSignedIn(
            as: account,
            launchArguments: UITestSession.pausedSprintLaunchArguments(
                taskTitle: "celebration sound testing", collapsed: true
            )
        )
        let bar = app.descendants(matching: .any)["focusTimerBar"]
        let disc = app.buttons["quickCaptureButton"]
        XCTAssertTrue(
            bar.waitForExistence(timeout: UITestSession.timeout),
            "The seeded sprint's timer bar never appeared. Check the seed against `PersistedFocusSprint`."
        )
        sweepSystemPrompts(app, wait: 5)
        UITestSession.openTab("Tasks", in: app)
        let row = app.descendants(matching: .any)["appSearchRow"]
        XCTAssertTrue(row.waitForExistence(timeout: UITestSession.timeout), "No search row on Tasks")
        XCTAssertTrue(disc.waitForExistence(timeout: UITestSession.timeout), "No capture disc")
        settle()
        attach(app, "00-tasks-collapsed-bar-fan-closed")
        let rowBefore = row.frame
        let discBefore = disc.frame
        print("[SPRINT-TASKS] closed row=\(rowBefore) disc=\(discBefore) bar=\(bar.frame)")
        // The control: the row and the disc share one row, so "rides with it" can mean something.
        XCTAssertEqual(
            rowBefore.midY, discBefore.midY, accuracy: 1, "Fan closed: the search row is not on the disc's row"
        )

        let task = app.buttons["captureFan-task"]
        XCTAssertTrue(UITestSession.tap(disc, untilExists: task), "The fan did not open")
        settle()
        attach(app, "01-tasks-fan-open-row-and-x-at-rest")
        print("[SPRINT-TASKS] open row=\(row.frame) disc=\(disc.frame) task=\(task.frame)")

        let xCentre = CGPoint(x: disc.frame.midX, y: disc.frame.midY)
        for kind in ["note", "voice", "photo", "link", "task"] {
            let tile = app.buttons["captureFan-\(kind)"].frame
            let distance = hypot(tile.midX - xCentre.x, tile.midY - xCentre.y)
            XCTAssertGreaterThanOrEqual(
                distance, 61,
                "Tasks, fan open: the × (centre \(xCentre)) sits on the \(kind.uppercased()) tile, \(distance)pt apart"
            )
        }
        XCTAssertEqual(row.frame.midY, disc.frame.midY, accuracy: 1, "Fan open: the search row did not ride with the ×")
        XCTAssertGreaterThanOrEqual(
            disc.frame.midY - discBefore.midY, 60,
            "Fan open: the × did not drop by the collapsed bar's height"
        )

        XCTAssertTrue(UITestSession.tap(disc, untilGone: task), "The fan did not close")
        settle()
        XCTAssertEqual(row.frame.midY, rowBefore.midY, accuracy: 1, "Fan closed: the search row did not return")
        XCTAssertEqual(disc.frame.midY, discBefore.midY, accuracy: 1, "Fan closed: the disc did not return")
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
