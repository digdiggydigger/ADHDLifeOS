//
//  CaptureInboxTriageCountsTests.swift
//  ADHD LifeOSTests
//
//  The filter picker's numbers, after a triage exit rather than after a load.
//

import XCTest
@testable import ADHD_LifeOS

/// **The picker must never contradict the headline.** E's device screenshot (2026-08-28) showed
/// "To triage (18)" sitting directly above "17 left", with a 17 on the tab badge, on a screen where
/// one capture had just been journalled — three numbers for one queue, two of them wrong.
///
/// The cause was that `state` and `counts` were separate truths: every exit rewrote the list and
/// none of them touched the counts, so the only thing that ever corrected a tab label was a fresh
/// `load()`. The headline reads the list; the picker reads the counts; they drifted apart the
/// instant anything left the inbox.
///
/// Two rules come out of that, and this file exists to hold them:
///
/// 1. The ACTIVE tab's count follows the list synchronously — no fetch, no window in which the two
///    disagree, because they are now the same number by construction.
/// 2. The DESTINATION tab's count is re-learned afterwards, by the existing failure-tolerant
///    contract: a capture that leaves To triage arrives somewhere, and that tab was equally stale.
@MainActor
final class CaptureInboxTriageCountsTests: XCTestCase {
    private func capture(
        _ content: String, kind: CaptureKind = .note, lifeAreaId: UUID? = nil
    ) -> Capture {
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

    /// Three filters on purpose: the bug is invisible on a single-filter service, because there is
    /// no second label to go stale and `refreshInactiveCount` has nothing to loop over.
    private func makeSUT(
        unprocessed: [Capture],
        seen: [Capture] = [],
        promoted: [Capture] = []
    ) async -> SUT {
        let client = FakeCaptureClientAdapting()
        let journal = FakeJournalClientAdapting()
        client.fetchUnprocessedCapturesResult = .success(unprocessed)
        client.fetchSeenCapturesResult = .success(seen)
        client.fetchProcessedCapturesResult = .success(promoted)
        let service = CaptureInboxService(
            client: client, journalClient: journal, transcriber: FakeVoiceTranscribing(),
            availableFilters: [.unprocessed, .seen, .promoted]
        )
        await service.load()
        return SUT(service: service, client: client, journal: journal)
    }

    /// The exact shape of E's screenshot: journal one of two, and read both numbers back.
    func testJournalIt_dropsTheActiveCount_soThePickerCannotContradictTheHeadline() async {
        let thought = capture("Book the dentist")
        let env = await makeSUT(unprocessed: [thought, capture("Keep me")])
        XCTAssertEqual(env.service.counts[.unprocessed], 2, "precondition: the load learned 2")

        let succeeded = await env.service.logToJournal(capture: thought)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(env.service.captures.count, 1, "the headline's number")
        XCTAssertEqual(
            env.service.counts[.unprocessed], 1,
            "the picker's number — 'To triage (2)' above '1 left' is the bug E photographed"
        )
    }

    func testSort_dropsTheActiveCount() async {
        let filed = capture("Book the dentist")
        let env = await makeSUT(unprocessed: [filed, capture("Keep me")])

        let succeeded = await env.service.sort(capture: filed, into: UUID())

        XCTAssertTrue(succeeded)
        XCTAssertEqual(env.service.counts[.unprocessed], env.service.captures.count)
        XCTAssertEqual(env.service.counts[.unprocessed], 1)
    }

    func testDiscard_dropsTheActiveCount() async {
        let doomed = capture("Idle thought")
        let env = await makeSUT(unprocessed: [doomed, capture("Keep me")])

        let succeeded = await env.service.discard(capture: doomed)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(env.service.counts[.unprocessed], 1)
    }

    /// The reverse direction leaves the Sorted slice, so it is the Sorted tab that must drop.
    func testUndoSeen_dropsTheActiveCountOfTheSliceItWasTappedOn() async {
        let client = FakeCaptureClientAdapting()
        let restored = capture("Sorted too early")
        client.fetchSeenCapturesResult = .success([restored, capture("Still sorted")])
        client.fetchUnprocessedCapturesResult = .success([])
        let service = CaptureInboxService(
            client: client, transcriber: FakeVoiceTranscribing(),
            availableFilters: [.unprocessed, .seen]
        )
        await service.select(filter: .seen)
        XCTAssertEqual(service.counts[.seen], 2, "precondition")

        let succeeded = await service.undoSeen(capture: restored)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(service.counts[.seen], 1)
    }

    /// A failed exit removes nothing, so it must not move a number either — a count that dropped
    /// on a write that never landed is worse than a stale one, because it looks like it worked.
    func testFailedExit_leavesTheCountAlone() async {
        let thought = capture("Book the dentist")
        let env = await makeSUT(unprocessed: [thought, capture("Keep me")])
        env.client.markProcessedResult = .failure(CaptureServiceError.fetchFailed("Network error"))

        let succeeded = await env.service.logToJournal(capture: thought)

        XCTAssertFalse(succeeded)
        XCTAssertEqual(env.service.counts[.unprocessed], 2, "nothing left the inbox")
        XCTAssertEqual(env.service.captures.count, 2)
    }

    // MARK: - The destination tab

    /// Journalling marks a capture processed, so it lands in Promoted — the tab whose label was
    /// still reading 11 in E's screenshot after a twelfth arrived.
    func testJournalIt_relearnsThePromotedCount() async {
        let thought = capture("Book the dentist")
        let alreadyThere = capture("Booked it")
        let env = await makeSUT(unprocessed: [thought], promoted: [alreadyThere])
        XCTAssertEqual(env.service.counts[.promoted], 1, "precondition")
        // What the backend would return once the journalled capture is processed.
        env.client.fetchProcessedCapturesResult = .success([alreadyThere, thought])

        _ = await env.service.logToJournal(capture: thought)

        XCTAssertEqual(
            env.service.counts[.promoted], 2,
            "the capture arrived somewhere; that tab's number was equally stale"
        )
    }

    /// Sorting writes `seen`, so the Sorted tab is the one that gains.
    func testSort_relearnsTheSeenCount() async {
        let filed = capture("Book the dentist")
        let env = await makeSUT(unprocessed: [filed], seen: [])
        env.client.fetchSeenCapturesResult = .success([filed])

        _ = await env.service.sort(capture: filed, into: UUID())

        XCTAssertEqual(env.service.counts[.seen], 1)
    }

    // MARK: - Undo

    /// Undo is an exit in reverse and leaves exactly the same staleness behind: the capture comes
    /// back to To triage, so Promoted has one fewer. `refresh()` alone only ever corrected the tab
    /// the user was standing on.
    func testUndoJournalIt_relearnsBothCounts() async {
        let thought = capture("Book the dentist")
        let alreadyThere = capture("Booked it")
        let env = await makeSUT(unprocessed: [thought], promoted: [alreadyThere])
        env.client.fetchProcessedCapturesResult = .success([alreadyThere, thought])
        _ = await env.service.logToJournal(capture: thought)
        XCTAssertEqual(env.service.counts[.promoted], 2, "precondition: the exit was counted")

        // What the backend holds once the capture is un-processed again.
        env.client.fetchUnprocessedCapturesResult = .success([thought])
        env.client.fetchProcessedCapturesResult = .success([alreadyThere])

        let undone = await env.service.undoLastTriageAction()

        XCTAssertTrue(undone)
        XCTAssertEqual(env.service.counts[.unprocessed], 1, "it came back")
        XCTAssertEqual(env.service.counts[.promoted], 1, "and it left where it had gone")
    }

    func testUndoSort_relearnsBothCounts() async {
        let filed = capture("Book the dentist")
        let env = await makeSUT(unprocessed: [filed])
        env.client.fetchSeenCapturesResult = .success([filed])
        _ = await env.service.sort(capture: filed, into: UUID())
        XCTAssertEqual(env.service.counts[.seen], 1, "precondition")

        env.client.fetchUnprocessedCapturesResult = .success([filed])
        env.client.fetchSeenCapturesResult = .success([])

        let undone = await env.service.undoLastTriageAction()

        XCTAssertTrue(undone)
        XCTAssertEqual(env.service.counts[.unprocessed], 1)
        XCTAssertEqual(env.service.counts[.seen], 0)
    }

    /// Counts are decoration, and the load contract already says a failed count fetch must never
    /// turn a good screen into a bad one. An exit is no different — the capture DID leave.
    func testWhenTheDestinationCountFetchFails_theExitStillSucceedsAndTheActiveCountIsStillRight() async {
        let thought = capture("Book the dentist")
        let env = await makeSUT(unprocessed: [thought, capture("Keep me")], promoted: [])
        env.client.fetchProcessedCapturesResult =
            .failure(CaptureServiceError.fetchFailed("Network error"))

        let succeeded = await env.service.logToJournal(capture: thought)

        XCTAssertTrue(succeeded, "a decoration fetch must never fail the exit")
        XCTAssertNil(env.service.triageErrorMessage, "nor surface an error for it")
        XCTAssertEqual(env.service.counts[.unprocessed], 1, "the active count is local, so it held")
    }
}
