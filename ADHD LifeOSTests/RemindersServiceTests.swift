//
//  RemindersServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class RemindersServiceTests: XCTestCase {

    private final class FakeRemindersClientAdapting: RemindersClientAdapting {
        var result: Result<[Reminder], Error> = .success([])
        private(set) var fetchCallCount = 0

        func fetchReminders() async throws -> [Reminder] {
            fetchCallCount += 1
            return try result.get()
        }
    }

    func testInitialState_isLoading() {
        let sut = RemindersService(client: FakeRemindersClientAdapting())

        XCTAssertEqual(sut.state, .loading)
    }

    func testLoad_success_setsLoadedState() async {
        let fake = FakeRemindersClientAdapting()
        let reminder = Reminder(id: "1", type: .reminder, title: "Test")
        fake.result = .success([reminder])
        let sut = RemindersService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([reminder]))
        XCTAssertEqual(fake.fetchCallCount, 1)
    }

    func testLoad_emptyData_setsLoadedEmptyState() async {
        let sut = RemindersService(client: FakeRemindersClientAdapting())

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([]))
    }

    func testLoad_clientThrows_setsFailedState() async {
        let fake = FakeRemindersClientAdapting()
        fake.result = .failure(RemindersServiceError.fetchFailed("Network error"))
        let sut = RemindersService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .failed("Network error"))
    }

    func testSort_prefersDatetimeDescending() {
        let base = Date(timeIntervalSince1970: 1_000_000)
        let earlier = Reminder(id: "earlier", type: .reminder, datetime: base)
        let later = Reminder(id: "later", type: .reminder, datetime: base.addingTimeInterval(3600))

        let sorted = RemindersService.sorted([earlier, later])

        XCTAssertEqual(sorted.map(\.id), ["later", "earlier"])
    }

    func testSort_itemsWithNoDatetimeSortLastOrderedByCreatedDescending() {
        let withDate = Reminder(id: "withDate", type: .reminder, datetime: Date(timeIntervalSince1970: 500))
        let noDateOlder = Reminder(
            id: "noDateOlder", type: .reminder, createdAt: Date(timeIntervalSince1970: 100)
        )
        let noDateNewer = Reminder(
            id: "noDateNewer", type: .reminder, createdAt: Date(timeIntervalSince1970: 200)
        )

        let sorted = RemindersService.sorted([noDateOlder, withDate, noDateNewer])

        XCTAssertEqual(sorted.map(\.id), ["withDate", "noDateNewer", "noDateOlder"])
    }

    func testSort_emptyInput_returnsEmpty() {
        XCTAssertEqual(RemindersService.sorted([]), [])
    }
}
