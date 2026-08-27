//
//  CaptureSortAndUndoTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// **Sorted** — the triage verb E asked for on 2026-08-28, after saying capture triage had fallen
/// behind the rest of the app and that "capturing is fine, deciding isn't".
///
/// It is not a new state: `seen` has existed since the third-exit block, but it was reachable only
/// from capture DETAIL, it required nothing, and the word undersold it. Sorted promotes it to a
/// first-class verb on the triage card and puts a condition on it — **a life area is required**
/// (tags stay optional, E's call), so "dealt with" always means "and I know where it lives".
///
/// Undo is E's other requirement, and it is why sorting can be one confident tap: every reversible
/// triage action records what it did and what taking it back means.
@MainActor
final class CaptureSortAndUndoTests: XCTestCase {

    private let work = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 1)
    private let health = LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0)

    private func capture(_ content: String, lifeAreaId: UUID? = nil) -> Capture {
        Capture(
            id: UUID(), content: content, kind: .note, processed: false,
            createdAt: Date(), lifeAreaId: lifeAreaId
        )
    }

    private struct SUT {
        let service: CaptureInboxService
        let client: FakeCaptureClientAdapting
    }

    private func makeSUT(loaded: [Capture]) async -> SUT {
        let client = FakeCaptureClientAdapting()
        client.fetchUnprocessedCapturesResult = .success(loaded)
        let service = CaptureInboxService(client: client, transcriber: FakeVoiceTranscribing())
        await service.load()
        return SUT(service: service, client: client)
    }

    // MARK: - The rule: a life area is required

    func testCanSort_needsAnArea_fromTheChipsOrTheCaptureItself() {
        XCTAssertFalse(
            CaptureTriage.canSort(selected: nil, existing: nil),
            "an unfiled capture with no chip picked cannot be sorted — that is the whole point"
        )
        XCTAssertTrue(CaptureTriage.canSort(selected: work.id, existing: nil))
        XCTAssertTrue(
            CaptureTriage.canSort(selected: nil, existing: work.id),
            "a capture filed in the composer is already sorted enough — don't make E re-pick"
        )
    }

    func testResolvedArea_theChipWinsOverWhateverTheCaptureCarried() {
        XCTAssertEqual(CaptureTriage.resolvedArea(selected: health.id, existing: work.id), health.id)
        XCTAssertEqual(CaptureTriage.resolvedArea(selected: nil, existing: work.id), work.id)
        XCTAssertNil(CaptureTriage.resolvedArea(selected: nil, existing: nil))
    }

    /// The chips open on the capture's own area, so an already-filed capture shows where it lives
    /// rather than presenting the choice as unmade.
    func testInitialSelection_isTheCapturesOwnArea() {
        XCTAssertEqual(CaptureTriage.initialSelection(for: capture("x", lifeAreaId: work.id)), work.id)
        XCTAssertNil(CaptureTriage.initialSelection(for: capture("x")))
    }

    // MARK: - Sorting writes one update

    func testSort_writesTheAreaAndTheExitStampTogether() async {
        let noted = capture("Interesting, no action")
        let env = await makeSUT(loaded: [noted, capture("Keep me")])

        let succeeded = await env.service.sort(capture: noted, into: work.id)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(env.client.lastUpdateCaptureId, noted.id)
        XCTAssertEqual(env.client.lastUpdateCaptureChanges?.seen, true)
        XCTAssertEqual(
            env.client.lastUpdateCaptureChanges?.lifeAreaId, .some(work.id),
            "the area and the exit stamp are ONE write — a capture can never be sorted-but-unfiled"
        )
        XCTAssertNotNil(env.client.lastUpdateCaptureChanges?.clearedAt.flatMap { $0 })
        XCTAssertEqual(env.service.captures.map(\.content), ["Keep me"])
    }

    /// Same non-optimistic discipline as every other triage exit: the row leaves only once the
    /// write has landed.
    func testSort_failure_keepsTheRowAndOffersNoUndo() async {
        let noted = capture("Interesting")
        let env = await makeSUT(loaded: [noted])
        env.client.updateCaptureResult = .failure(CaptureServiceError.fetchFailed("offline"))

        let succeeded = await env.service.sort(capture: noted, into: work.id)

        XCTAssertFalse(succeeded)
        XCTAssertEqual(env.service.captures.count, 1)
        XCTAssertNotNil(env.service.triageErrorMessage)
        XCTAssertNil(
            env.service.lastTriageAction,
            "nothing happened, so there must be nothing to take back"
        )
    }

    // MARK: - Undo

    func testSort_recordsWhatItDidAndWhatItWouldTakeBack() async {
        let noted = capture("Interesting", lifeAreaId: health.id)
        let env = await makeSUT(loaded: [noted])

        await env.service.sort(capture: noted, into: work.id)

        XCTAssertEqual(
            env.service.lastTriageAction,
            .sorted(captureId: noted.id, previousLifeAreaId: health.id),
            "undo has to restore the area it REPLACED, not just clear the exit stamp"
        )
    }

    func testUndoSort_reversesTheExitStampAndTheArea() async {
        let noted = capture("Interesting", lifeAreaId: health.id)
        let env = await makeSUT(loaded: [noted])
        await env.service.sort(capture: noted, into: work.id)

        let undone = await env.service.undoLastTriageAction()

        XCTAssertTrue(undone)
        XCTAssertEqual(env.client.lastUpdateCaptureChanges?.seen, false)
        XCTAssertNil(
            env.client.lastUpdateCaptureChanges?.clearedAt.flatMap { $0 },
            "re-entering the inbox deletes the exit stamp (M7)"
        )
        XCTAssertEqual(env.client.lastUpdateCaptureChanges?.lifeAreaId, .some(health.id))
    }

    func testUndoSort_ofACaptureThatHadNoArea_clearsItRatherThanLeavingTheNewOne() async {
        let noted = capture("Interesting")
        let env = await makeSUT(loaded: [noted])
        await env.service.sort(capture: noted, into: work.id)

        await env.service.undoLastTriageAction()

        XCTAssertEqual(
            env.client.lastUpdateCaptureChanges?.lifeAreaId, .some(nil),
            "an undone sort must not leave the area it only just wrote"
        )
    }

    /// One undo, not a repeatable loop — a second tap must not re-reverse anything.
    func testUndo_isSpentOnceUsed() async {
        let noted = capture("Interesting")
        let env = await makeSUT(loaded: [noted])
        await env.service.sort(capture: noted, into: work.id)
        await env.service.undoLastTriageAction()

        XCTAssertNil(env.service.lastTriageAction)
        let secondAttempt = await env.service.undoLastTriageAction()
        XCTAssertFalse(secondAttempt)
    }

    /// The queue is newest-first by default, so skipping the capture at the FRONT is the only
    /// version of this that proves anything — skipping the one already at the back would leave the
    /// order untouched and the assertion would pass on a broken undo.
    func testUndoSkip_putsTheCaptureBackWhereItWas() async throws {
        let env = await makeSUT(loaded: [capture("Older"), capture("Newer")])
        let before = env.service.displayedCaptures.map(\.content)
        let front = try XCTUnwrap(env.service.displayedCaptures.first)
        env.service.skip(front)
        XCTAssertNotEqual(
            env.service.displayedCaptures.map(\.content), before,
            "skipping the front of the queue must actually move it"
        )

        let undone = await env.service.undoLastTriageAction()

        XCTAssertTrue(undone)
        XCTAssertEqual(env.service.displayedCaptures.map(\.content), before)
    }

    func testSkip_recordsAnUndoableAction() async {
        let first = capture("First")
        let env = await makeSUT(loaded: [first, capture("Second")])

        env.service.skip(first)

        XCTAssertEqual(env.service.lastTriageAction, .skipped(captureId: first.id))
    }

    // MARK: - The button only lights up when it can actually be used

    /// E's 2026-08-28 screenshot note: Sorted must be eye-catching ONLY when its requirement is
    /// met. Pinned as a rule rather than left to the view, so the emphasis and the enabled state
    /// can never drift apart and promise something the tap won't deliver.
    func testSortedEmphasis_isReadyExactlyWhenItCanSort() {
        XCTAssertEqual(CaptureTriage.emphasis(selected: nil, existing: nil), .waiting)
        XCTAssertEqual(CaptureTriage.emphasis(selected: work.id, existing: nil), .ready)
        XCTAssertEqual(CaptureTriage.emphasis(selected: nil, existing: work.id), .ready)
    }

    func testSortedEmphasis_neverDisagreesWithCanSort() {
        let cases: [(UUID?, UUID?)] = [
            (nil, nil), (work.id, nil), (nil, work.id), (work.id, health.id)
        ]
        for (selected, existing) in cases {
            XCTAssertEqual(
                CaptureTriage.emphasis(selected: selected, existing: existing) == .ready,
                CaptureTriage.canSort(selected: selected, existing: existing),
                "a glowing button that cannot be tapped is a lie"
            )
        }
    }

    // MARK: - What the undo bar says

    func testConfirmation_namesTheAreaItSortedInto() {
        let line = CaptureTriage.confirmation(
            for: .sorted(captureId: UUID(), previousLifeAreaId: nil),
            sortedInto: work.id,
            lifeAreas: [work, health]
        )

        XCTAssertEqual(line, "Sorted to 💼 Work")
    }

    func testConfirmation_skipSaysItIsComingBack() {
        let line = CaptureTriage.confirmation(
            for: .skipped(captureId: UUID()), sortedInto: nil, lifeAreas: [work]
        )

        XCTAssertEqual(line, "Skipped — it'll come back round")
    }

    /// A deleted area must degrade to a plain sentence, never a raw UUID.
    func testConfirmation_danglingArea_staysReadable() {
        let line = CaptureTriage.confirmation(
            for: .sorted(captureId: UUID(), previousLifeAreaId: nil),
            sortedInto: UUID(),
            lifeAreas: [work]
        )

        XCTAssertEqual(line, "Sorted")
    }
}

/// The Inbox door on the Captures tab. E's answer to where triage should live was "keep the list,
/// make the door louder" — a door that never says how much is behind it is exactly the door E
/// stopped opening.
final class CaptureInboxDoorTests: XCTestCase {

    func testDoorLine_countsWhatIsWaiting() {
        XCTAssertEqual(CaptureInboxSummary.doorLine(count: 3), "3 waiting to triage")
        XCTAssertEqual(CaptureInboxSummary.doorLine(count: 1), "1 waiting to triage")
    }

    /// An empty inbox is the WIN state for an ADHD user, so the door says so rather than "0".
    func testDoorLine_emptyInboxIsAWin() {
        XCTAssertEqual(CaptureInboxSummary.doorLine(count: 0), "Inbox clear")
    }

    /// Never having looked is not the same as nothing being there — the same rule the filter tabs
    /// already follow.
    func testDoorLine_unknownCountSaysNothingAtAll() {
        XCTAssertNil(CaptureInboxSummary.doorLine(count: nil))
    }
}
