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

    /// **The undo moved out of this service in `F-C1-UndoCapsule`.** It used to hold its own
    /// `lastTriageAction`, which both inbox affordances read; E chose "one bottom bar everywhere",
    /// so the slot is the app-level `RecentActionCenter` now and this service only records into it.
    /// These tests therefore assert what was RECORDED and what running its reversal does, which is
    /// strictly more than the old field could say — the capsule's words are checked too.
    /// **The REAL centre, not a double.** The spent-once rule and the put-the-offer-back-on-failure
    /// rule now live there rather than in this service, so a recording double would let these tests
    /// pass on a build where undo looped or where a failed reversal lost its offer. The centre has
    /// its own unit tests; this is where the two halves are checked together.
    private struct SUT {
        let service: CaptureInboxService
        let client: FakeCaptureClientAdapting
        let centre: RecentActionCenter

        /// What the capsule is offering right now, or `nil` if there is nothing to take back.
        @MainActor var pending: RecentAction? { centre.pendingAction }

        /// Takes it back, the way the capsule's Undo button does.
        @MainActor func undo() async {
            await centre.undo()
        }
    }

    private func makeSUT(loaded: [Capture]) async -> SUT {
        let client = FakeCaptureClientAdapting()
        client.fetchUnprocessedCapturesResult = .success(loaded)
        let service = CaptureInboxService(client: client, transcriber: FakeVoiceTranscribing())
        let centre = RecentActionCenter()
        service.recordAction = centre
        await service.load()
        return SUT(service: service, client: client, centre: centre)
    }

    // MARK: - The rule: a life area is required

    func testCanSort_needsAnArea() {
        XCTAssertFalse(
            CaptureTriage.canSort(area: nil),
            "an unfiled capture with no chip picked cannot be sorted — that is the whole point"
        )
        XCTAssertTrue(CaptureTriage.canSort(area: work.id))
    }

    /// With no pick staged the chips open on the capture's own area, so a capture filed in the
    /// composer shows where it lives rather than presenting the choice as unmade — and is already
    /// sorted enough to go.
    func testArea_withNothingStaged_isTheCapturesOwnArea() {
        XCTAssertEqual(CaptureTriage.area(staged: nil, for: capture("x", lifeAreaId: work.id)), work.id)
        XCTAssertNil(CaptureTriage.area(staged: nil, for: capture("x")))
    }

    func testArea_aStagedPickWinsOverWhateverTheCaptureCarried() {
        let filed = capture("x", lifeAreaId: work.id)
        let staged = CaptureTriage.StagedSelection(captureId: filed.id, lifeAreaId: health.id)

        XCTAssertEqual(CaptureTriage.area(staged: staged, for: filed), health.id)
    }

    /// Deselection (E, 2026-08-28: the picker must be unselectable too). A staged record for THIS
    /// capture wins even when it is EMPTY — otherwise tapping the lit chip on an already-filed
    /// capture would spring straight back to its stored area and the choice could never be unmade.
    func testArea_aStagedCLEARWinsToo_soDeselectingAFiledCaptureSticks() {
        let filed = capture("x", lifeAreaId: work.id)
        let cleared = CaptureTriage.StagedSelection(captureId: filed.id, lifeAreaId: nil)

        XCTAssertNil(CaptureTriage.area(staged: cleared, for: filed))
    }

    /// The card is a queue: a pick staged on the previous capture must never leak onto this one.
    func testArea_aStagedPickForADifferentCaptureIsIgnored() {
        let other = CaptureTriage.StagedSelection(captureId: UUID(), lifeAreaId: health.id)

        XCTAssertEqual(CaptureTriage.area(staged: other, for: capture("x", lifeAreaId: work.id)), work.id)
        XCTAssertNil(CaptureTriage.area(staged: other, for: capture("x")))
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
        XCTAssertNil(env.pending, "nothing happened, so there must be nothing to take back")
    }

    // MARK: - Undo

    func testSort_recordsWhatItDidInTheWordsTheCapsuleWillSay() async {
        let noted = capture("Interesting", lifeAreaId: health.id)
        let env = await makeSUT(loaded: [noted])

        await env.service.sort(capture: noted, into: work.id, areaLabel: "💼 Work")

        XCTAssertEqual(env.pending?.kind, .captureSorted(areaLabel: "💼 Work"))
        XCTAssertEqual(env.pending?.subject, "Interesting", "the capsule names the capture, not the verb alone")
    }

    /// The label is resolved by the CALLER at the moment of the sort, so an area deleted before
    /// the undo is taken degrades to the bare verb rather than the capsule quoting a raw id — the
    /// rule the retired inbox bar held, carried over.
    func testSort_withNoResolvableArea_recordsTheBareVerb() async {
        let noted = capture("Interesting")
        let env = await makeSUT(loaded: [noted])

        await env.service.sort(capture: noted, into: work.id)

        XCTAssertEqual(env.pending?.kind, .captureSorted(areaLabel: nil))
    }

    func testUndoSort_reversesTheExitStampAndTheArea() async {
        let noted = capture("Interesting", lifeAreaId: health.id)
        let env = await makeSUT(loaded: [noted])
        await env.service.sort(capture: noted, into: work.id)

        await env.undo()

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

        await env.undo()

        XCTAssertEqual(
            env.client.lastUpdateCaptureChanges?.lifeAreaId, .some(nil),
            "an undone sort must not leave the area it only just wrote"
        )
    }

    /// One undo, not a repeatable loop — a second tap must not re-reverse anything. **The
    /// spent-once rule moved to `RecentActionCenter` with the slot** (`RecentActionCenterTests`
    /// holds it); what this pins is that the service itself declines a repeat, so the guarantee
    /// does not rest on the centre alone.
    func testUndo_isSpentOnceUsed() async {
        let noted = capture("Interesting")
        let env = await makeSUT(loaded: [noted])
        await env.service.sort(capture: noted, into: work.id)
        await env.undo()
        let writesAfterOneUndo = env.client.updateCaptureCallCount

        await env.undo()

        XCTAssertNil(env.pending, "the offer survived being taken")
        XCTAssertEqual(
            env.client.updateCaptureCallCount, writesAfterOneUndo,
            "a second Undo wrote again, so the reversal is a loop rather than a spent offer"
        )
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

        await env.undo()

        XCTAssertEqual(env.service.displayedCaptures.map(\.content), before)
    }

    func testSkip_recordsAnUndoableAction() async {
        let first = capture("First")
        let env = await makeSUT(loaded: [first, capture("Second")])

        env.service.skip(first)

        XCTAssertEqual(env.pending?.kind, .captureSkipped)
        XCTAssertEqual(env.pending?.subject, "First")
    }

    // MARK: - The button only lights up when it can actually be used

    /// E's 2026-08-28 screenshot note: Sorted must be eye-catching ONLY when its requirement is
    /// met. Pinned as a rule rather than left to the view, so the emphasis and the enabled state
    /// can never drift apart and promise something the tap won't deliver.
    func testSortedEmphasis_isReadyExactlyWhenItCanSort() {
        XCTAssertEqual(CaptureTriage.emphasis(area: nil), .waiting)
        XCTAssertEqual(CaptureTriage.emphasis(area: work.id), .ready)
    }

    func testSortedEmphasis_neverDisagreesWithCanSort() {
        for area: UUID? in [nil, work.id, health.id] {
            XCTAssertEqual(
                CaptureTriage.emphasis(area: area) == .ready,
                CaptureTriage.canSort(area: area),
                "a glowing button that cannot be tapped is a lie"
            )
        }
    }

    /// The bug deselection would have introduced if the button read the staged pick and the stored
    /// area as two separate things: the chips would show nothing chosen while Sorted stayed lit.
    /// Both now come from one resolution.
    func testSortedEmphasis_deselectingAFiledCaptureDimsTheButton() {
        let filed = capture("x", lifeAreaId: work.id)
        let cleared = CaptureTriage.StagedSelection(captureId: filed.id, lifeAreaId: nil)

        XCTAssertEqual(
            CaptureTriage.emphasis(area: CaptureTriage.area(staged: cleared, for: filed)),
            .waiting
        )
    }

    // MARK: - What the capsule's verb is built from

    /// **`confirmation(for:sortedInto:lifeAreas:)` was replaced by `areaLabel(id:in:)` in
    /// `F-C1-UndoCapsule`.** It built the retired bar's WHOLE sentence — "Sorted to 💼 Work",
    /// "Skipped — it'll come back round" — because that bar had one line. The capsule carries the
    /// capture's own words on a second line, so the verb is `RecentActionKind.verb`'s job
    /// (`UndoCapsulePresentationTests`) and the area's label is all that is left here.
    func testAreaLabel_namesTheAreaItSortedInto() {
        XCTAssertEqual(CaptureTriage.areaLabel(id: work.id, in: [work, health]), "💼 Work")
    }

    /// A deleted area must degrade to nothing, never a raw UUID — the rule that survived the
    /// replacement, because it is the one that protects the user from seeing an id.
    func testAreaLabel_danglingArea_staysReadable() {
        XCTAssertNil(CaptureTriage.areaLabel(id: UUID(), in: [work]))
        XCTAssertNil(CaptureTriage.areaLabel(id: nil, in: [work]))
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
