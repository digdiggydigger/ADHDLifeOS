//
//  TaskStatusFilterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class TaskStatusFilterTests: XCTestCase {

    private func makeTask(title: String, status: TaskStatus) -> TaskItem {
        TaskItem(id: UUID(), lifeAreaId: nil, title: title, status: status, priority: .p4, dueDate: nil)
    }

    func testFilter_open_returnsOnlyOpenTasks() {
        let tasks = [
            makeTask(title: "Open task", status: .open),
            makeTask(title: "Done task", status: .done)
        ]

        let result = TaskStatusFilter.filter(tasks: tasks, by: .open)

        XCTAssertEqual(result.map(\.title), ["Open task"])
    }

    func testFilter_done_returnsOnlyDoneTasks() {
        let tasks = [
            makeTask(title: "Open task", status: .open),
            makeTask(title: "Done task", status: .done)
        ]

        let result = TaskStatusFilter.filter(tasks: tasks, by: .done)

        XCTAssertEqual(result.map(\.title), ["Done task"])
    }

    /// Momentum is "what's moving today": everything open, plus today's closures as evidence.
    /// Yesterday's wins belong to Done, not to today's board.
    func testFilter_momentum_returnsOpenPlusTodaysClosures() {
        var closedToday = makeTask(title: "Closed today", status: .done)
        closedToday.completedAt = Date()
        var closedYesterday = makeTask(title: "Closed yesterday", status: .done)
        closedYesterday.completedAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())

        let result = TaskStatusFilter.filter(
            tasks: [makeTask(title: "Open task", status: .open), closedToday, closedYesterday],
            by: .momentum
        )

        XCTAssertEqual(result.map(\.title), ["Open task", "Closed today"])
    }

    func testFilter_all_returnsEveryTask() {
        let tasks = [
            makeTask(title: "Open task", status: .open),
            makeTask(title: "Done task", status: .done)
        ]

        let result = TaskStatusFilter.filter(tasks: tasks, by: .all)

        XCTAssertEqual(result.map(\.title), ["Open task", "Done task"])
    }

    func testFilter_done_withNoDoneTasks_returnsEmptyArray() {
        let tasks = [makeTask(title: "Open task", status: .open)]

        let result = TaskStatusFilter.filter(tasks: tasks, by: .done)

        XCTAssertEqual(result, [])
    }

    func testStatusFilterOption_id_matchesRawValue() {
        XCTAssertEqual(TaskStatusFilterOption.open.id, "open")
        XCTAssertEqual(TaskStatusFilterOption.done.id, "done")
        XCTAssertEqual(TaskStatusFilterOption.all.id, "all")
    }

    func testStatusFilterOption_label_isHumanReadable() {
        XCTAssertEqual(TaskStatusFilterOption.open.label, "Open")
        XCTAssertEqual(TaskStatusFilterOption.done.label, "Done")
        XCTAssertEqual(TaskStatusFilterOption.all.label, "All")
    }
}
