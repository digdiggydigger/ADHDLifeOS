//
//  FocusCompletionStackLayoutTests.swift
//  ADHD LifeOSTests
//
//  F-FocusCard-3's arithmetic, and — deliberately — its RENDER ORDER too.
//
//  The design record names the `ZStack` order as this block's headline trap: get it wrong and the
//  OLDEST card is in front, while every offset/scale/opacity assertion still passes. That is only
//  true while the order lives inside the view body, where no unit test can reach it. So it does
//  not live there: `drawOrder(for:)` is a pure function returning the layers BACK TO FRONT, the
//  view is a `ForEach` over its output, and the trap becomes an assertion like any other.
//
//  Several of these use STRICT inequalities on purpose. A stub that returns a constant — the
//  plausible half-implementation — satisfies every `<=` in the file and none of the `<`.
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

final class FocusCompletionStackLayoutTests: XCTestCase {

    private func record(_ title: String) -> CompletedFocusSession {
        CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: title, lifeAreaEmoji: "💼",
            plannedSeconds: 600, focusedSeconds: 600, checkpointsReached: 1,
            completedNaturally: true, startedAt: Date(), endedAt: Date()
        )
    }

    // MARK: - The front card

    /// The front card must be untouched: any offset, scale or fade on it is a sign error that
    /// would push the card the user is meant to act on out from under their thumb.
    func testTheFrontCardIsUnoffsetFullScaleAndOpaque() {
        XCTAssertEqual(FocusCompletionStackLayout.yOffset(0), 0, "The front card is displaced.")
        XCTAssertEqual(FocusCompletionStackLayout.scale(0), 1, "The front card is scaled.")
        XCTAssertEqual(FocusCompletionStackLayout.opacity(0), 1, "The front card is faded.")
    }

    // MARK: - The peek

    /// **This is the assertion that pins the stack the right way up, and nothing else catches a
    /// sign flip here.** Negative is UPWARD in SwiftUI, and upward is the only direction
    /// available: the card sits directly on top of the running timer bar, so a stack that peeked
    /// downward would hide its own older cards behind the sprint the user is still running.
    func testThePeekGoesUpwardsSoTheStackCannotShipUpsideDown() {
        XCTAssertLessThan(
            FocusCompletionStackLayout.yOffset(1), 0,
            "The second card peeks BELOW the front one, where the running timer bar is. Negative"
                + " is upward in SwiftUI's coordinate space."
        )
        XCTAssertLessThan(
            FocusCompletionStackLayout.yOffset(2), FocusCompletionStackLayout.yOffset(1),
            "The third card is not further up than the second, so the two deeper layers land on"
                + " each other and the stack reads as two cards, not three."
        )
    }

    /// **The one number in this file that is a DECISION rather than a derivation, so it is the
    /// one place a literal belongs.**
    ///
    /// E chose it on 2026-09-10 by looking at six rendered options side by side
    /// (`screenshots/focus-card-light-peek-options/`), after the shipped 8pt peek proved too
    /// quiet in LIGHT mode on their own device: the sliver measured 1.03:1 against the page, so
    /// the second card was carried entirely by its keyline at 1.30:1.
    ///
    /// **The lever ordering the register carried was wrong, and that is why this is pinned.**
    /// `opacityStep` was named the blunt instrument; it moves the keyline 1.30:1 → 1.35:1, a
    /// change nobody can see, because the layer behind already draws at 0.85. What the eye reads
    /// is the sliver's HEIGHT. Anyone re-tuning this should raise `peekStep` and leave the other
    /// two alone.
    ///
    /// **14 is deliberately OFF §2's 4/8/16/24 grid, and E waived the rule explicitly** rather
    /// than take the on-grid 16 — see the exception recorded in `CLAUDE.md` §2. Do not "correct"
    /// it to a grid value; that would silently undo a decision made by looking.
    func testThePeekStepIsTheValueEChoseByLooking() {
        XCTAssertEqual(
            FocusCompletionStackLayout.peekStep, 14,
            "The peek step moved off the value E chose from rendered options on 2026-09-10."
        )
        XCTAssertEqual(
            FocusCompletionStackLayout.yOffset(1), -14,
            "The second card no longer peeks by the chosen 14pt."
        )
    }

    /// Strict on every step. A `scale(_:)` that returned a constant 0.95 for every depth would
    /// pass a non-strict version of this while rendering all three layers identically.
    func testDeeperCardsShrinkStrictlyAndStayVisible() {
        XCTAssertLessThan(FocusCompletionStackLayout.scale(1), FocusCompletionStackLayout.scale(0))
        XCTAssertLessThan(FocusCompletionStackLayout.scale(2), FocusCompletionStackLayout.scale(1))
        XCTAssertGreaterThan(
            FocusCompletionStackLayout.scale(FocusCompletionStackLayout.maxVisible - 1), 0.8,
            "The deepest drawn card has shrunk past a peeking edge into a visibly different"
                + " object. The stack is a depth cue, not a perspective drawing."
        )
    }

    func testDeeperCardsFadeStrictlyAndStayVisible() {
        XCTAssertLessThan(
            FocusCompletionStackLayout.opacity(1), FocusCompletionStackLayout.opacity(0)
        )
        XCTAssertLessThan(
            FocusCompletionStackLayout.opacity(2), FocusCompletionStackLayout.opacity(1)
        )
        XCTAssertGreaterThan(
            FocusCompletionStackLayout.opacity(FocusCompletionStackLayout.maxVisible - 1), 0,
            "The deepest drawn card is fully transparent, so the layout draws a layer that is not"
                + " there — three cards' worth of cost for two cards' worth of stack."
        )
    }

    // MARK: - Only three layers draw

    /// E ruled out any cap on the DATA — nothing is ever auto-confirmed — so the cap is purely a
    /// drawing one. Ten waiting cards must still be ten records and three layers.
    func testOnlyThreeLayersDrawHoweverManyAreWaiting() {
        XCTAssertEqual(FocusCompletionStackLayout.maxVisible, 3)
        XCTAssertTrue(FocusCompletionStackLayout.isVisible(depth: 0))
        XCTAssertTrue(FocusCompletionStackLayout.isVisible(depth: 2))
        XCTAssertFalse(
            FocusCompletionStackLayout.isVisible(depth: 3),
            "A fourth layer draws. Only three may — the rest are data, waiting their turn."
        )

        let ten = (1...10).map { record("Sprint \($0)") }
        XCTAssertEqual(
            FocusCompletionStackLayout.drawOrder(for: ten).count, 3,
            "The draw order is not capped, so ten waiting completions render ten stacked cards."
        )
    }

    // MARK: - Render order — the block's headline trap

    /// **The ZStack trap, made assertable.** `ZStack` draws later children ON TOP, so a naive
    /// `ForEach(records)` over a newest-first array puts the OLDEST card in front — and every
    /// other test in this file still passes, because the arithmetic is correct and only the
    /// order is wrong.
    func testTheNewestRecordIsDrawnLastAndSoLandsInFront() throws {
        let newest = record("Newest")
        let middle = record("Middle")
        let oldest = record("Oldest")

        let order = FocusCompletionStackLayout.drawOrder(for: [newest, middle, oldest])

        XCTAssertEqual(
            order.map(\.record.taskTitle), ["Oldest", "Middle", "Newest"],
            "The layers are not in back-to-front order. `ZStack` draws later children on top, so"
                + " the newest card — the one E's presentation puts in front — must come LAST."
        )
        let front = try XCTUnwrap(order.last)
        XCTAssertEqual(front.record.id, newest.id)
        XCTAssertTrue(front.isFront, "The last-drawn layer is not the one marked as the front.")
    }

    /// Depth comes out of `drawOrder` rather than being recomputed by the view, so there is one
    /// source for both the order and the offsets. A card's depth IS its index in the service's
    /// newest-first array — that equivalence is what block 2 built this array to give.
    func testDepthIsTheRecordsIndexInTheNewestFirstArray() {
        let records = [record("Newest"), record("Middle"), record("Oldest")]

        let byId = Dictionary(
            uniqueKeysWithValues: FocusCompletionStackLayout.drawOrder(for: records)
                .map { ($0.record.id, $0.depth) }
        )

        XCTAssertEqual(byId[records[0].id], 0, "The newest record is not at depth 0.")
        XCTAssertEqual(byId[records[1].id], 1)
        XCTAssertEqual(byId[records[2].id], 2)
    }

    /// `ForEach` needs an id that survives a removal, or confirming the front card reshuffles the
    /// remaining layers instead of promoting them.
    func testALayersIdentityIsItsRecordsSoRemovalAnimatesRatherThanReshuffles() {
        let records = [record("Newest"), record("Oldest")]

        let order = FocusCompletionStackLayout.drawOrder(for: records)

        XCTAssertEqual(Set(order.map(\.id)), Set(records.map(\.id)))
    }

    func testAnEmptyStackDrawsNothing() {
        XCTAssertTrue(FocusCompletionStackLayout.drawOrder(for: []).isEmpty)
    }

    // MARK: - The peek needs layout space, and `.offset` does not reserve any

    /// **Load-bearing, not polish.** `.offset` moves rendering and hit-testing without touching
    /// layout, so the stack's frame is the FRONT card's alone — the two peeking edges hang
    /// outside it. `RootBottomOverlay`'s VStack spaces its children by 8, so an unreserved
    /// 16pt peek lands the third card's edge on top of the search row above.
    ///
    /// Derived from `yOffset`, never restated: a literal 16 here goes stale the moment E moves
    /// the peek on device, which is exactly what this arc has done at every block.
    func testTheStackReservesTheSpaceItsPeeksHangOutsideItsFrame() {
        XCTAssertEqual(
            FocusCompletionStackLayout.reservedTopPadding(forCount: 3),
            -FocusCompletionStackLayout.yOffset(FocusCompletionStackLayout.maxVisible - 1),
            "The reserved space no longer matches the deepest peek, so either the stack clips"
                + " into the row above it or it reserves a gap nothing occupies."
        )
    }

    /// A single card is not a stack and must not push the furniture above it up by a peek that
    /// is not drawn — the same reasoning that keeps the collapsed running card from reserving
    /// the expanded one's height.
    func testASingleCardReservesNothing() {
        XCTAssertEqual(FocusCompletionStackLayout.reservedTopPadding(forCount: 0), 0)
        XCTAssertEqual(
            FocusCompletionStackLayout.reservedTopPadding(forCount: 1), 0,
            "One waiting card reserves room for a peek that is not drawn, so a lone completion"
                + " card sits higher than the running card it replaces."
        )
        XCTAssertEqual(
            FocusCompletionStackLayout.reservedTopPadding(forCount: 2),
            -FocusCompletionStackLayout.yOffset(1)
        )
    }

    // MARK: - What the stack actually measures

    /// **The measurement, not the arithmetic** — the `testTheCardIsASingle44ptBandInsideItsPadding`
    /// mould. Every assertion above relates one constant to another, all of which hold perfectly
    /// while the view forgets to apply any of them. This one hosts the real stack and asks UIKit,
    /// so a `reservedTopPadding` that is computed and never used has somewhere to fail.
    @MainActor
    func testHostingTheStackReservesTheSpaceTheThreeLayersNeed() {
        let records = (1...3).map { record("Sprint \($0)") }

        let stacked = hostedHeight(of: FocusCompletionCardStack(records: records) { _ in })
        let single = hostedHeight(
            of: FocusCompletionCardStack(records: Array(records.prefix(1))) { _ in }
        )

        XCTAssertEqual(
            single, FocusCompletionCardMetrics.height, accuracy: 0.5,
            "A lone card in the stack is no longer the card E approved in block 2 — the stack is"
                + " adding height to a single completion."
        )
        XCTAssertEqual(
            stacked - single,
            FocusCompletionStackLayout.reservedTopPadding(forCount: 3),
            accuracy: 0.5,
            "The reserved space is computed but not applied, so the two peeking edges hang"
                + " outside the stack's frame and land on the search row above it."
        )
    }

    @MainActor
    private func hostedHeight(of view: some View) -> CGFloat {
        UIHostingController(rootView: view)
            .sizeThatFits(in: CGSize(width: 393, height: CGFloat.greatestFiniteMagnitude))
            .height
    }

    /// Beyond the drawn cap the reservation must stop growing with the data.
    func testTheReservationIsCappedWithTheDrawing() {
        XCTAssertEqual(
            FocusCompletionStackLayout.reservedTopPadding(forCount: 9),
            FocusCompletionStackLayout.reservedTopPadding(forCount: 3),
            "The reserved space keeps growing past the three drawn layers, so a user with nine"
                + " waiting completions gets a gap where the invisible ones would be."
        )
    }
}
