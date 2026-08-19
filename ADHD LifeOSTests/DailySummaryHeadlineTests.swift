//
//  DailySummaryHeadlineTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The synthesized headline is the one piece of `DailySummaryView` with branching logic, split
/// into a pure enum precisely so it's testable without rendering. Priority order under test:
/// due nudges beat inbox ideas beat the empty slate beat the general open-task line.
final class DailySummaryHeadlineTests: XCTestCase {
    func testDueNudgesTakePriority() {
        let text = DailySummaryHeadline.text(openTasks: 5, lifeAreas: 3, inbox: 4, dueNudges: 2)
        XCTAssertEqual(text, "2 nudges are due — a tiny step right now counts.")
    }

    func testSingularNudge() {
        let text = DailySummaryHeadline.text(openTasks: 0, lifeAreas: 0, inbox: 0, dueNudges: 1)
        XCTAssertEqual(text, "1 nudge is due — a tiny step right now counts.")
    }

    func testInboxBeatsOpenTasks() {
        let text = DailySummaryHeadline.text(openTasks: 5, lifeAreas: 3, inbox: 3, dueNudges: 0)
        XCTAssertEqual(text, "3 ideas captured — triage one to clear your head.")
    }

    func testSingularIdea() {
        let text = DailySummaryHeadline.text(openTasks: 0, lifeAreas: 0, inbox: 1, dueNudges: 0)
        XCTAssertEqual(text, "1 idea captured — triage it to clear your head.")
    }

    func testCleanSlate() {
        let text = DailySummaryHeadline.text(openTasks: 0, lifeAreas: 6, inbox: 0, dueNudges: 0)
        XCTAssertEqual(text, "A clean slate today. Add one small task to build momentum.")
    }

    func testGeneralOpenTasksLine() {
        let text = DailySummaryHeadline.text(openTasks: 7, lifeAreas: 4, inbox: 0, dueNudges: 0)
        XCTAssertEqual(text, "7 open tasks across 4 areas — start with the smallest one.")
    }

    func testSingularTaskAndArea() {
        let text = DailySummaryHeadline.text(openTasks: 1, lifeAreas: 1, inbox: 0, dueNudges: 0)
        XCTAssertEqual(text, "1 open task across 1 area — start with the smallest one.")
    }
}
