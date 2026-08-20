//
//  CaptureInboxTriageActionsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The two triage exits the native inbox never had: **discard** and **log to journal**.
///
/// Promote-to-task was the only way a capture could leave the inbox, so anything that wasn't a task
/// — a stray thought, a thing you'd already done, a note worth keeping but not acting on — had
/// nowhere to go and sat there forever. The web prototype offers both; this ports them.
@MainActor
final class CaptureInboxTriageActionsTests: XCTestCase {
    private func capture(_ content: String, kind: CaptureKind = .note, lifeAreaId: UUID? = nil) -> Capture {
        Capture(
            id: UUID(), content: content, kind: kind, processed: false,
            createdAt: Date(), lifeAreaId: lifeAreaId
        )
    }

    private struct SUT {
        let service: CaptureInboxService
        let client: FakeCaptureClientAdapting
        let journal: FakeJournalClientAdapting
    }

    private func makeSUT(loaded: [Capture]) async -> SUT {
        let client = FakeCaptureClientAdapting()
        let journal = FakeJournalClientAdapting()
        client.fetchUnprocessedCapturesResult = .success(loaded)
        let service = CaptureInboxService(
            client: client, journalClient: journal, transcriber: FakeVoiceTranscribing()
        )
        await service.load()
        return SUT(service: service, client: client, journal: journal)
    }

    // MARK: - Discard

    func testDiscard_removesTheCaptureFromTheList() async {
        let doomed = capture("Idle thought")
        let env = await makeSUT(loaded: [doomed, capture("Keep me")])

        let succeeded = await env.service.discard(capture: doomed)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(env.service.captures.map(\.content), ["Keep me"])
        XCTAssertEqual(env.client.lastDeleteCaptureId, doomed.id)
    }

    func testDiscard_failure_keepsTheCaptureAndSurfacesTheError() async {
        let doomed = capture("Idle thought")
        let env = await makeSUT(loaded: [doomed])
        env.client.deleteCaptureResult = .failure(CaptureServiceError.fetchFailed("offline"))

        let succeeded = await env.service.discard(capture: doomed)

        XCTAssertFalse(succeeded)
        XCTAssertEqual(env.service.captures.count, 1, "a failed delete must not optimistically empty the row")
        XCTAssertEqual(env.service.triageErrorMessage, "offline")
    }

    // MARK: - Log to journal

    func testLogToJournal_writesAJournalEntryFromTheCapture() async {
        let area = UUID()
        let thought = capture("Realised I procrastinate when the first step is vague", lifeAreaId: area)
        let env = await makeSUT(loaded: [thought])

        let succeeded = await env.service.logToJournal(capture: thought)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(env.journal.lastCreateLogInput?.body, thought.content)
        XCTAssertEqual(env.journal.lastCreateLogInput?.type, .journal)
        XCTAssertEqual(
            env.journal.lastCreateLogInput?.lifeAreaId, area,
            "the capture's triaged life area carries into the entry"
        )
    }

    func testLogToJournal_marksTheCaptureProcessedAndClearsItFromTheInbox() async {
        let thought = capture("A thought")
        let env = await makeSUT(loaded: [thought, capture("Another")])

        _ = await env.service.logToJournal(capture: thought)

        XCTAssertEqual(env.client.lastMarkProcessedCaptureId, thought.id)
        XCTAssertEqual(env.service.captures.map(\.content), ["Another"])
    }

    func testLogToJournal_whenTheJournalWriteFails_leavesTheCaptureUnprocessed() async {
        let thought = capture("A thought")
        let env = await makeSUT(loaded: [thought])
        env.journal.createLogResult = .failure(CaptureServiceError.fetchFailed("offline"))

        let succeeded = await env.service.logToJournal(capture: thought)

        XCTAssertFalse(succeeded)
        XCTAssertEqual(
            env.client.markProcessedCallCount, 0,
            "never retire a capture whose journal entry didn't land — that would lose the thought"
        )
        XCTAssertEqual(env.service.captures.count, 1)
        XCTAssertEqual(env.service.triageErrorMessage, "offline")
    }

    func testLogToJournal_withNothingToWrite_failsValidationWithoutCallingTheBackend() async {
        let blank = capture("   ")
        let env = await makeSUT(loaded: [blank])

        let succeeded = await env.service.logToJournal(capture: blank)

        XCTAssertFalse(succeeded)
        XCTAssertEqual(env.journal.createLogCallCount, 0)
        XCTAssertNotNil(env.service.triageErrorMessage)
    }

    func testLogToJournal_prefersTheCapturesTitleWhenItHasOne() async {
        let titled = Capture(
            id: UUID(), content: "https://example.com/an-article", kind: .link, processed: false,
            createdAt: Date(), title: "Why vague first steps stall you"
        )
        let env = await makeSUT(loaded: [titled])

        _ = await env.service.logToJournal(capture: titled)

        XCTAssertEqual(
            env.journal.lastCreateLogInput?.body,
            "Why vague first steps stall you\nhttps://example.com/an-article",
            "a titled capture keeps both its headline and what it pointed at"
        )
    }
}
