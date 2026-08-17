//
//  CaptureInboxLifeAreaRaceTests.swift
//  ADHD LifeOSTests
//
//  Pins the SERVICE-LEVEL contract behind the Life-Area PATCH race fix (the FIX block that is a
//  follow-on to 345233b). The race itself lives in `CaptureRowView`'s @State, which is not
//  unit-testable by this project's established precedent — that half is verified by driving the
//  simulator and reported separately. What IS pinnable here is `updateLifeArea`'s return contract
//  (false on throw, true on success) and that two overlapping PATCHes each resolve to THEIR OWN
//  outcome regardless of completion order — the invariant the view's cancellation guard depends on.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CaptureInboxLifeAreaRaceTests: XCTestCase {

    private func capture() -> Capture {
        Capture(id: UUID(), content: "Buy milk", kind: .note, processed: false, createdAt: Date())
    }

    // MARK: - Queued fail-then-succeed return contract

    func testUpdateLifeArea_queuedFailThenSucceed_returnValuesFollowTheQueue() async {
        let cap = capture()
        let fake = SequencedCaptureClientFake(defaultUpdateOutcome: .success(cap))
        let succeeded = Capture(
            id: cap.id, content: cap.content, kind: cap.kind, processed: false,
            createdAt: cap.createdAt, lifeAreaId: UUID()
        )
        fake.enqueueUpdateOutcomes([
            .failure(CaptureServiceError.fetchFailed("Network error")),
            .success(succeeded)
        ])
        let sut = CaptureInboxService(client: fake)

        let first = await sut.updateLifeArea(capture: cap, lifeAreaId: UUID())
        let second = await sut.updateLifeArea(capture: cap, lifeAreaId: UUID())

        XCTAssertFalse(first, "the queued failure must return false")
        XCTAssertTrue(second, "the queued success must return true")
        XCTAssertEqual(fake.updateCaptureCallCount, 2)
    }

    // MARK: - Overlapping calls, first fails LAST

    /// The exact shape of acceptance-criterion 1: two rapid changes where the FIRST (superseded)
    /// PATCH fails and the SECOND succeeds — and, harder, the first resolves *after* the second.
    /// Each call must still report its own outcome. The view layer then uses these return values,
    /// plus its `Task.isCancelled` guard, to ensure the superseded failure never moves the picker;
    /// that view behaviour is verified in the simulator, not here.
    func testUpdateLifeArea_overlapping_firstFailsAfterSecondSucceeds_eachReportsOwnOutcome() async {
        let cap = capture()
        let v2Committed = Capture(
            id: cap.id, content: cap.content, kind: cap.kind, processed: false,
            createdAt: cap.createdAt, lifeAreaId: UUID()
        )
        let fake = SequencedCaptureClientFake(defaultUpdateOutcome: .success(cap))
        fake.enqueueUpdateOutcomes([
            .failure(CaptureServiceError.fetchFailed("Network error")), // call #1 → the superseded pick
            .success(v2Committed)                                        // call #2 → the winning pick
        ])
        fake.hold(callOrdinal: 1) // park the first PATCH in-flight

        let sut = CaptureInboxService(client: fake)

        async let firstResult = sut.updateLifeArea(capture: cap, lifeAreaId: UUID())
        await fake.waitUntilStarted(callOrdinal: 1) // guarantee #1 is genuinely in-flight
        let second = await sut.updateLifeArea(capture: cap, lifeAreaId: UUID()) // #2 runs to completion first
        fake.release(callOrdinal: 1)                                            // now let #1 fail, last
        let first = await firstResult

        XCTAssertFalse(first, "the superseded PATCH still resolves to false even though it finished last")
        XCTAssertTrue(second, "the later PATCH succeeded")
        XCTAssertEqual(fake.updateCaptureCallCount, 2)
        XCTAssertEqual(fake.updateStartOrder, [cap.id, cap.id], "both PATCHes targeted the same capture")
    }

    // MARK: - Single failure still surfaces the triage error (no 345233b regression)

    func testUpdateLifeArea_singleFailure_returnsFalseAndSurfacesTriageError() async {
        let cap = capture()
        let fake = SequencedCaptureClientFake(defaultUpdateOutcome: .success(cap))
        fake.enqueueUpdateOutcomes([.failure(CaptureServiceError.fetchFailed("Network error"))])
        let sut = CaptureInboxService(client: fake)

        let result = await sut.updateLifeArea(capture: cap, lifeAreaId: UUID())

        XCTAssertFalse(result)
        XCTAssertEqual(sut.triageErrorMessage, "Network error")
    }
}
