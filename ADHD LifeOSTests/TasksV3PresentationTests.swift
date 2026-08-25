//
//  TasksV3PresentationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The v3 Tasks screen's pure presentation (F-V3-Tasks): the header count line and the coloured
/// bucket headers.
final class TasksV3PresentationTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 9, minute: 41))!
    }

    private func task(status: TaskStatus, dueDaysFromNow: Int? = nil) -> TaskItem {
        TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Task", status: status, priority: .p3,
            dueDate: dueDaysFromNow.map { calendar.date(byAdding: .day, value: $0, to: now)! }
        )
    }

    func testHeaderLine_countsOpenAndOverdue() {
        let tasks = [
            task(status: .open, dueDaysFromNow: -2),
            task(status: .open, dueDaysFromNow: 0),
            task(status: .open),
            task(status: .done, dueDaysFromNow: -5)
        ]
        XCTAssertEqual(
            MomentumTaskBuckets.headerLine(tasks: tasks, asOf: now, calendar: calendar),
            "3 open · 1 overdue"
        )
    }

    func testHeaderLine_singularAndClean() {
        XCTAssertEqual(
            MomentumTaskBuckets.headerLine(tasks: [task(status: .open)], asOf: now, calendar: calendar),
            "1 open · 0 overdue"
        )
        XCTAssertEqual(
            MomentumTaskBuckets.headerLine(tasks: [], asOf: now, calendar: calendar),
            "0 open · 0 overdue"
        )
    }

    func testBucketHeaderTones_matchTheV3Hues() {
        XCTAssertEqual(MomentumTaskBuckets.headerToneAssetName(customId: "momentum-dueToday"), "StateWarn")
        XCTAssertEqual(MomentumTaskBuckets.headerToneAssetName(customId: "momentum-tomorrow"), "AccentColor")
        XCTAssertEqual(MomentumTaskBuckets.headerToneAssetName(customId: "momentum-closedToday"), "StateGo")
        XCTAssertNil(MomentumTaskBuckets.headerToneAssetName(customId: "momentum-later"))
        XCTAssertNil(MomentumTaskBuckets.headerToneAssetName(customId: "momentum-someday"))
        XCTAssertNil(MomentumTaskBuckets.headerToneAssetName(customId: nil))
    }
}
