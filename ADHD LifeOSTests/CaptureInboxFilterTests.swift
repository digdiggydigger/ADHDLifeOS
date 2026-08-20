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

    private func makeSUT(unprocessed: [Capture] = [], processed: [Capture] = []) -> SUT {
        let client = FakeCaptureClientAdapting()
        client.fetchUnprocessedCapturesResult = .success(unprocessed)
        client.fetchProcessedCapturesResult = .success(processed)
        return SUT(
            service: CaptureInboxService(client: client, transcriber: FakeVoiceTranscribing()),
            client: client
        )
    }

    func testDefaultFilter_isUnprocessed() {
        XCTAssertEqual(makeSUT().service.filter, .unprocessed, "triage is the job; the backlog opens first")
    }

    func testLoad_withUnprocessedFilter_showsOnlyWhatStillNeedsTriage() async {
        let env = makeSUT(unprocessed: [capture("Buy milk", processed: false)])

        await env.service.load()

        XCTAssertEqual(env.service.captures.map(\.content), ["Buy milk"])
        XCTAssertEqual(
            env.client.fetchProcessedCapturesCallCount, 0,
            "the promoted tab must not be fetched until it is asked for"
        )
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
