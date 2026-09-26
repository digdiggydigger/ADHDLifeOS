//
//  WeekReviewOneChartRenderUITests.swift
//  ADHD LifeOSUITests
//
//  `F-E4-WeekReviewConsolidation`'s evidence harness — the frames for `screenshots/week-review-one-chart/`.
//
//  Round 3, *"One bar chart in Week review. Keep the Mon–Sun bars and drop the 7-day trend line."*
//  Unit tests pin the week's buckets, the goal's plumbing and what the widget shed; only the real
//  screen shows the one chart where the closures bars were, with and without a goal — and reached
//  through BOTH doors, which is the claim that each carries the goal.
//
//  Run one appearance per run with `scripts/build-loop/ui.sh` (the tag names the frames).
//

import XCTest

final class WeekReviewOneChartRenderUITests: XCTestCase {

    private var tag: String { ProcessInfo.processInfo.environment["TODAY_RENDER_TAG"] ?? "X" }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRenderTheOneChartWithoutAndWithAGoal() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "e4chart")
        try seedWeek(uid: account.uid)
        let app = try UITestSession.launchSignedIn(as: account)

        // 1 — through the Areas door, no goal set: the one chart, no goal bar.
        UITestSession.openTab("Areas", in: app)
        let areasDoor = app.buttons["areasWeekReviewRow"].firstMatch
        let chart = element("weeklyFocusSummaryWidget", in: app)
        XCTAssertTrue(UITestSession.tap(areasDoor, untilExists: chart), "Week review drew no focus chart")
        UITestSession.dismissSystemPasswordPromptIfPresent()
        assertTheChartShedItsExtras(in: app)
        let anyGoalLine = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Weekly goal"))
        XCTAssertEqual(anyGoalLine.count, 0, "A goal bar with no goal set")
        XCTAssertFalse(element("weekReviewBars", in: app).exists, "The closures bars are still drawn")
        print("MEASURE chart-\(tag) chart=\(chart.frame)")
        attach(app, named: "01-no-goal-from-areas-\(tag)")

        // 2 — set a focus goal in Settings, then through TODAY's door: the goal bar appears.
        setTheFocusGoal(enabled: true, in: app)
        let doneLine = app.buttons["homeWeekReviewRow"].firstMatch
        let header = element("weekReviewHeader", in: app)
        XCTAssertTrue(UITestSession.tap(doneLine, untilExists: header), "Today's done line opened no review")
        let goalLine = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Weekly goal")).firstMatch
        XCTAssertTrue(goalLine.waitForExistence(timeout: UITestSession.timeout), "A set goal drew no goal bar")
        print("MEASURE chart-\(tag) goal=\(goalLine.label)")
        attach(app, named: "02-goal-set-from-today-\(tag)")

        app.navigationBars.buttons.firstMatch.tap()
        setTheFocusGoal(enabled: false, in: app)
    }

    // MARK: - Assertions

    @MainActor
    private func assertTheChartShedItsExtras(in app: XCUIApplication) {
        XCTAssertFalse(element("weeklyFocusUnitPicker", in: app).exists, "The minutes/hours toggle is back")
        XCTAssertFalse(app.staticTexts["Day Streak"].exists, "The day-streak stat is back")
        XCTAssertFalse(element("productivityTrendChart", in: app).exists, "The trend line is back")
    }

    // MARK: - Settings

    @MainActor
    private func setTheFocusGoal(enabled: Bool, in app: XCUIApplication) {
        UITestSession.openTab("Today", in: app)
        let gear = app.buttons["settingsButton"].firstMatch
        let done = app.buttons["settingsDoneButton"].firstMatch
        XCTAssertTrue(UITestSession.tap(gear, untilExists: done), "Settings never opened from Today's gear")
        let toggle = app.switches["settingsFocusGoalToggle"].firstMatch
        UITestSession.scrollUntilHittable(toggle, in: app)
        let stepper = app.steppers["settingsFocusGoalStepper"].firstMatch
        let verb = enabled ? "set" : "clear"
        XCTAssertTrue(flip(toggle, until: stepper, exists: enabled), "The focus goal toggle did not \(verb)")
        done.tap()
    }

    /// Taps the SWITCH end of a Form toggle row (`WeeklyChainRenderUITests`' lesson: on iOS 26+ a
    /// tap on the label does not always flip it).
    @MainActor
    private func flip(_ toggle: XCUIElement, until target: XCUIElement, exists: Bool) -> Bool {
        for _ in 1...3 {
            if target.exists == exists { return true }
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            let settled = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == %@", NSNumber(value: exists)), object: target
            )
            if XCTWaiter().wait(for: [settled], timeout: 4) == .completed { return true }
        }
        return target.exists == exists
    }

    // MARK: - Seeding

    /// Two areas (which stands the first-run seed down) and one CONFIRMED sprint on each day from
    /// Monday to today — confirmed, so no confirmation card takes the screen.
    private func seedWeek(uid: String) throws {
        for (order, name) in ["Work", "Home"].enumerated() {
            let id = UUID()
            try UITestEmulator.writeDocument(
                path: "users/\(uid)/life_areas/\(id.uuidString)",
                fields: [
                    "id": UITestEmulator.string(id.uuidString), "name": UITestEmulator.string(name),
                    "colour": UITestEmulator.string(order == 0 ? "💼" : "🏠"),
                    "sort_order": ["integerValue": String(order)]
                ]
            )
        }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sinceMonday = (calendar.component(.weekday, from: today) + 5) % 7
        let minutes = [25, 50, 0, 75, 30, 20, 40]
        for back in 0...sinceMonday where minutes[sinceMonday - back] > 0 {
            let day = calendar.date(byAdding: .day, value: -back, to: today)!
            let ended = min(day.addingTimeInterval(12 * 3600), Date().addingTimeInterval(-60))
            try seedSprint(minutes: minutes[sinceMonday - back], endedAt: ended, uid: uid)
        }
    }

    private func seedSprint(minutes: Int, endedAt: Date, uid: String) throws {
        let id = UUID()
        let seconds = String(minutes * 60)
        try UITestEmulator.writeDocument(
            path: "users/\(uid)/focus_sessions/\(id.uuidString)",
            fields: [
                "id": UITestEmulator.string(id.uuidString),
                "task_title": UITestEmulator.string("Draft the brief"),
                "life_area_emoji": UITestEmulator.string("💼"),
                "planned_seconds": ["integerValue": seconds],
                "focused_seconds": ["integerValue": seconds],
                "checkpoints_reached": ["integerValue": "0"],
                "completed_naturally": UITestEmulator.bool(true),
                "started_at": UITestEmulator.timestamp(endedAt.addingTimeInterval(TimeInterval(-minutes * 60))),
                "ended_at": UITestEmulator.timestamp(endedAt),
                "confirmed_at": UITestEmulator.timestamp(endedAt)
            ]
        )
    }

    // MARK: - Plumbing

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    private func attach(_ app: XCUIApplication, named name: String) {
        UITestSession.dismissSystemPasswordPromptIfPresent()
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
