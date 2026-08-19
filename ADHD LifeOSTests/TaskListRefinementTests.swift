//
//  TaskListRefinementTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Ports the web Tasks screen's client-side refinement (`TaskListView.tsx`): case-insensitive
/// title search, an urgency filter, and the sort dropdown (default order / by urgency / by due
/// date, undated tasks last). Pure, so it's testable without a service or view host.
final class TaskListRefinementTests: XCTestCase {
    private func task(
        _ title: String,
        priority: TaskPriority = .p3,
        dueDate: Date? = nil
    ) -> TaskItem {
        TaskItem(
            id: UUID(), lifeAreaId: nil, title: title, status: .open, priority: priority, dueDate: dueDate
        )
    }

    // MARK: - Search

    func testSearch_isCaseInsensitiveTitleSubstring() {
        let tasks = [task("Draft the report"), task("Water the plants"), task("REPORT expenses")]

        let refined = TaskListRefinement.apply(
            tasks: tasks, searchText: "report", priorityFilter: nil, sort: .standard
        )

        XCTAssertEqual(refined.map(\.title), ["Draft the report", "REPORT expenses"])
    }

    func testSearch_blankQueryMatchesEverything() {
        let tasks = [task("One"), task("Two")]

        let refined = TaskListRefinement.apply(
            tasks: tasks, searchText: "   ", priorityFilter: nil, sort: .standard
        )

        XCTAssertEqual(refined.count, 2)
    }

    // MARK: - Priority filter

    func testPriorityFilter_keepsOnlyMatchingTasks() {
        let tasks = [task("A", priority: .p1), task("B", priority: .p2), task("C", priority: .p1)]

        let refined = TaskListRefinement.apply(
            tasks: tasks, searchText: "", priorityFilter: .p1, sort: .standard
        )

        XCTAssertEqual(refined.map(\.title), ["A", "C"])
    }

    // MARK: - Sort

    func testStandardSort_preservesIncomingOrder() {
        let tasks = [task("B", priority: .p4), task("A", priority: .p1)]

        let refined = TaskListRefinement.apply(
            tasks: tasks, searchText: "", priorityFilter: nil, sort: .standard
        )

        XCTAssertEqual(refined.map(\.title), ["B", "A"])
    }

    func testPrioritySort_highestUrgencyFirst_stableWithinRank() {
        let tasks = [
            task("Low", priority: .p4),
            task("High first", priority: .p1),
            task("Mid", priority: .p3),
            task("High second", priority: .p1)
        ]

        let refined = TaskListRefinement.apply(
            tasks: tasks, searchText: "", priorityFilter: nil, sort: .priority
        )

        XCTAssertEqual(refined.map(\.title), ["High first", "High second", "Mid", "Low"])
    }

    func testDueDateSort_soonestFirst_undatedLast() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let tasks = [
            task("Undated"),
            task("Later", dueDate: now.addingTimeInterval(86_400)),
            task("Soon", dueDate: now)
        ]

        let refined = TaskListRefinement.apply(
            tasks: tasks, searchText: "", priorityFilter: nil, sort: .dueDate
        )

        XCTAssertEqual(refined.map(\.title), ["Soon", "Later", "Undated"])
    }

    // MARK: - Composition

    func testSearchFilterAndSort_composeInThatOrder() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let tasks = [
            task("Pay invoice", priority: .p1, dueDate: now.addingTimeInterval(3600)),
            task("Pay rent", priority: .p1, dueDate: now),
            task("Pay respects", priority: .p4, dueDate: now),
            task("Water plants", priority: .p1, dueDate: now)
        ]

        let refined = TaskListRefinement.apply(
            tasks: tasks, searchText: "pay", priorityFilter: .p1, sort: .dueDate
        )

        XCTAssertEqual(refined.map(\.title), ["Pay rent", "Pay invoice"])
    }
}
