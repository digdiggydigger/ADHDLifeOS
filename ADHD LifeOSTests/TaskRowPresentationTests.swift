//
//  TaskRowPresentationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The dense task row's one-line meta (F-V3-Tasks-rebuild): "💼 Work & Career · P1 · Due today"
/// for open tasks, "💼 Work & Career · closed 05:41" for closed ones. Pure strings so the row
/// view stays logic-free.
final class TaskRowPresentationTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private let work = LifeArea(id: UUID(), name: "Work & Career", colour: "💼", sortOrder: 0)

    private func task(
        status: TaskStatus = .open,
        priority: TaskPriority = .p1,
        dueDaysFromNow: Int? = nil,
        completedAt: Date? = nil
    ) -> TaskItem {
        TaskItem(
            id: UUID(), lifeAreaId: work.id, title: "Task", status: status, priority: priority,
            dueDate: dueDaysFromNow.map { calendar.date(byAdding: .day, value: $0, to: now)! },
            completedAt: completedAt
        )
    }

    // MARK: - Open rows

    func testMetaLine_open_areaPriorityAndDuePhrase() {
        XCTAssertEqual(
            TaskRowPresentation.metaLine(
                task: task(dueDaysFromNow: 0), lifeArea: work, asOf: now, calendar: calendar
            ),
            "💼 Work & Career · P1 · Due today"
        )
        XCTAssertEqual(
            TaskRowPresentation.metaLine(
                task: task(dueDaysFromNow: -2), lifeArea: work, asOf: now, calendar: calendar
            ),
            "💼 Work & Career · P1 · Overdue"
        )
    }

    func testMetaLine_open_undatedSkipsTheDuePhrase() {
        XCTAssertEqual(
            TaskRowPresentation.metaLine(task: task(), lifeArea: work, asOf: now, calendar: calendar),
            "💼 Work & Career · P1"
        )
    }

    func testMetaLine_open_withoutAnAreaLeadsWithPriority() {
        let orphan = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Task", status: .open, priority: .p3, dueDate: nil
        )
        XCTAssertEqual(
            TaskRowPresentation.metaLine(task: orphan, lifeArea: nil, asOf: now, calendar: calendar),
            "P3"
        )
    }

    // MARK: - Closed rows

    func testMetaLine_closed_readsTheClosedTimeNotPriority() {
        let closedAt = calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 5, minute: 41))!
        let line = TaskRowPresentation.metaLine(
            task: task(status: .done, completedAt: closedAt), lifeArea: work, asOf: now, calendar: calendar
        )
        XCTAssertEqual(line, "💼 Work & Career · closed \(Self.expectedTime(closedAt, calendar: calendar))")
        XCTAssertFalse(line.contains("P1"), "a closed row's meta is about the closure, not urgency")
    }

    /// `status: done` with no stamp means "done, at an unknown time" (see `TaskCompletionStamp`) —
    /// the row states the closure without inventing a moment.
    func testMetaLine_closed_withoutAStampSaysClosedWithNoTime() {
        XCTAssertEqual(
            TaskRowPresentation.metaLine(
                task: task(status: .done), lifeArea: work, asOf: now, calendar: calendar
            ),
            "💼 Work & Career · closed"
        )
    }

    // MARK: - Accessibility

    func testAccessibilityLabel_open_readsAreaAndPriorityInWords() {
        let label = TaskRowPresentation.accessibilityLabel(
            task: task(dueDaysFromNow: 0), lifeArea: work, asOf: now, calendar: calendar
        )
        XCTAssertEqual(label, "Work & Career, Priority p1, Due today")
    }

    func testAccessibilityLabel_closed_readsTheClosure() {
        let closedAt = calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 5, minute: 41))!
        XCTAssertEqual(
            TaskRowPresentation.accessibilityLabel(
                task: task(status: .done, completedAt: closedAt),
                lifeArea: work, asOf: now, calendar: calendar
            ),
            "Work & Career, closed \(Self.expectedTime(closedAt, calendar: calendar))"
        )
    }

    /// Built with the same locale-aware short time style the implementation must use — the tests
    /// pin the *structure*, not one locale's rendering of 05:41.
    private static func expectedTime(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
