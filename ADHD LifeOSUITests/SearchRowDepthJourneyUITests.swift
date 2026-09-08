//
//  SearchRowDepthJourneyUITests.swift
//  ADHD LifeOSUITests
//
//  E's screenshot (2026-09-08 06:20): a task's DETAIL screen, pushed from the Tasks list, with
//  the bottom-search arc's "Search tasks" row still sitting above the tab bar beside the capture
//  disc. *"We need to remove the 'search tasks' search bar from a full view task screen."*
//
//  **This is the block's acceptance test.** `AppSearchScopeTests` proves the rule takes the
//  depth; `AppSearchCallSiteTests` proves `RootView` feeds it the depth; only this proves the row
//  actually leaves when a detail is pushed and comes back when it pops, because the row is a
//  view at the root and no unit test can see it.
//

import XCTest

final class SearchRowDepthJourneyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// The row is on the list, gone over the pushed detail, and back once block 1's re-tap pops
    /// the detail. The task is seeded with a known id so the journey opens THAT row rather than
    /// guessing (the `SignedInJourneyUITests` detail-population arrangement).
    @MainActor
    func testTheSearchRowLeavesWithAPushedTaskDetailAndReturnsWhenItPops() throws {
        try UITestEmulator.skipUnlessRunning()
        let account = try UITestSession.createAccount(label: "search-row-depth")
        let taskID = UUID()
        try UITestSession.seedTask(id: taskID, title: "Renew the passport", uid: account.uid)
        let app = try UITestSession.launchSignedIn(as: account)

        UITestSession.openTab("Tasks", in: app)
        // By identifier and any type: the control is a Button carrying the search-field trait,
        // and which element type XCUITest files it under is not the point.
        let row = app.descendants(matching: .any)["appSearchRow"]
        XCTAssertTrue(
            row.waitForExistence(timeout: UITestSession.timeout),
            "The search row never appeared on the Tasks list, so there is nothing to hide."
        )

        let taskRow = app.descendants(matching: .any)["taskRow-\(taskID.uuidString)"]
        XCTAssertTrue(
            taskRow.waitForExistence(timeout: UITestSession.timeout),
            "The seeded task never appeared in the list."
        )
        let titleField = app.textFields["taskDetailTitleField"]
        XCTAssertTrue(UITestSession.tap(taskRow, untilExists: titleField), "Task detail never opened.")
        attach(app, "1-task-detail-pushed")

        // Waited for, not read once: the row leaves on the overlay's spring, so it is still in the
        // tree for the first third of a second after the push.
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: row)
        XCTAssertEqual(
            XCTWaiter().wait(for: [gone], timeout: UITestSession.timeout), .completed,
            "E's screenshot, unchanged: \"Search tasks\" is still beside the capture disc with a"
                + " task's detail pushed over the list."
        )

        // The way back is block 1's re-tap. `openTab` returns early on a selected slot, so the
        // slot is tapped directly, through the retrying helper (the re-tap journey's pattern).
        let tasksTab = UITestSession.tabButton("Tasks", in: app)
        XCTAssertTrue(tasksTab.isSelected, "Tasks is not the selected tab, so this would be a select, not a re-tap.")
        XCTAssertTrue(
            UITestSession.tap(tasksTab, untilExists: row),
            "The search row did not return once the Tasks re-tap popped the detail."
        )
        XCTAssertFalse(titleField.exists, "The task detail is still pushed after the Tasks re-tap.")
        attach(app, "2-list-back-row-back")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
