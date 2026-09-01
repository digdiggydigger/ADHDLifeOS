//
//  PlaceLinkOpeningTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The universal-link opener (F-AppDirectory-2-Links): how a tapped link actually opens.
///
/// The load-bearing pin is SYNCHRONY: the notification tap's FIRST `UIApplication.open` must
/// fire synchronously on the delegate callback (the `0c65ca5` field lesson — any async hop
/// breaks the tap's user-initiated attribution and invites iOS's "wants to open X" dialog).
/// The fallback lives in the completion, where attribution no longer matters: it is the
/// failure path.
final class PlaceLinkOpeningTests: XCTestCase {

    /// Records opens WITHOUT completing them, so a test can hold the completion back and
    /// observe exactly what fired before `run` returned.
    @MainActor
    private final class OpenRecorder {
        private(set) var calls: [(url: URL, universalLinksOnly: Bool)] = []
        private(set) var completions: [(Bool) -> Void] = []
        private(set) var failures: [String] = []

        func opener() -> PlaceLinkOpener {
            PlaceLinkOpener(
                open: { url, universalLinksOnly, completion in
                    self.calls.append((url, universalLinksOnly))
                    self.completions.append(completion)
                },
                notifyFailure: { self.failures.append($0) }
            )
        }
    }

    private let https = URL(string: "https://open.spotify.com/playlist/abc")!
    private let scheme = URL(string: "spotify://")!

    // MARK: - The plan

    func testPlan_webLinksGoUniversalFirst() {
        XCTAssertEqual(PlaceLinkOpenPlan.plan(for: https), .universalFirst(https))
        let http = URL(string: "http://example.com")!
        XCTAssertEqual(PlaceLinkOpenPlan.plan(for: http), .universalFirst(http))
    }

    func testPlan_schemeURLsOpenDirect() {
        XCTAssertEqual(PlaceLinkOpenPlan.plan(for: scheme), .direct(scheme))
        let sms = URL(string: "sms:+44111&body=hi")!
        XCTAssertEqual(PlaceLinkOpenPlan.plan(for: sms), .direct(sms))
    }

    // MARK: - The synchrony pin

    /// The first attempt must have FIRED by the time `run` returns — no async hop.
    @MainActor
    func testRun_firstAttemptFiresBeforeRunReturns() {
        let recorder = OpenRecorder()

        recorder.opener().run(.universalFirst(https), failureBody: "nope")

        XCTAssertEqual(recorder.calls.count, 1, "the first open must be synchronous")
        XCTAssertEqual(recorder.calls[0].url, https)
        XCTAssertTrue(recorder.calls[0].universalLinksOnly, "attempt 1 is universal-links-only")
        XCTAssertTrue(recorder.failures.isEmpty, "no verdict before the attempt completes")
    }

    // MARK: - The universal-first ladder

    @MainActor
    func testRun_universalSuccess_stopsThere() {
        let recorder = OpenRecorder()
        recorder.opener().run(.universalFirst(https), failureBody: "nope")

        recorder.completions[0](true)

        XCTAssertEqual(recorder.calls.count, 1)
        XCTAssertTrue(recorder.failures.isEmpty)
    }

    @MainActor
    func testRun_universalFailure_fallsBackToAPlainOpen() {
        let recorder = OpenRecorder()
        recorder.opener().run(.universalFirst(https), failureBody: "nope")

        recorder.completions[0](false)

        XCTAssertEqual(recorder.calls.count, 2, "failure must fall back, not give up")
        XCTAssertEqual(recorder.calls[1].url, https)
        XCTAssertFalse(recorder.calls[1].universalLinksOnly, "the fallback is a plain open")
        XCTAssertTrue(recorder.failures.isEmpty, "no verdict until the LAST attempt fails")

        recorder.completions[1](true)
        XCTAssertTrue(recorder.failures.isEmpty)
    }

    @MainActor
    func testRun_bothAttemptsFail_notifiesOnce() {
        let recorder = OpenRecorder()
        recorder.opener().run(.universalFirst(https), failureBody: "that didn't open")

        recorder.completions[0](false)
        recorder.completions[1](false)

        XCTAssertEqual(recorder.failures, ["that didn't open"])
    }

    // MARK: - Direct

    @MainActor
    func testRun_directFiresOnePlainOpen_andNotifiesOnlyOnFailure() {
        let succeeding = OpenRecorder()
        succeeding.opener().run(.direct(scheme), failureBody: "nope")
        XCTAssertEqual(succeeding.calls.count, 1)
        XCTAssertFalse(succeeding.calls[0].universalLinksOnly)
        succeeding.completions[0](true)
        XCTAssertTrue(succeeding.failures.isEmpty)

        let failing = OpenRecorder()
        failing.opener().run(.direct(scheme), failureBody: "app may not be installed")
        failing.completions[0](false)
        XCTAssertEqual(failing.failures, ["app may not be installed"])
        XCTAssertEqual(failing.calls.count, 1, "a scheme URL has no web fallback to try")
    }
}
