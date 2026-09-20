//
//  RecentActionCenterTests.swift
//  ADHD LifeOSTests
//
//  `F-C1-UndoCapsule`: the one slot behind the undo capsule.
//
//  **The cross-kind collision is asserted, not merely documented.** E's round-2 choice was "one
//  bottom bar everywhere", and one bar means one slot — so closing a task after sorting a capture
//  spends the capture's undo. That is a real behaviour change and the test below is where it is
//  pinned, so a later block cannot quietly give a second kind its own slot and call it a fix.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class RecentActionCenterTests: XCTestCase {

    // MARK: - Recording

    func testRecordingPutsTheActionInTheOneSlot() {
        let center = RecentActionCenter()
        XCTAssertNil(center.pendingAction, "The slot starts empty, so nothing offers an undo on launch.")

        center.record(Self.action(kind: .taskClosed, subject: "Pay the council tax instalment"))

        XCTAssertEqual(center.pendingAction?.kind, .taskClosed)
        XCTAssertEqual(center.pendingAction?.subject, "Pay the council tax instalment")
    }

    /// E's "one bottom bar everywhere", read onto the code: a task close SPENDS a pending capture
    /// undo, and the reverse. The slot holds the newest action whatever kind it is.
    func testANewRecordReplacesAPendingOneWhateverKindItIs() {
        let center = RecentActionCenter()
        var capturesReversed = 0
        center.record(
            Self.action(kind: .captureSorted(areaLabel: "💼 Work"), subject: "Bike repair receipt") {
                capturesReversed += 1
            }
        )

        center.record(Self.action(kind: .taskClosed, subject: "Call Mum back"))

        XCTAssertEqual(center.pendingAction?.kind, .taskClosed, "The newest action owns the one slot.")
        XCTAssertEqual(
            capturesReversed, 0,
            "Replacing a pending action must not RUN its reversal — the undo is spent, not taken."
        )
    }

    // MARK: - Undo

    func testUndoRunsTheRecordedReversalAndEmptiesTheSlot() async {
        let center = RecentActionCenter()
        let reversals = Counter()
        center.record(Self.action(kind: .taskClosed, subject: "Call Mum back") { reversals.bump() })

        await center.undo()

        XCTAssertEqual(reversals.count, 1, "Undo did not run the reversal the site recorded.")
        XCTAssertNil(center.pendingAction, "The slot is empty once its undo has been taken.")
    }

    func testUndoIsSpentOnceSoASecondTapReversesNothing() async {
        let center = RecentActionCenter()
        let reversals = Counter()
        center.record(Self.action(kind: .taskClosed, subject: "Call Mum back") { reversals.bump() })

        await center.undo()
        await center.undo()

        XCTAssertEqual(
            reversals.count, 1,
            "A second Undo re-ran the reversal — the capsule would re-close the task it just reopened."
        )
    }

    func testUndoWithAnEmptySlotRunsNothing() async {
        let center = RecentActionCenter()
        await center.undo()
        XCTAssertNil(center.pendingAction)
    }

    func testOnlyTheNEWESTReversalIsEverRun() async {
        let center = RecentActionCenter()
        let firstReversals = Counter()
        let secondReversals = Counter()
        center.record(Self.action(kind: .captureSkipped, subject: "Old one") { firstReversals.bump() })
        center.record(Self.action(kind: .taskClosed, subject: "New one") { secondReversals.bump() })

        await center.undo()

        XCTAssertEqual(firstReversals.count, 0, "The replaced action's reversal ran — the slot kept a stale closure.")
        XCTAssertEqual(secondReversals.count, 1)
    }

    /// **A reversal that could not land puts its offer back.** The Capture Inbox has always
    /// promised this — *"nothing happened, so the offer still stands"* — and for "Journal it" it is
    /// a safety argument rather than a nicety: a failed restore deliberately leaves the journal
    /// entry alone, because it is the only copy of the thought left, so the user must be able to
    /// try again.
    func testAReversalThatDeclinesPutsTheOfferBack() async {
        let center = RecentActionCenter()
        let action = Self.action(kind: .captureJournalled, subject: "Rain smelled like school", reversed: false)
        center.record(action)

        await center.undo()

        XCTAssertEqual(center.pendingAction, action, "A failed undo left the user with no way to retry.")
    }

    /// …but only into a slot nothing else has claimed. A reversal takes a network round trip, and
    /// a close made while it was in flight owns the capsule now — restoring over it would show an
    /// undo for something two actions ago.
    func testAFailedReversalNeverEvictsAnActionRecordedWhileItWasInFlight() async {
        let center = RecentActionCenter()
        let slow = RecentAction(kind: .captureSkipped, subject: "Old one") {
            center.record(Self.action(kind: .taskClosed, subject: "Closed meanwhile"))
            return false
        }
        center.record(slow)

        await center.undo()

        XCTAssertEqual(center.pendingAction?.subject, "Closed meanwhile")
    }

    // MARK: - Clearing

    func testClearEmptiesTheSlotWithoutRunningTheReversal() {
        let center = RecentActionCenter()
        let reversals = Counter()
        center.record(Self.action(kind: .taskClosed, subject: "Call Mum back") { reversals.bump() })

        center.clear()

        XCTAssertNil(center.pendingAction)
        XCTAssertEqual(reversals.count, 0, "Clearing is dismissal, not undo — it must never reverse anything.")
    }

    // MARK: - Identity

    /// The capsule keys its transition on the action, so two DIFFERENT closes must not compare
    /// equal just because they are both `.taskClosed` — the second would slide in silently.
    func testTwoRecordingsOfTheSameKindAreDistinctActions() {
        let center = RecentActionCenter()
        center.record(Self.action(kind: .taskClosed, subject: "One"))
        let first = center.pendingAction
        center.record(Self.action(kind: .taskClosed, subject: "One"))

        XCTAssertNotEqual(first, center.pendingAction, "Two separate closes share one identity.")
    }

    // MARK: - Helpers

    private static func action(
        kind: RecentActionKind, subject: String, reversed: Bool = true, undo: @escaping () -> Void = {}
    ) -> RecentAction {
        RecentAction(kind: kind, subject: subject) {
            undo()
            return reversed
        }
    }

    /// A reference box, so a `@Sendable` reversal closure can count itself without capturing a
    /// `var` the compiler will not let it mutate.
    private final class Counter {
        private(set) var count = 0
        func bump() { count += 1 }
    }
}
