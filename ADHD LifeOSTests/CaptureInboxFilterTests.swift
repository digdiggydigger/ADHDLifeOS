//
//  CaptureInboxFilterTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The Unprocessed / Promoted tab filter, ported from the web inbox's `activeTabFilter`.
///
/// The native inbox could only ever show unprocessed captures, so anything you triaged vanished
/// with no way to look back at it — the web prototype has always had the second tab.
@MainActor
final class CaptureInboxFilterTests: XCTestCase {
    private func capture(_ content: String, processed: Bool) -> Capture {
        Capture(id: UUID(), content: content, kind: .note, processed: processed, createdAt: Date())
    }

    private struct SUT {
        let service: CaptureInboxService
        let client: FakeCaptureClientAdapting
    }

    /// Most of this file exercises the two-filter tab mechanics, so the SUT default keeps a
    /// two-filter service. The app's real screens pass their own lists: the Inbox constructs with
    /// the init default (`[.unprocessed]`, tested below) and the Captures tab with
    /// `[.seen, .promoted]`.
    private func makeSUT(
        unprocessed: [Capture] = [],
        processed: [Capture] = [],
        seen: [Capture] = [],
        availableFilters: [CaptureInboxService.Filter] = [.unprocessed, .promoted]
    ) -> SUT {
        let client = FakeCaptureClientAdapting()
        client.fetchUnprocessedCapturesResult = .success(unprocessed)
        client.fetchProcessedCapturesResult = .success(processed)
        client.fetchSeenCapturesResult = .success(seen)
        return SUT(
            service: CaptureInboxService(
                client: client, transcriber: FakeVoiceTranscribing(), availableFilters: availableFilters
            ),
            client: client
        )
    }

    func testDefaultFilter_isUnprocessed() {
        XCTAssertEqual(makeSUT().service.filter, .unprocessed, "triage is the job; the backlog opens first")
    }

    // MARK: - Display refinement (sort + kind filter)

    func testDisplayedCaptures_honourSortAndKindRefinement() async {
        let older = Capture(
            id: UUID(), content: "older note", kind: .note, processed: false,
            createdAt: Date().addingTimeInterval(-3600)
        )
        let newerLink = Capture(
            id: UUID(), content: "newer link", kind: .link, processed: false, createdAt: Date()
        )
        let env = makeSUT(unprocessed: [newerLink, older])
        await env.service.load()

        XCTAssertEqual(env.service.displayedCaptures.map(\.content), ["newer link", "older note"])

        env.service.sortNewestFirst = false
        XCTAssertEqual(env.service.displayedCaptures.map(\.content), ["older note", "newer link"])

        env.service.kindFilter = .link
        XCTAssertEqual(env.service.displayedCaptures.map(\.content), ["newer link"])
    }

    // MARK: - Which filters a screen offers

    /// The Inbox's default: purely to-triage. Since the Captures tab took over Seen and Promoted,
    /// the Inbox must not fetch either — a count for a tab the screen no longer offers is a
    /// wasted call.
    func testDefaultInit_isTriageOnly_andNeverFetchesTheOtherSlices() async {
        let client = FakeCaptureClientAdapting()
        let service = CaptureInboxService(client: client, transcriber: FakeVoiceTranscribing())

        await service.load()

        XCTAssertEqual(service.filter, .unprocessed)
        XCTAssertEqual(client.fetchProcessedCapturesCallCount, 0)
        XCTAssertEqual(client.fetchSeenCapturesCallCount, 0)
    }

    /// The Captures tab's configuration opens on its first offered filter, not on a hardcoded
    /// `.unprocessed` it doesn't even offer.
    func testInit_startsOnTheFirstOfferedFilter() {
        let env = makeSUT(availableFilters: [.seen, .promoted])

        XCTAssertEqual(env.service.filter, .seen)
    }

    func testLoad_onTheSeenFilter_showsTheSeenArchive() async {
        let env = makeSUT(
            seen: [capture("Noted, nothing to do", processed: false)],
            availableFilters: [.seen, .promoted]
        )

        await env.service.load()

        XCTAssertEqual(env.service.captures.map(\.content), ["Noted, nothing to do"])
        XCTAssertEqual(env.service.counts[.seen], 1)
    }

    /// A filter the screen doesn't offer can't be selected — the picker never shows it, and a
    /// programmatic select must not smuggle it in.
    func testSelect_filterTheScreenDoesNotOffer_isANoOp() async {
        let env = makeSUT(
            unprocessed: [capture("Buy milk", processed: false)],
            availableFilters: [.unprocessed]
        )
        await env.service.load()

        await env.service.select(filter: .promoted)

        XCTAssertEqual(env.service.filter, .unprocessed)
        XCTAssertEqual(env.client.fetchProcessedCapturesCallCount, 0)
    }

    func testLoad_withUnprocessedFilter_showsOnlyWhatStillNeedsTriage() async {
        let env = makeSUT(
            unprocessed: [capture("Buy milk", processed: false)],
            processed: [capture("Already a task", processed: true)]
        )

        await env.service.load()

        XCTAssertEqual(
            env.service.captures.map(\.content), ["Buy milk"],
            "the promoted tab's captures never reach the list, even though its COUNT is now fetched"
        )
    }

    /// The counts behind the filter picker's "To triage (1)" / "Promoted (2)" labels — the web
    /// original puts a number on BOTH tabs, so `load` learns the inactive one's count too.
    func testLoad_learnsTheCountForBothTabs() async {
        let env = makeSUT(
            unprocessed: [capture("Buy milk", processed: false)],
            processed: [capture("Booked it", processed: true), capture("Filed it", processed: true)]
        )

        await env.service.load()

        XCTAssertEqual(env.service.counts[.unprocessed], 1)
        XCTAssertEqual(env.service.counts[.promoted], 2, "the tab you are not on still carries a number")
    }

    /// A count is decoration on a tab the user is not looking at. It must never turn a perfectly
    /// good load into a failure.
    func testLoad_whenTheInactiveTabsFetchFails_stillLoadsAndJustOmitsThatCount() async {
        let env = makeSUT(unprocessed: [capture("Buy milk", processed: false)])
        env.client.fetchProcessedCapturesResult = .failure(CaptureServiceError.fetchFailed("Network error"))

        await env.service.load()

        XCTAssertEqual(env.service.captures.map(\.content), ["Buy milk"])
        XCTAssertEqual(env.service.counts[.unprocessed], 1)
        XCTAssertNil(env.service.counts[.promoted], "unknown, which is not the same as zero")
    }

    func testSelectingPromoted_fetchesAndShowsTriagedCaptures() async {
        let env = makeSUT(
            unprocessed: [capture("Buy milk", processed: false)],
            processed: [capture("Already a task", processed: true)]
        )
        await env.service.load()

        await env.service.select(filter: .promoted)

        XCTAssertEqual(env.service.filter, .promoted)
        XCTAssertEqual(env.service.captures.map(\.content), ["Already a task"])
    }

    func testSwitchingBack_refetchesTheUnprocessedList() async {
        let env = makeSUT(
            unprocessed: [capture("Buy milk", processed: false)],
            processed: [capture("Already a task", processed: true)]
        )
        await env.service.load()
        await env.service.select(filter: .promoted)

        await env.service.select(filter: .unprocessed)

        XCTAssertEqual(env.service.captures.map(\.content), ["Buy milk"])
    }

    func testSelectingTheFilterAlreadyShowing_doesNotRefetch() async {
        let env = makeSUT(unprocessed: [capture("Buy milk", processed: false)])
        await env.service.load()
        let fetchesAfterLoad = env.client.fetchUnprocessedCapturesCallCount

        await env.service.select(filter: .unprocessed)

        XCTAssertEqual(
            env.client.fetchUnprocessedCapturesCallCount, fetchesAfterLoad,
            "re-tapping the active tab is a no-op"
        )
    }

    func testRefresh_honoursTheActiveFilter() async {
        let env = makeSUT(processed: [capture("Already a task", processed: true)])
        await env.service.load()
        await env.service.select(filter: .promoted)

        await env.service.refresh()

        XCTAssertEqual(
            env.service.captures.map(\.content), ["Already a task"],
            "pull-to-refresh must not silently switch tabs"
        )
    }

    func testPromotedFetchFailure_surfacesAsAFailedState() async {
        let env = makeSUT()
        env.client.fetchProcessedCapturesResult = .failure(CaptureServiceError.fetchFailed("offline"))
        await env.service.load()

        await env.service.select(filter: .promoted)

        guard case .failed(let message) = env.service.state else {
            return XCTFail("expected a failed state, got \(env.service.state)")
        }
        XCTAssertEqual(message, "offline")
    }
}
