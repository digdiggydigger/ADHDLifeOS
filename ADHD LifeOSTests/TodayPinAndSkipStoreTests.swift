//
//  TodayPinAndSkipStoreTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `F-E3-OneCardToday`: the pin toggle and "Not this one" are device-local and PER ACCOUNT — the
/// `NudgeFirstRunMarker` lesson, where a device-wide key leaked one account's answer into the next
/// account signed into the same phone.
final class TodayPinAndSkipStoreTests: XCTestCase {

    private var defaults: UserDefaults!
    private let suiteName = "TodayPinAndSkipStoreTests"

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }()

    private func date(day: Int, hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour))!
    }

    override func setUpWithError() throws {
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
    }

    // MARK: - The pin

    func testNothingIsPinnedForAnUnknownAccount() {
        XCTAssertNil(TodayPinStore.pinnedTaskId(uid: "alice", in: defaults))
    }

    func testAPinPersistsForThatAccountOnly() {
        let id = UUID()
        TodayPinStore.pin(id, uid: "alice", in: defaults)
        XCTAssertEqual(TodayPinStore.pinnedTaskId(uid: "alice", in: defaults), id)
        XCTAssertNil(TodayPinStore.pinnedTaskId(uid: "bob", in: defaults))
    }

    func testPinningAnotherTaskReplacesThePin() {
        let first = UUID()
        let second = UUID()
        TodayPinStore.pin(first, uid: "alice", in: defaults)
        TodayPinStore.pin(second, uid: "alice", in: defaults)
        XCTAssertEqual(TodayPinStore.pinnedTaskId(uid: "alice", in: defaults), second)
    }

    func testUnpinningClearsIt() {
        TodayPinStore.pin(UUID(), uid: "alice", in: defaults)
        TodayPinStore.unpin(uid: "alice", in: defaults)
        XCTAssertNil(TodayPinStore.pinnedTaskId(uid: "alice", in: defaults))
    }

    func testThePinKeyNamesTheAccount() {
        XCTAssertEqual(TodayPinStore.key(for: "alice"), "today.pinnedTaskId.alice")
    }

    // MARK: - "Not this one"

    func testNothingIsSkippedForAnUnknownAccount() {
        XCTAssertEqual(
            TodaySkipStore.skippedTaskIds(uid: "alice", asOf: date(day: 26, hour: 9), calendar: calendar, in: defaults),
            []
        )
    }

    func testSkipsAccumulateThroughTheDay() {
        let first = UUID()
        let second = UUID()
        TodaySkipStore.skip(first, uid: "alice", asOf: date(day: 26, hour: 9), calendar: calendar, in: defaults)
        TodaySkipStore.skip(second, uid: "alice", asOf: date(day: 26, hour: 21), calendar: calendar, in: defaults)
        XCTAssertEqual(
            TodaySkipStore.skippedTaskIds(
                uid: "alice", asOf: date(day: 26, hour: 23), calendar: calendar, in: defaults
            ),
            [first, second]
        )
    }

    /// Round 5b: *"the card won't offer it again until TOMORROW"*.
    func testSkipsExpireAtTheStartOfTheNextDay() {
        TodaySkipStore.skip(UUID(), uid: "alice", asOf: date(day: 26, hour: 23), calendar: calendar, in: defaults)
        XCTAssertEqual(
            TodaySkipStore.skippedTaskIds(uid: "alice", asOf: date(day: 27, hour: 0), calendar: calendar, in: defaults),
            []
        )
    }

    /// A skip on a new day starts that day's set rather than adding to yesterday's.
    func testAFirstSkipOnANewDayDropsYesterdays() {
        let yesterday = UUID()
        let today = UUID()
        TodaySkipStore.skip(
            yesterday, uid: "alice", asOf: date(day: 26, hour: 20), calendar: calendar, in: defaults
        )
        TodaySkipStore.skip(today, uid: "alice", asOf: date(day: 27, hour: 8), calendar: calendar, in: defaults)
        XCTAssertEqual(
            TodaySkipStore.skippedTaskIds(uid: "alice", asOf: date(day: 27, hour: 9), calendar: calendar, in: defaults),
            [today]
        )
    }

    func testSkipsBelongToOneAccount() {
        TodaySkipStore.skip(UUID(), uid: "alice", asOf: date(day: 26, hour: 9), calendar: calendar, in: defaults)
        XCTAssertEqual(
            TodaySkipStore.skippedTaskIds(uid: "bob", asOf: date(day: 26, hour: 9), calendar: calendar, in: defaults),
            []
        )
    }

    func testTheSkipKeyNamesTheAccount() {
        XCTAssertEqual(TodaySkipStore.key(for: "alice"), "today.skippedTaskIds.alice")
    }
}
