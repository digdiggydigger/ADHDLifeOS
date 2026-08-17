//
//  JournalServiceTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class JournalServiceTests: XCTestCase {

    private func makeLog(
        lifeAreaId: UUID? = nil,
        type: LogType = .log,
        body: String = "Entry",
        entryDate: Date = Date()
    ) -> Log {
        Log(id: UUID(), lifeAreaId: lifeAreaId, type: type, body: body, entryDate: entryDate, createdAt: entryDate)
    }

    func testInitialState_isLoading() {
        let fake = FakeJournalClientAdapting()
        let sut = JournalService(client: fake)

        XCTAssertEqual(sut.state, .loading)
    }

    func testLoad_success_setsLoadedStateNewestFirst() async {
        let fake = FakeJournalClientAdapting()
        let older = makeLog(body: "Older", entryDate: Date(timeIntervalSince1970: 0))
        let newer = makeLog(body: "Newer", entryDate: Date(timeIntervalSince1970: 100))
        fake.logsResult = .success([older, newer])
        let sut = JournalService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([newer, older]))
        XCTAssertEqual(fake.fetchLifeAreasCallCount, 1)
        XCTAssertEqual(fake.fetchLogsCallCount, 1)
    }

    func testLoad_emptyData_setsLoadedStateWithEmptyList() async {
        let fake = FakeJournalClientAdapting()
        let sut = JournalService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([]))
    }

    func testLoad_lifeAreasFetchFails_setsFailedState() async {
        let fake = FakeJournalClientAdapting()
        fake.lifeAreasResult = .failure(JournalServiceError.fetchFailed("Network error"))
        let sut = JournalService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .failed("Network error"))
    }

    func testLoad_logsFetchFails_setsFailedState() async {
        let fake = FakeJournalClientAdapting()
        fake.logsResult = .failure(JournalServiceError.fetchFailed("Network error"))
        let sut = JournalService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .failed("Network error"))
    }

    func testChangingLifeAreaFilter_afterLoad_refiltersWithoutRefetching() async {
        let fake = FakeJournalClientAdapting()
        let workId = UUID()
        let personalId = UUID()
        let workLog = makeLog(lifeAreaId: workId, body: "Work log")
        let personalLog = makeLog(lifeAreaId: personalId, body: "Personal log")
        fake.logsResult = .success([workLog, personalLog])
        let sut = JournalService(client: fake)
        await sut.load()

        sut.selectedLifeAreaId = workId

        XCTAssertEqual(sut.state, .loaded([workLog]))
        XCTAssertEqual(fake.fetchLogsCallCount, 1)
    }

    func testChangingLifeAreaFilter_toAreaWithNoMatches_setsLoadedStateWithEmptyList() async {
        let fake = FakeJournalClientAdapting()
        let workId = UUID()
        let otherId = UUID()
        fake.logsResult = .success([makeLog(lifeAreaId: otherId)])
        let sut = JournalService(client: fake)
        await sut.load()

        sut.selectedLifeAreaId = workId

        XCTAssertEqual(sut.state, .loaded([]))
    }

    func testChangingLifeAreaFilter_beforeLoad_doesNotChangeState() {
        let fake = FakeJournalClientAdapting()
        let sut = JournalService(client: fake)

        sut.selectedLifeAreaId = UUID()

        XCTAssertEqual(sut.state, .loading)
        XCTAssertEqual(fake.fetchLogsCallCount, 0)
    }

    func testCreateLog_emptyBody_isRejectedWithoutNetworkCall() async {
        let fake = FakeJournalClientAdapting()
        let sut = JournalService(client: fake)
        sut.composerBody = "   "

        let result = await sut.createLog()

        XCTAssertFalse(result)
        XCTAssertEqual(fake.createLogCallCount, 0)
        XCTAssertNotNil(sut.createErrorMessage)
    }

    func testCreateLog_success_appendsToFeedAndResetsComposer() async {
        let fake = FakeJournalClientAdapting()
        let sut = JournalService(client: fake)
        await sut.load()
        sut.composerBody = "Had a good day"
        sut.composerType = .journal

        let result = await sut.createLog()

        XCTAssertTrue(result)
        XCTAssertEqual(fake.createLogCallCount, 1)
        XCTAssertEqual(fake.lastCreateLogInput?.body, "Had a good day")
        XCTAssertEqual(fake.lastCreateLogInput?.type, .journal)
        guard case .loaded(let logs) = sut.state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.body, "Had a good day")
        XCTAssertEqual(sut.composerBody, "", "Body should reset after a successful create")
        XCTAssertEqual(sut.composerType, .log, "Type should reset to default after a successful create")
    }

    func testCreateLog_networkFailure_surfacesErrorAndDoesNotClearComposer() async {
        let fake = FakeJournalClientAdapting()
        fake.createLogResult = .failure(JournalServiceError.fetchFailed("Network error"))
        let sut = JournalService(client: fake)
        sut.composerBody = "Had a good day"

        let result = await sut.createLog()

        XCTAssertFalse(result)
        XCTAssertEqual(sut.createErrorMessage, "Network error")
        XCTAssertEqual(sut.composerBody, "Had a good day")
    }
}
