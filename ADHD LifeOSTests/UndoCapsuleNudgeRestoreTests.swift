//
//  UndoCapsuleNudgeRestoreTests.swift
//  ADHD LifeOSTests
//
//  `F-C1-UndoCapsule`, E's Step 0 answer 3: *"Yes, a nudge dismiss gets the capsule"*. That is the
//  one close surface in the arc that needed a NEW write — `unmarkFired` — because nothing in the
//  app had ever taken a "Done for now" back.
//
//  **It restores rather than decrements, and that is what these tests are mostly about.** Popping
//  the last entry off `completion_dates` and guessing a new `last_fired_at` would be wrong for any
//  nudge whose previous firing was not the last stamp, and would have no answer at all for one
//  that had never fired before. So the caller hands over the document as it stood BEFORE, and the
//  write puts it back.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class UndoCapsuleNudgeRestoreTests: XCTestCase {

    // MARK: - The service

    func testDismissingRecordsAnUndoNamedAfterTheNudge() async {
        let env = await loadedService(nudge: Self.nudge())

        await env.sut.dismiss(Self.nudge())

        XCTAssertNotNil(env.centre.pendingAction, "A \"Done for now\" recorded no undo.")
        XCTAssertEqual(env.centre.pendingAction?.kind, .nudgeDismissed)
        XCTAssertEqual(env.centre.pendingAction?.subject, "Take the meds")
    }

    func testTheRecordedUndoRestoresTheStampsTheNudgeHadBefore() async {
        let fired = Date(timeIntervalSince1970: 1_700_000_000)
        let before = Self.nudge(lastFiredAt: fired, completionDates: [fired])
        let env = await loadedService(nudge: before)
        await env.sut.dismiss(before)

        await env.centre.undo()

        XCTAssertEqual(env.client.unmarkFiredCallCount, 1, "The undo never wrote.")
        XCTAssertEqual(env.client.lastUnmarkFiredArguments?.previousLastFiredAt, fired)
        XCTAssertEqual(env.client.lastUnmarkFiredArguments?.previousCompletionDates, [fired])
    }

    /// A nudge dismissed for the FIRST time has no previous firing, so the restore must clear the
    /// field rather than invent a moment. `nil` is what the payload turns into `FieldValue.delete()`.
    func testRestoringANudgeThatHadNeverFiredHandsOverNoPreviousMoment() async {
        let before = Self.nudge(lastFiredAt: nil, completionDates: nil)
        let env = await loadedService(nudge: before)
        await env.sut.dismiss(before)

        await env.centre.undo()

        XCTAssertNil(env.client.lastUnmarkFiredArguments?.previousLastFiredAt)
        XCTAssertEqual(env.client.lastUnmarkFiredArguments?.previousCompletionDates, [])
    }

    func testAFailedRestoreSurfacesItsErrorAndLeavesTheListAlone() async {
        let before = Self.nudge()
        let env = await loadedService(nudge: before)
        env.client.unmarkFiredResult = .failure(NudgesServiceError.notFound)

        let restored = await env.sut.restore(before)

        XCTAssertFalse(restored)
        XCTAssertEqual(env.sut.errorMessage, NudgesServiceError.notFound.errorDescription)
    }

    // MARK: - The payload

    func testTheUnfiredPayloadRestoresBothStampsInTheStoredSpellings() {
        let previous = Date(timeIntervalSince1970: 1_700_000_000)
        let now = Date(timeIntervalSince1970: 1_700_009_999)

        let fields = FirestoreFieldPayloads.nudgeUnfired(
            previousLastFiredAt: previous, completionDates: [previous], now: now
        )

        XCTAssertEqual(fields.keys.sorted(), ["completion_dates", "last_fired_at", "updated_at"])
        XCTAssertEqual(FirestoreDocumentCoder.date(from: fields["last_fired_at"]), previous)
        XCTAssertEqual(FirestoreDocumentCoder.date(from: fields["updated_at"]), now)
        XCTAssertEqual(
            (fields["completion_dates"] as? [Any])?.compactMap { FirestoreDocumentCoder.date(from: $0) },
            [previous]
        )
        XCTAssertNil(fields["lastFiredAt"], "The camelCase spelling would write a field nothing reads.")
        XCTAssertNil(fields["completionDates"], "The camelCase spelling would write a field nothing reads.")
        XCTAssertFalse(
            FirestoreDocumentCoder.isServerTimestamp(fields["updated_at"]),
            "An undo pins its instant client-side, the same as the firing it reverses."
        )
    }

    /// The one case a decrement could not express: a nudge that had never fired. The field is
    /// CLEARED, not written as a null — `FieldValue.delete()` is how this codebase says "remove
    /// the field", the same rule `captureReturnedToInbox` follows for `clearedAt`.
    func testAnUnfiredNudgeHasItsLastFiredStampDeletedRatherThanWritten() {
        let fields = FirestoreFieldPayloads.nudgeUnfired(
            previousLastFiredAt: nil, completionDates: [], now: Date()
        )

        XCTAssertNotNil(fields["last_fired_at"], "The field is untouched, so the stamp survives the undo.")
        XCTAssertTrue(
            FirestoreDocumentCoder.isFieldDelete(fields["last_fired_at"]),
            "A moment was written for a nudge that had never fired."
        )
        XCTAssertEqual((fields["completion_dates"] as? [Any])?.count, 0)
    }

    // MARK: - Helpers

    private static func nudge(
        lastFiredAt: Date? = Date(timeIntervalSince1970: 1_700_000_000),
        completionDates: [Date]? = [Date(timeIntervalSince1970: 1_700_000_000)]
    ) -> Nudge {
        Nudge(
            id: Self.id, label: "Take the meds", schedule: "0 9 * * *", active: true,
            lastFiredAt: lastFiredAt, completionDates: completionDates,
            createdAt: Date(timeIntervalSince1970: 1), updatedAt: Date()
        )
    }

    private static let id = UUID()

    private struct SUT {
        let sut: NudgesService
        let client: FakeNudgesClientAdapting
        /// The app's one undo slot — the real one, since the spent-once rule lives there.
        let centre: RecentActionCenter
    }

    private func loadedService(nudge: Nudge) async -> SUT {
        let client = FakeNudgesClientAdapting()
        client.fetchNudgesResult = .success([nudge])
        let centre = RecentActionCenter()
        let service = NudgesService(
            client: client, notificationSchedulingClient: FakeNudgeNotificationSchedulingAdapting()
        )
        service.recordAction = centre
        await service.load()
        return SUT(sut: service, client: client, centre: centre)
    }
}
