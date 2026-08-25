//
//  JournalTimelineTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The v3 Journal timeline (F-V3-Journal): entries and closed tasks share one day-grouped
/// stream — newest day first, chronological within a day — with the filter and header line.
final class JournalTimelineTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.locale = Locale(identifier: "en_US")
        return cal
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private func log(daysAgo: Int, hour: Int, areaId: UUID? = nil) -> Log {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        return Log(
            id: UUID(), lifeAreaId: areaId, type: .journal, body: "entry",
            entryDate: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!,
            createdAt: now
        )
    }

    private func doneTask(daysAgo: Int, hour: Int, areaId: UUID? = nil) -> TaskItem {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
        return TaskItem(
            id: UUID(), lifeAreaId: areaId, title: "Done", status: .done,
            priority: .p3, dueDate: nil,
            completedAt: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
        )
    }

    func testDays_groupAndOrder() {
        let days = JournalTimeline.days(
            logs: [log(daysAgo: 0, hour: 4), log(daysAgo: 1, hour: 9)],
            tasks: [doneTask(daysAgo: 0, hour: 5), doneTask(daysAgo: 1, hour: 17)],
            asOf: now, calendar: calendar
        )
        XCTAssertEqual(days.count, 2)
        XCTAssertEqual(days[0].title, "Today")
        XCTAssertEqual(days[1].title, "Yesterday")
        // Chronological within the day: the 04:00 entry precedes the 05:00 closure.
        if case .log = days[0].entries[0] {} else { XCTFail("Expected the log first") }
        if case .closedTask = days[0].entries[1] {} else { XCTFail("Expected the closure second") }
    }

    func testFilters_splitWrittenFromClosed() {
        let logs = [log(daysAgo: 0, hour: 4)]
        let tasks = [doneTask(daysAgo: 0, hour: 5)]
        XCTAssertEqual(
            JournalTimeline.days(logs: logs, tasks: tasks, filter: .written, asOf: now, calendar: calendar)
                .flatMap(\.entries).count,
            1
        )
        XCTAssertEqual(
            JournalTimeline.days(logs: logs, tasks: tasks, filter: .closed, asOf: now, calendar: calendar)
                .flatMap(\.entries).count,
            1
        )
    }

    func testAreaFilter_appliesToBothStreams() {
        let area = UUID()
        let days = JournalTimeline.days(
            logs: [log(daysAgo: 0, hour: 4, areaId: area), log(daysAgo: 0, hour: 6)],
            tasks: [doneTask(daysAgo: 0, hour: 5, areaId: area), doneTask(daysAgo: 0, hour: 7)],
            lifeAreaId: area,
            asOf: now, calendar: calendar
        )
        XCTAssertEqual(days.flatMap(\.entries).count, 2)
    }

    func testHeaderLine_countsTheRollingWeek() {
        XCTAssertEqual(
            JournalTimeline.headerLine(
                logs: [log(daysAgo: 2, hour: 9), log(daysAgo: 20, hour: 9)],
                tasks: [doneTask(daysAgo: 0, hour: 5), doneTask(daysAgo: 30, hour: 5)],
                asOf: now, calendar: calendar
            ),
            "1 closed · 1 written this week"
        )
    }
}
