//
//  ActiveGoalSelectionTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Home's "Active Goal" hero picks ONE task to headline. The web's rule was "first high-priority
/// open task, else first open task" over an ordered array; our Firestore open-tasks query is
/// unsorted (no composite index), so "first" is meaningless and the tie-breaks are made explicit:
/// highest urgency band wins, then the earliest due date (undated last), then stable input order.
final class ActiveGoalSelectionTests: XCTestCase {
    private func summary(
        _ title: String,
        priority: TaskPriority = .p3,
        status: TaskStatus = .open,
        dueDate: Date? = nil
    ) -> TaskSummary {
        TaskSummary(lifeAreaId: nil, status: status, title: title, priority: priority, dueDate: dueDate)
    }

    func testTopTask_emptyList_returnsNil() {
        XCTAssertNil(ActiveGoalSelection.topTask(in: []))
    }

    func testTopTask_ignoresDoneTasks() {
        let tasks = [summary("Done thing", priority: .p1, status: .done)]
        XCTAssertNil(ActiveGoalSelection.topTask(in: tasks))
    }

    func testTopTask_highestUrgencyBandWins() {
        let tasks = [
            summary("Routine", priority: .p3),
            summary("Urgent", priority: .p1),
            summary("Soonish", priority: .p2)
        ]
        XCTAssertEqual(ActiveGoalSelection.topTask(in: tasks)?.title, "Urgent")
    }

    func testTopTask_withinBand_earliestDueDateWins_undatedLast() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let tasks = [
            summary("Undated", priority: .p1),
            summary("Later", priority: .p1, dueDate: now.addingTimeInterval(7200)),
            summary("Soonest", priority: .p1, dueDate: now)
        ]
        XCTAssertEqual(ActiveGoalSelection.topTask(in: tasks)?.title, "Soonest")
    }

    func testTopTask_fullTie_keepsInputOrder() {
        let tasks = [
            summary("First in", priority: .p2),
            summary("Second in", priority: .p2)
        ]
        XCTAssertEqual(ActiveGoalSelection.topTask(in: tasks)?.title, "First in")
    }

    // MARK: - The widened TaskSummary projection decodes from the same task document

    func testTaskSummaryDecoding_readsHeroFields_andToleratesAbsentOptionals() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let tuned = Data("""
        {"id": "\(UUID().uuidString)", "title": "Tuned", "status": "open", "priority": "p1",
         "notes": "Two micro-steps", "due_date": 1700000000,
         "focus_duration_seconds": 300, "nudges_count": 3}
        """.utf8)
        let legacy = Data("""
        {"id": "\(UUID().uuidString)", "title": "Legacy", "status": "open", "priority": "p2"}
        """.utf8)

        let tunedSummary = try decoder.decode(TaskSummary.self, from: tuned)
        let legacySummary = try decoder.decode(TaskSummary.self, from: legacy)

        XCTAssertEqual(tunedSummary.title, "Tuned")
        XCTAssertEqual(tunedSummary.priority, .p1)
        XCTAssertEqual(tunedSummary.notes, "Two micro-steps")
        XCTAssertEqual(tunedSummary.dueDate, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(tunedSummary.focusDurationSeconds, 300)
        XCTAssertEqual(tunedSummary.nudgesCount, 3)

        XCTAssertEqual(legacySummary.title, "Legacy")
        XCTAssertNil(legacySummary.notes)
        XCTAssertNil(legacySummary.dueDate)
        XCTAssertNil(legacySummary.focusDurationSeconds)
        XCTAssertNil(legacySummary.nudgesCount)
    }
}
