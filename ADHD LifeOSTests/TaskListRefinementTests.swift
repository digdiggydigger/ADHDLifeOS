//
//  TaskListRefinementTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Case-insensitive title search over the loaded tasks. The web-parity urgency filter and sort
/// dropdown were retired in F-V3-Tasks-rebuild — E confirmed the refinement menu was unused
/// chrome — so search is the whole refinement now.
final class TaskListRefinementTests: XCTestCase {
    private func task(_ title: String) -> TaskItem {
        TaskItem(id: UUID(), lifeAreaId: nil, title: title, status: .open, priority: .p3, dueDate: nil)
    }

    func testSearch_isCaseInsensitiveTitleSubstring() {
        let tasks = [task("Draft the report"), task("Water the plants"), task("REPORT expenses")]

        let refined = TaskListRefinement.apply(tasks: tasks, searchText: "report")

        XCTAssertEqual(refined.map(\.title), ["Draft the report", "REPORT expenses"])
    }

    func testSearch_blankQueryMatchesEverything() {
        let tasks = [task("One"), task("Two")]

        let refined = TaskListRefinement.apply(tasks: tasks, searchText: "   ")

        XCTAssertEqual(refined.count, 2)
    }

    func testSearch_preservesIncomingOrder() {
        let tasks = [task("Pay rent"), task("Pay invoice")]

        let refined = TaskListRefinement.apply(tasks: tasks, searchText: "pay")

        XCTAssertEqual(refined.map(\.title), ["Pay rent", "Pay invoice"])
    }
}
