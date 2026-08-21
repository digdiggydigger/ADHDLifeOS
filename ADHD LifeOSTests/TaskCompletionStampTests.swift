//
//  TaskCompletionStampTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `completed_at` exists so the Daily Executive Summary can answer "what did I finish today?" —
/// a question `status` alone cannot, because it carries no time. The stamp rule and the
/// same-day filter are pure so both are testable without Firestore or a clock.
/// `@MainActor` because `TaskItem`'s `Codable` conformance is main-actor-isolated in this module;
/// the wire-format tests below encode and decode it directly.
@MainActor
final class TaskCompletionStampTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_787_000_000)

    // MARK: - The stamp rule

    func testCompletingStampsTheMoment() {
        XCTAssertEqual(TaskCompletionStamp.completedAt(for: .done, now: now), now)
    }

    func testReopeningClearsTheStamp() {
        XCTAssertNil(TaskCompletionStamp.completedAt(for: .open, now: now))
    }

    /// Re-opening must clear rather than leave the old value: a task that was finished yesterday
    /// and re-opened today is not a win, and a stale stamp would keep claiming it was.
    func testReopeningDiscardsAPreviousStamp() {
        let stamped = makeTask(status: .done, completedAt: now.addingTimeInterval(-86_400))
        let reopened = TaskCompletionStamp.applying(status: .open, to: stamped, now: now)
        XCTAssertNil(reopened.completedAt)
        XCTAssertEqual(reopened.status, .open)
    }

    func testApplyingDoneSetsBothStatusAndStamp() {
        let open = makeTask(status: .open, completedAt: nil)
        let done = TaskCompletionStamp.applying(status: .done, to: open, now: now)
        XCTAssertEqual(done.status, .done)
        XCTAssertEqual(done.completedAt, now)
    }

    // MARK: - The same-day filter

    func testCompletedTodayKeepsOnlyTodaysDoneTasks() {
        let calendar = Calendar(identifier: .gregorian)
        let tasks = [
            makeTask(title: "today", status: .done, completedAt: now),
            makeTask(title: "yesterday", status: .done, completedAt: now.addingTimeInterval(-86_400)),
            makeTask(title: "open", status: .open, completedAt: nil),
            // Done before `completed_at` existed — no stamp, so not attributable to any day.
            makeTask(title: "legacy", status: .done, completedAt: nil)
        ]
        let wins = TaskCompletionStamp.completedTasks(in: tasks, on: now, calendar: calendar)
        XCTAssertEqual(wins.map(\.title), ["today"])
    }

    /// Same calendar day but hours apart still counts — the filter is day-granular, not a
    /// 24-hour window, so a task finished at 09:00 is still a win at 23:00.
    func testCompletedTodayIsDayGranularNotATwentyFourHourWindow() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let morning = calendar.date(from: DateComponents(year: 2026, month: 8, day: 21, hour: 9))!
        let evening = calendar.date(from: DateComponents(year: 2026, month: 8, day: 21, hour: 23))!
        let tasks = [makeTask(title: "morning", status: .done, completedAt: morning)]
        let wins = TaskCompletionStamp.completedTasks(in: tasks, on: evening, calendar: calendar)
        XCTAssertEqual(wins.map(\.title), ["morning"])
    }

    func testCompletedTodayIsNewestFirst() {
        let calendar = Calendar(identifier: .gregorian)
        let tasks = [
            makeTask(title: "early", status: .done, completedAt: now.addingTimeInterval(-3_600)),
            makeTask(title: "late", status: .done, completedAt: now)
        ]
        let wins = TaskCompletionStamp.completedTasks(in: tasks, on: now, calendar: calendar)
        XCTAssertEqual(wins.map(\.title), ["late", "early"])
    }

    // MARK: - Wire format

    /// The field is snake_cased to match every other key on this document, and absent rather
    /// than null when unset, matching the app's own encoder.
    func testEncodesAsCompletedAtAndIsOmittedWhenNil() throws {
        let encoder = JSONEncoder()
        let stamped = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: encoder.encode(makeTask(status: .done, completedAt: now))
            ) as? [String: Any]
        )
        XCTAssertNotNil(stamped["completed_at"])

        let unstamped = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: encoder.encode(makeTask(status: .open, completedAt: nil))
            ) as? [String: Any]
        )
        XCTAssertNil(unstamped["completed_at"])
    }

    /// A document written before the field existed must still decode — every task in E's
    /// account predates it.
    func testDecodesADocumentWithNoCompletedAtField() throws {
        let json = """
        {"id":"\(UUID().uuidString)","title":"legacy","status":"done","priority":"p2"}
        """
        let task = try JSONDecoder().decode(TaskItem.self, from: Data(json.utf8))
        XCTAssertNil(task.completedAt)
        XCTAssertEqual(task.status, .done)
    }

    // MARK: - Helpers

    private func makeTask(
        title: String = "task",
        status: TaskStatus,
        completedAt: Date?
    ) -> TaskItem {
        TaskItem(
            id: UUID(), lifeAreaId: nil, title: title, status: status,
            priority: .p2, dueDate: nil, completedAt: completedAt
        )
    }
}
