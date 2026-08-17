//
//  LogSortingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class LogSortingTests: XCTestCase {

    private func makeLog(
        lifeAreaId: UUID? = nil,
        body: String = "Entry",
        entryDate: Date
    ) -> Log {
        Log(id: UUID(), lifeAreaId: lifeAreaId, type: .log, body: body, entryDate: entryDate, createdAt: entryDate)
    }

    // MARK: sortByEntryDateDescending

    func testSort_emptyList_returnsEmpty() {
        XCTAssertEqual(LogSorting.sortByEntryDateDescending([]), [])
    }

    func testSort_singleEntry_returnsSameEntry() {
        let log = makeLog(entryDate: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(LogSorting.sortByEntryDateDescending([log]), [log])
    }

    func testSort_mixedDates_ordersNewestFirst() {
        let oldest = makeLog(body: "Oldest", entryDate: Date(timeIntervalSince1970: 0))
        let middle = makeLog(body: "Middle", entryDate: Date(timeIntervalSince1970: 100))
        let newest = makeLog(body: "Newest", entryDate: Date(timeIntervalSince1970: 200))

        let sorted = LogSorting.sortByEntryDateDescending([middle, oldest, newest])

        XCTAssertEqual(sorted, [newest, middle, oldest])
    }

    // MARK: filterByLifeArea

    func testFilter_nilLifeAreaId_returnsAllLogs() {
        let workId = UUID()
        let logs = [makeLog(lifeAreaId: workId, entryDate: Date()), makeLog(lifeAreaId: nil, entryDate: Date())]

        XCTAssertEqual(LogSorting.filterByLifeArea(logs, lifeAreaId: nil), logs)
    }

    func testFilter_specificLifeAreaId_returnsOnlyMatches() {
        let workId = UUID()
        let personalId = UUID()
        let workLog = makeLog(lifeAreaId: workId, entryDate: Date())
        let personalLog = makeLog(lifeAreaId: personalId, entryDate: Date())

        let filtered = LogSorting.filterByLifeArea([workLog, personalLog], lifeAreaId: workId)

        XCTAssertEqual(filtered, [workLog])
    }

    func testFilter_lifeAreaWithNoLogs_returnsEmpty() {
        let workId = UUID()
        let otherId = UUID()
        let logs = [makeLog(lifeAreaId: otherId, entryDate: Date())]

        XCTAssertEqual(LogSorting.filterByLifeArea(logs, lifeAreaId: workId), [])
    }
}
