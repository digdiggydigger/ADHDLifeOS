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
//  `F-CollapsedBarLift`: the collapsed bar no longer drops onto the tab bar. E: *"Line up with the
//  Disc, But when there are multiple cards being displayed, then maintain the alignment"*, in
//  portrait AND landscape. The disc's RESTING line is read from the app itself — beside the cards
//  in landscape, and with the fan open in portrait (where `F-FanXAtRest` drops the × to it) — so
//  "lined up" is measured, not assumed. Landscape frames for evidence are taken host-side while a
//  pose is held (`[POSE]` lines carry the host clock), because `app.screenshot()` lies on a
//  rotated simulator (F-LandscapeFix).
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
        // `.firstMatch`: the identifier sits on a container, and its children inherit it.
        let bar = app.descendants(matching: .any).matching(identifier: "focusTimerBar").firstMatch
        let disc = app.buttons["quickCaptureButton"]
        XCTAssertTrue(
            bar.waitForExistence(timeout: UITestSession.timeout),
            "The seeded sprint's timer bar never appeared. Check the seed against `PersistedFocusSprint`."
        )
        sweepSystemPrompts(app, wait: 5)
        UITestSession.openTab("Tasks", in: app)
        let row = app.descendants(matching: .any).matching(identifier: "appSearchRow").firstMatch
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

    // MARK: - The collapsed bar's line (F-CollapsedBarLift)

    /// The bar alone: in portrait its bottom is the disc's resting line and it sits the stack's 8pt
    /// under the pushed-up disc; in landscape its bottom is the disc's bottom. On the unfixed tree
    /// the bar hangs 32pt lower in both — onto the tab bar.
    @MainActor
    func testTheCollapsedBarAloneSitsOnTheDiscsLineInBothOrientations() throws {
        try checkTheCollapsedBarsLine(withConfirmCard: false)
    }

    /// E's "maintain the alignment" with more than one card: with a Confirm card above it the
    /// collapsed bar still ends on the disc's line, and the Confirm card stays clear above it.
    @MainActor
    func testUnderAConfirmCardTheCollapsedBarKeepsTheAlignment() throws {
        try checkTheCollapsedBarsLine(withConfirmCard: true)
    }

    @MainActor
    private func checkTheCollapsedBarsLine(withConfirmCard: Bool) throws {
        // Every pose is worth seeing even when one assertion fails: the RED run is the "before"
        // evidence, so it must reach the landscape frame too.
        continueAfterFailure = true
        let app = try launchWithCollapsedSprint(withConfirmCard: withConfirmCard)
        let disc = app.buttons["quickCaptureButton"]
        let pose = withConfirmCard ? "confirm" : "alone"

        // Portrait. The resting line is where the × drops to with the fan open.
        let bar = collapsedCard(in: app)
        let discPushed = disc.frame
        let card = withConfirmCard ? confirmButton(in: app).frame : nil
        attach(app, "\(pose)-portrait")
        holdPose("\(pose)-portrait")
        let task = app.buttons["captureFan-task"]
        XCTAssertTrue(UITestSession.tap(disc, untilExists: task), "The fan did not open")
        settle()
        let restingLine = disc.frame.maxY
        XCTAssertTrue(UITestSession.tap(disc, untilGone: task), "The fan did not close")
        settle()
        report("portrait", bar: bar, discBottom: restingLine, card: card, discPushed: discPushed)
        assertTheBarsLine(bar, restingLine: restingLine, card: card, orientation: "Portrait")
        if !withConfirmCard {
            XCTAssertEqual(
                bar.minY - discPushed.maxY, 8, accuracy: 1,
                "Portrait: the bar is not the stack's 8pt under the disc it pushes up"
            )
            // The scroll-clearance look: the last row of a scrolled Today against the lifted bar.
            for _ in 0..<4 { app.swipeUp() }
            settle()
            holdPose("\(pose)-portrait-scrolled-to-bottom")
        }

        XCTAssertTrue(UITestSession.rotateToLandscape(app), "The window never went landscape")
        settle()
        let landscapeBar = collapsedCard(in: app)
        let landscapeCard = withConfirmCard ? confirmButton(in: app).frame : nil
        report("landscape", bar: landscapeBar, discBottom: disc.frame.maxY, card: landscapeCard, discPushed: nil)
        holdPose("\(pose)-landscape")
        assertTheBarsLine(landscapeBar, restingLine: disc.frame.maxY, card: landscapeCard, orientation: "Landscape")
    }

    /// Signs a fresh account in with a PAUSED, collapsed sprint seeded — and a Confirm card too
    /// when asked — and waits for both to be on screen.
    @MainActor
    private func launchWithCollapsedSprint(withConfirmCard: Bool) throws -> XCUIApplication {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: withConfirmCard ? "barliftconfirm" : "barlift")
        var arguments = UITestSession.pausedSprintLaunchArguments(
            taskTitle: "celebration sound testing", collapsed: true
        )
        if withConfirmCard {
            arguments += UITestSession.unconfirmedCompletionLaunchArguments(taskTitle: "the sprint before")
        }
        let app = try UITestSession.launchSignedIn(as: account, launchArguments: arguments)
        addTeardownBlock { @MainActor in
            UITestSession.resetToPortrait()
        }
        // iOS's own prompts first — the AutoFill "Save Password?" sheet trails sign-in and stood
        // over Today for most of an earlier run of this journey.
        sweepSystemPrompts(app, wait: 5)
        XCTAssertTrue(
            resumeButton(in: app).waitForExistence(timeout: UITestSession.timeout),
            "The seeded collapsed sprint never appeared."
        )
        if withConfirmCard {
            XCTAssertTrue(
                confirmButton(in: app).waitForExistence(timeout: UITestSession.timeout),
                "The seeded Confirm card never appeared."
            )
        }
        settle()
        return app
    }

    /// The bar's bottom on the disc's resting line — 32pt above the tab bar — and, with a Confirm
    /// card up, its Confirm button clear above the bar.
    @MainActor
    private func assertTheBarsLine(_ bar: CGRect, restingLine: CGFloat, card: CGRect?, orientation: String) {
        XCTAssertEqual(
            bar.maxY, restingLine, accuracy: 1,
            "\(orientation): the collapsed bar's bottom is \(bar.maxY - restingLine)pt off the disc's line"
                + " — dropped toward the tab bar"
        )
        if let card {
            XCTAssertLessThanOrEqual(
                card.maxY, bar.minY, "\(orientation): the Confirm button runs into the collapsed bar"
            )
        }
    }

    /// The gap above the tab bar is the disc line's 32pt less however far the bar drops below it.
    private func report(_ orientation: String, bar: CGRect, discBottom: CGFloat, card: CGRect?, discPushed: CGRect?) {
        let gapAboveTabBar = discBottom + 32 - bar.maxY
        let confirmToBar = card.map { bar.minY - $0.maxY }
        print("[BAR-LINE] \(orientation) bar=\(bar) discRestingBottom=\(discBottom)"
            + " gapAboveTabBar=\(gapAboveTabBar) confirmButton=\(String(describing: card))"
            + " confirmButtonToBar=\(String(describing: confirmToBar)) discPushed=\(String(describing: discPushed))")
    }

    /// The collapsed card, read from its Pause button. The card's `focusTimerBar` identifier never
    /// surfaces as an element of its own, and it OVERRIDES its children's — the largest match is
    /// the title (measured 165 × 16), and `focusBarPause` matches nothing at all — but Pause is the
    /// collapsed row's 44pt height, and the card is that row plus
    /// `FocusBarMetrics.collapsedPaddingVertical` (8) above and below: 60pt.
    @MainActor
    private func collapsedCard(in app: XCUIApplication) -> CGRect {
        let pause = resumeButton(in: app).frame
        return CGRect(x: pause.minX, y: pause.minY - 8, width: pause.width, height: pause.height + 16)
    }

    /// The Confirm card's button, by label for the same reason — its card identifier may override too.
    @MainActor
    private func confirmButton(in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Confirm'")).firstMatch
    }

    /// Found by LABEL, for the reason above. The seeded sprint is paused, so the collapsed card's
    /// Pause control reads "Resume sprint"; the expanded card's control is labelled "Resume".
    @MainActor
    private func resumeButton(in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == 'Resume sprint'")).firstMatch
    }

    /// Holds a pose for the host-side poller, stamped with the host clock it names its files by.
    private func holdPose(_ name: String) {
        print("[POSE] \(name) t=\(Int(Date().timeIntervalSince1970))")
        Thread.sleep(forTimeInterval: 3.0)
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
