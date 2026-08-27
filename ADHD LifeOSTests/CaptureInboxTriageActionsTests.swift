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
        // One sequence, both seams — undoing "Journal it" spans them and its ORDER is the safety
        // argument, so the two fakes have to stamp against the same counter.
        let sequence = TriageCallSequence()
        client.callSequence = sequence
        journal.callSequence = sequence
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

    // MARK: - Undoing "Journal it"

    /// The exit that had no way back. Sorted and Skip have been undoable since round 1; this one
    /// was left out because reversing it needs BOTH a log-delete and an inverse to `markProcessed`
    /// — neither existed, and an Undo offered for something it cannot reverse is worse than none.
    /// Both exist now, so the queue's fourth verb finally joins them.
    func testLogToJournal_recordsAnUndoableActionNamingTheEntryItWrote() async {
        let thought = capture("Rain smelled like school")
        let env = await makeSUT(loaded: [thought])
        let logId = UUID()
        env.journal.createLogResult = .success(
            Log(id: logId, lifeAreaId: nil, type: .journal, body: "x", entryDate: Date(), createdAt: Date())
        )

        _ = await env.service.logToJournal(capture: thought)

        XCTAssertEqual(
            env.service.lastTriageAction, .journaled(captureId: thought.id, logId: logId),
            "undo has to know WHICH entry to delete — the capture id alone cannot find it"
        )
    }

    /// Order is load-bearing and it is the REVERSE of the forward path's. Forward writes the entry
    /// first and only then retires the capture, so a half-failure never loses the thought. Undo
    /// restores the capture FIRST for the same reason: if the delete then fails, the capture is
    /// back and a stray entry remains — visible, recoverable, nothing lost. Deleting first and
    /// failing to restore would erase the thought from both places at once.
    func testUndoJournal_restoresTheCaptureBeforeDeletingTheEntry() async {
        let thought = capture("Rain smelled like school")
        let env = await makeSUT(loaded: [thought])
        let logId = UUID()
        env.journal.createLogResult = .success(
            Log(id: logId, lifeAreaId: nil, type: .journal, body: "x", entryDate: Date(), createdAt: Date())
        )
        _ = await env.service.logToJournal(capture: thought)

        let undone = await env.service.undoLastTriageAction()

        XCTAssertTrue(undone)
        XCTAssertEqual(env.client.lastMarkUnprocessedCaptureId, thought.id)
        XCTAssertEqual(env.journal.lastDeleteLogId, logId)
        XCTAssertEqual(
            env.client.markUnprocessedCallOrder, 0,
            "the capture must be back before its entry is deleted"
        )
        XCTAssertEqual(env.journal.deleteLogCallOrder, 1)
    }

    func testUndoJournal_isSpentOnceUsed() async {
        let thought = capture("Rain smelled like school")
        let env = await makeSUT(loaded: [thought])
        _ = await env.service.logToJournal(capture: thought)
        _ = await env.service.undoLastTriageAction()

        XCTAssertNil(env.service.lastTriageAction)
        let secondAttempt = await env.service.undoLastTriageAction()
        XCTAssertFalse(secondAttempt)
    }

    /// The capture never came back, so nothing was undone and the offer stands. Critically the
    /// entry is NOT deleted — that would leave the thought nowhere at all.
    func testUndoJournal_whenTheCaptureCannotBeRestored_deletesNothingAndKeepsTheOffer() async {
        let thought = capture("Rain smelled like school")
        let env = await makeSUT(loaded: [thought])
        _ = await env.service.logToJournal(capture: thought)
        env.client.markUnprocessedResult = .failure(CaptureServiceError.fetchFailed("offline"))

        let undone = await env.service.undoLastTriageAction()

        XCTAssertFalse(undone)
        XCTAssertNil(env.journal.lastDeleteLogId, "the entry is the only copy left — never delete it blind")
        XCTAssertEqual(env.service.triageErrorMessage, "offline")
        XCTAssertNotNil(env.service.lastTriageAction, "nothing happened, so the offer still stands")
    }

    /// The half-failure worth naming: the capture IS back, so the undo did the thing the user
    /// asked for, but a duplicate entry is sitting in their journal. Same shape as the promote
    /// path's "Task created, but couldn't mark the capture as processed."
    func testUndoJournal_whenOnlyTheEntryDeleteFails_succeedsAndSaysWhatIsLeftBehind() async {
        let thought = capture("Rain smelled like school")
        let env = await makeSUT(loaded: [thought])
        _ = await env.service.logToJournal(capture: thought)
        env.journal.deleteLogResult = .failure(JournalServiceError.fetchFailed("offline"))

        let undone = await env.service.undoLastTriageAction()

        XCTAssertTrue(undone, "the capture came back, which is what undo promised")
        XCTAssertNil(env.service.lastTriageAction, "and the offer is spent")
        XCTAssertEqual(
            env.service.warningMessage,
            "Capture is back in your inbox, but its journal entry couldn't be removed."
        )
    }

    func testConfirmation_journalledSaysWhatHappened() {
        XCTAssertEqual(
            CaptureTriage.confirmation(
                for: .journaled(captureId: UUID(), logId: UUID()), sortedInto: nil, lifeAreas: []
            ),
            "Journalled — it's in your journal"
        )
    }
}
