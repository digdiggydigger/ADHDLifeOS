//
//  TaskDueChoiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The S1-style task composer's "When is it due?" chips — pure mapping between a chip choice and
/// `TaskCreateService.dueDate`, so the view stays dumb. "Today" means start-of-day, the exact
/// convention the capture fan's fast-task path established (`QuickCaptureView.saveTask`).
final class TaskDueChoiceTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 8, day: 25, hour: 9, minute: 41))!
    }

    func testResolvedDueDate_perChoice() {
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        XCTAssertNil(TaskDueChoice.notYet.resolvedDueDate(existing: nil, asOf: now, calendar: calendar))
        XCTAssertEqual(
            TaskDueChoice.today.resolvedDueDate(existing: nil, asOf: now, calendar: calendar),
            today
        )
        XCTAssertEqual(
            TaskDueChoice.tomorrow.resolvedDueDate(existing: nil, asOf: now, calendar: calendar),
            tomorrow
        )
    }

    func testResolvedDueDate_customKeepsAnExistingDateAndSeedsNowWithoutOne() {
        let picked = calendar.date(from: DateComponents(year: 2026, month: 9, day: 2, hour: 15))!
        XCTAssertEqual(
            TaskDueChoice.custom.resolvedDueDate(existing: picked, asOf: now, calendar: calendar),
            picked,
            "switching to the picker must not clobber a date already chosen"
        )
        XCTAssertEqual(
            TaskDueChoice.custom.resolvedDueDate(existing: nil, asOf: now, calendar: calendar),
            now,
            "the picker needs a concrete date to start from"
        )
    }

    func testChoice_recognisesTheDateItProduced() {
        for choice in TaskDueChoice.allCases where choice != .custom {
            let date = choice.resolvedDueDate(existing: nil, asOf: now, calendar: calendar)
            XCTAssertEqual(
                TaskDueChoice.choice(for: date, asOf: now, calendar: calendar), choice,
                "\(choice) must round-trip"
            )
        }
    }

    func testChoice_anyOtherDateReadsAsCustom() {
        let picked = calendar.date(from: DateComponents(year: 2026, month: 9, day: 2, hour: 15))!
        XCTAssertEqual(TaskDueChoice.choice(for: picked, asOf: now, calendar: calendar), .custom)
        // A time WITHIN today that is not start-of-day is still a deliberate pick.
        XCTAssertEqual(TaskDueChoice.choice(for: now, asOf: now, calendar: calendar), .custom)
    }

    func testTitles_areTheChipCopy() {
        XCTAssertEqual(TaskDueChoice.notYet.title, "Not yet")
        XCTAssertEqual(TaskDueChoice.today.title, "Today")
        XCTAssertEqual(TaskDueChoice.tomorrow.title, "Tomorrow")
        XCTAssertEqual(TaskDueChoice.custom.title, "Pick a date")
    }
}
