//
//  NudgeScheduleParsingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class NudgeScheduleParsingTests: XCTestCase {

    // MARK: Existing presets still parse correctly

    func testParse_dailyAt9Preset_matchesAllWeekdays() {
        let schedule = NudgeSchedule.parse(cronString: "0 9 * * *")

        XCTAssertEqual(schedule, NudgeSchedule(hour: 9, minute: 0, weekdays: Set(0...6)))
    }

    func testParse_weekdaysAt9Preset_matchesMondayThroughFriday() {
        let schedule = NudgeSchedule.parse(cronString: "0 9 * * 1-5")

        XCTAssertEqual(schedule, NudgeSchedule(hour: 9, minute: 0, weekdays: [1, 2, 3, 4, 5]))
    }

    func testParse_everyMondayAt9Preset_matchesMondayOnly() {
        let schedule = NudgeSchedule.parse(cronString: "0 9 * * 1")

        XCTAssertEqual(schedule, NudgeSchedule(hour: 9, minute: 0, weekdays: [1]))
    }

    // MARK: Arbitrary time-of-day / weekday combinations

    func testParse_tuesdayAndThursdayAt8am() {
        let schedule = NudgeSchedule.parse(cronString: "0 8 * * 2,4")

        XCTAssertEqual(schedule, NudgeSchedule(hour: 8, minute: 0, weekdays: [2, 4]))
    }

    func testParse_everyDayAt630pm() {
        let schedule = NudgeSchedule.parse(cronString: "30 18 * * *")

        XCTAssertEqual(schedule, NudgeSchedule(hour: 18, minute: 30, weekdays: Set(0...6)))
    }

    func testParse_saturdayAndSundayAt10am() {
        let schedule = NudgeSchedule.parse(cronString: "0 10 * * 6,0")

        XCTAssertEqual(schedule, NudgeSchedule(hour: 10, minute: 0, weekdays: [0, 6]))
    }

    func testParse_sundayAsSeven_normalizesToZero() {
        let schedule = NudgeSchedule.parse(cronString: "0 9 * * 7")

        XCTAssertEqual(schedule, NudgeSchedule(hour: 9, minute: 0, weekdays: [0]))
    }

    // MARK: Malformed / unsupported strings fall back to nil

    func testParse_dayOfMonthPresent_isUnsupported() {
        XCTAssertNil(NudgeSchedule.parse(cronString: "0 9 1 * *"))
    }

    func testParse_monthPresent_isUnsupported() {
        XCTAssertNil(NudgeSchedule.parse(cronString: "0 9 * 6 *"))
    }

    func testParse_stepValueInHour_isUnsupported() {
        XCTAssertNil(NudgeSchedule.parse(cronString: "0 */2 * * *"))
    }

    func testParse_stepValueInMinute_isUnsupported() {
        XCTAssertNil(NudgeSchedule.parse(cronString: "*/15 9 * * *"))
    }

    func testParse_emptyDayList_isUnsupported() {
        XCTAssertNil(NudgeSchedule.parse(cronString: "0 9 * *"))
    }

    func testParse_outOfRangeHour_isUnsupported() {
        XCTAssertNil(NudgeSchedule.parse(cronString: "0 24 * * *"))
    }

    func testParse_outOfRangeWeekday_isUnsupported() {
        XCTAssertNil(NudgeSchedule.parse(cronString: "0 9 * * 8"))
    }

    func testParse_wrongFieldCount_isUnsupported() {
        XCTAssertNil(NudgeSchedule.parse(cronString: "0 9 * *"))
        XCTAssertNil(NudgeSchedule.parse(cronString: "0 9 * * * *"))
    }

    func testParse_nonNumericMinute_isUnsupported() {
        XCTAssertNil(NudgeSchedule.parse(cronString: "abc 9 * * *"))
    }

    // MARK: Round-trip via encode()

    func testEncode_roundTripsThroughParse() {
        let schedule = NudgeSchedule(hour: 8, minute: 0, weekdays: [2, 4])

        XCTAssertEqual(NudgeSchedule.parse(cronString: schedule.encode()), schedule)
    }

    func testEncode_producesSortedCommaList() {
        let schedule = NudgeSchedule(hour: 8, minute: 0, weekdays: [4, 2])

        XCTAssertEqual(schedule.encode(), "0 8 * * 2,4")
    }
}
