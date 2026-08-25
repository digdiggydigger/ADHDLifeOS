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

    // MARK: - Sprints and captures alongside the logs (E's note, 2026-08-25)

    func testLoad_populatesFocusSessionsAndCaptures() async {
        let fake = FakeJournalClientAdapting()
        let sprint = CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Draft", lifeAreaEmoji: "💼",
            plannedSeconds: 1_500, focusedSeconds: 1_500, checkpointsReached: 2,
            completedNaturally: true, startedAt: Date(timeIntervalSince1970: 0),
            endedAt: Date(timeIntervalSince1970: 1_500)
        )
        let capture = Capture(
            id: UUID(), content: "stray thought", kind: .note, processed: false,
            createdAt: Date(timeIntervalSince1970: 100)
        )
        fake.focusSessionsResult = .success([sprint])
        fake.capturesResult = .success([capture])
        let sut = JournalService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.focusSessions, [sprint])
        XCTAssertEqual(sut.captures, [capture])
    }

    // MARK: - Composer tags (E's 2026-08-25 note: journal and logs take tags too)

    func testLoad_populatesAvailableTags() async {
        let fake = FakeJournalClientAdapting()
        let tag = Tag(id: UUID(), name: "errands")
        fake.allTagsResult = .success([tag])
        let sut = JournalService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.availableTags, [tag])
    }

    func testCreateLog_sendsTheSelectedTagsAndResetsThem() async {
        let fake = FakeJournalClientAdapting()
        let sut = JournalService(client: fake)
        let tagIds = [UUID(), UUID()]
        sut.composerBody = "Tagged entry"
        sut.composerTagIds = tagIds

        let created = await sut.createLog()

        XCTAssertTrue(created)
        XCTAssertEqual(fake.lastCreateLogInput?.tagIds, tagIds)
        XCTAssertEqual(sut.composerTagIds, [], "selection must reset with the rest of the composer")
    }

    func testCreateTagForComposer_createsSelectsAndListsTheTag() async {
        let fake = FakeJournalClientAdapting()
        let tag = Tag(id: UUID(), name: "deep-work")
        fake.createTagResult = .success(tag)
        let sut = JournalService(client: fake)

        let returned = await sut.createTagForComposer(name: "deep-work")

        XCTAssertEqual(returned, tag)
        XCTAssertEqual(sut.composerTagIds, [tag.id], "a freshly made tag is what you meant to use")
        XCTAssertTrue(sut.availableTags.contains(tag))
    }

    func testCreateTagForComposer_failureSurfacesTheErrorWithoutSelecting() async {
        let fake = FakeJournalClientAdapting()
        fake.createTagResult = .failure(JournalServiceError.fetchFailed("down"))
        let sut = JournalService(client: fake)

        let returned = await sut.createTagForComposer(name: "deep-work")

        XCTAssertNil(returned)
        XCTAssertEqual(sut.createErrorMessage, "down")
        XCTAssertEqual(sut.composerTagIds, [])
    }

    /// The side streams are garnish, never load-bearing: their failure must not take the written
    /// journal down — same non-blocking posture as the view's task fetch.
    func testLoad_sprintOrCaptureFailureLeavesThemEmptyWithoutFailingTheJournal() async {
        let fake = FakeJournalClientAdapting()
        let log = makeLog()
        fake.logsResult = .success([log])
        fake.focusSessionsResult = .failure(JournalServiceError.fetchFailed("down"))
        fake.capturesResult = .failure(JournalServiceError.fetchFailed("down"))
        let sut = JournalService(client: fake)

        await sut.load()

        XCTAssertEqual(sut.state, .loaded([log]))
        XCTAssertEqual(sut.focusSessions, [])
        XCTAssertEqual(sut.captures, [])
    }
}
