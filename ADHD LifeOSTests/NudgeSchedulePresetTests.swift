//
//  NudgeSchedulePresetTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The preset layer behind the rebuilt New nudge sheet (F-NudgePresets).
///
/// Written before the implementation. The cases that matter are the two the cron convention
/// invites you to get wrong — Sunday is `0`, so "weekdays" is `1...5` and NOT `0...4` — and the
/// empty set, which must resolve to `.custom` rather than being quietly promoted to `.daily`.
final class NudgeSchedulePresetTests: XCTestCase {

    // MARK: - The sets each preset stands for

    func testDaily_selectsAllSevenDays() {
        XCTAssertEqual(NudgeSchedulePreset.daily.weekdays, Set(0...6))
    }

    /// Cron's day-of-week is `0` = Sunday, so Monday–Friday is `1...5`. Writing `0...4` here
    /// would silently schedule Sunday–Thursday, which reads correct and fires on the wrong days.
    func testWeekdays_isMondayToFriday_notSundayToThursday() {
        XCTAssertEqual(NudgeSchedulePreset.weekdays.weekdays, [1, 2, 3, 4, 5])
        XCTAssertFalse(NudgeSchedulePreset.weekdays.weekdays?.contains(0) ?? true, "Sunday is not a weekday")
        XCTAssertFalse(NudgeSchedulePreset.weekdays.weekdays?.contains(6) ?? true, "Saturday is not a weekday")
    }

    func testWeekends_isSaturdayAndSunday() {
        XCTAssertEqual(NudgeSchedulePreset.weekends.weekdays, [0, 6])
    }

    /// `.custom` has no canonical set — it is whatever the user picked, so it must not answer
    /// with one. A non-nil answer here would let the picker overwrite a custom selection.
    func testCustom_hasNoCanonicalSet() {
        XCTAssertNil(NudgeSchedulePreset.custom.weekdays)
    }

    // MARK: - Recognising a set as a preset

    func testMatching_recognisesEachNamedPreset() {
        XCTAssertEqual(NudgeSchedulePreset.matching(weekdays: Set(0...6)), .daily)
        XCTAssertEqual(NudgeSchedulePreset.matching(weekdays: [1, 2, 3, 4, 5]), .weekdays)
        XCTAssertEqual(NudgeSchedulePreset.matching(weekdays: [0, 6]), .weekends)
    }

    func testMatching_anArbitrarySet_isCustom() {
        XCTAssertEqual(NudgeSchedulePreset.matching(weekdays: [1, 3, 5]), .custom)
        XCTAssertEqual(NudgeSchedulePreset.matching(weekdays: [2]), .custom)
    }

    /// The empty set is NOT daily. `NudgeValidation` already rejects it ("Please select at least
    /// one day"), and promoting it to `.daily` here would show the user a selected Daily chip for
    /// a schedule that cannot be saved — and `NudgeSchedule.parse` treats an empty day list as
    /// never-computably-due.
    func testMatching_theEmptySet_isCustom_notDaily() {
        XCTAssertEqual(NudgeSchedulePreset.matching(weekdays: []), .custom)
    }

    func testMatching_roundTripsEveryNamedPreset() {
        for preset in NudgeSchedulePreset.allCases where preset != .custom {
            guard let days = preset.weekdays else {
                return XCTFail("\(preset) should carry a canonical set")
            }
            XCTAssertEqual(NudgeSchedulePreset.matching(weekdays: days), preset)
        }
    }

    // MARK: - The line under the chips

    func testDaySummary_namedPresets_readAsWords() {
        XCTAssertEqual(NudgeSchedulePreset.daySummary(weekdays: Set(0...6)), "Every day")
        XCTAssertEqual(NudgeSchedulePreset.daySummary(weekdays: [1, 2, 3, 4, 5]), "Every weekday")
        XCTAssertEqual(NudgeSchedulePreset.daySummary(weekdays: [0, 6]), "Weekends")
    }

    /// Week order, not insertion order — a `Set` has no order of its own, so listing it raw would
    /// produce a different sentence on different runs.
    func testDaySummary_customSet_listsDaysInWeekOrder() {
        XCTAssertEqual(NudgeSchedulePreset.daySummary(weekdays: [5, 1, 3]), "Mon, Wed, Fri")
        XCTAssertEqual(NudgeSchedulePreset.daySummary(weekdays: [6, 0]), "Weekends")
        XCTAssertEqual(NudgeSchedulePreset.daySummary(weekdays: [4, 0]), "Sun, Thu")
    }

    /// Says what is wrong rather than rendering an empty string, because this is the one state
    /// that blocks saving.
    func testDaySummary_noDays_saysSo() {
        XCTAssertEqual(NudgeSchedulePreset.daySummary(weekdays: []), "No days selected")
    }

    // MARK: - Chip titles

    func testTitles_areTheFourChipsOnTheSheet() {
        XCTAssertEqual(NudgeSchedulePreset.daily.title, "Daily")
        XCTAssertEqual(NudgeSchedulePreset.weekdays.title, "Weekdays")
        XCTAssertEqual(NudgeSchedulePreset.weekends.title, "Weekends")
        XCTAssertEqual(NudgeSchedulePreset.custom.title, "Custom")
    }

    /// The chips are rendered from `allCases`, so their order IS the on-screen order and Custom
    /// has to come last — it is the escape hatch, not a peer of the three common answers.
    func testAllCases_areInChipOrder_withCustomLast() {
        XCTAssertEqual(NudgeSchedulePreset.allCases, [.daily, .weekdays, .weekends, .custom])
    }
}
