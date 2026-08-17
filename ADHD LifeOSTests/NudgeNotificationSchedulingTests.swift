//
//  NudgeNotificationSchedulingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class NudgeNotificationSchedulingTests: XCTestCase {

    func testTriggerComponents_singleWeekday_producesOneComponent() {
        let schedule = NudgeSchedule(hour: 9, minute: 0, weekdays: [1])

        let components = NudgeNotificationScheduling.triggerComponents(for: schedule)

        XCTAssertEqual(components.count, 1)
        XCTAssertEqual(components[0].hour, 9)
        XCTAssertEqual(components[0].minute, 0)
        XCTAssertEqual(components[0].weekday, 2, "Cron Monday (1) should map to DateComponents weekday 2")
    }

    func testTriggerComponents_multipleWeekdays_producesOnePerWeekday() {
        let schedule = NudgeSchedule(hour: 18, minute: 30, weekdays: [1, 2, 3, 4, 5])

        let components = NudgeNotificationScheduling.triggerComponents(for: schedule)

        XCTAssertEqual(components.count, 5)
        XCTAssertEqual(components.compactMap(\.weekday), [2, 3, 4, 5, 6])
        XCTAssertTrue(components.allSatisfy { $0.hour == 18 && $0.minute == 30 })
    }

    func testTriggerComponents_allSevenDays_producesSevenComponents() {
        let schedule = NudgeSchedule(hour: 9, minute: 0, weekdays: Set(0...6))

        let components = NudgeNotificationScheduling.triggerComponents(for: schedule)

        XCTAssertEqual(components.count, 7)
        XCTAssertEqual(components.compactMap(\.weekday).sorted(), [1, 2, 3, 4, 5, 6, 7])
    }

    /// The boundary case most likely to be off-by-one: cron `0` (Sunday) must map to
    /// `DateComponents.weekday`'s `1`, not `0` or `7`.
    func testTriggerComponents_cronSunday_mapsToDateComponentsWeekdayOne() {
        let schedule = NudgeSchedule(hour: 9, minute: 0, weekdays: [0])

        let components = NudgeNotificationScheduling.triggerComponents(for: schedule)

        XCTAssertEqual(components.compactMap(\.weekday), [1])
    }

    /// The other boundary case: cron `6` (Saturday) must map to `DateComponents.weekday`'s `7`,
    /// not `6` or wrapping back to `1`.
    func testTriggerComponents_cronSaturday_mapsToDateComponentsWeekdaySeven() {
        let schedule = NudgeSchedule(hour: 9, minute: 0, weekdays: [6])

        let components = NudgeNotificationScheduling.triggerComponents(for: schedule)

        XCTAssertEqual(components.compactMap(\.weekday), [7])
    }
}
