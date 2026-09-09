//
//  FocusCompletionCardTests.swift
//  ADHD LifeOSTests
//
//  F-FocusCard-2's view half — the parts of it a unit test can actually reach. The card's body is
//  a SwiftUI view and is out of a unit test's range by construction (CLAUDE.md records this for
//  the whole `View` family); its COPY and its DIMENSIONS are pure, and both are decisions rather
//  than incidentals, so both are held here.
//
//  Also closes a live-store gap F-FocusCard-1 left: `UserDefaultsFocusSprintStore`'s collapse
//  accessors shipped exercised only through the recording fake, so the real UserDefaults round
//  trip — the one the app actually runs — had never been asserted.
//

import XCTest
@testable import ADHD_LifeOS

final class FocusCompletionCardTests: XCTestCase {

    private func record(focusedSeconds: Int, checkpoints: Int) -> CompletedFocusSession {
        CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Draft the review", lifeAreaEmoji: "💼",
            plannedSeconds: 1500, focusedSeconds: focusedSeconds,
            checkpointsReached: checkpoints, completedNaturally: true,
            startedAt: Date(), endedAt: Date()
        )
    }

    // MARK: - The copy

    /// **The whole reason this card does not use the analytics formatter.**
    /// `FocusTimeFormatting.duration(seconds:)` renders 1,530 seconds as "25m"; the user extended
    /// that sprint by +30s and the card is where they find out whether it counted.
    func testTheSummaryKeepsTheSecondsOnAnExtendedSprint() {
        XCTAssertEqual(
            FocusCompletionCard.summaryLine(for: record(focusedSeconds: 1530, checkpoints: 2)),
            "25m 30s focused · 2 checkpoints",
            "The banked seconds were rounded away. `duration(seconds:)` would read \"25m\" here,"
                + " which silently loses the +30s the user deliberately added."
        )
    }

    func testTheSummaryDropsTheCheckpointClauseWhenThereAreNone() {
        XCTAssertEqual(
            FocusCompletionCard.summaryLine(for: record(focusedSeconds: 45, checkpoints: 0)),
            "45s focused",
            "A sprint with no checkpoints must not read \"· 0 checkpoints\"."
        )
    }

    func testTheCheckpointClauseIsSingularForOne() {
        XCTAssertEqual(
            FocusCompletionCard.summaryLine(for: record(focusedSeconds: 900, checkpoints: 1)),
            "15m focused · 1 checkpoint"
        )
    }

    // MARK: - The dimensions

    /// The completion card and the running card are stacked in one column and read as one family,
    /// so every dimension they share is DERIVED rather than re-spelled. A literal here passes
    /// today and rots the moment E moves the running card again — which has already happened
    /// four times in this arc.
    func testTheCardBorrowsTheRunningCardsGeometryRatherThanRestatingIt() {
        XCTAssertEqual(FocusCompletionCardMetrics.inset, FocusBarMetrics.expandedInset)
        XCTAssertEqual(FocusCompletionCardMetrics.cornerRadius, FocusBarMetrics.cornerRadius)
        XCTAssertEqual(FocusCompletionCardMetrics.paddingVertical, FocusBarMetrics.expandedPaddingVertical)
        XCTAssertEqual(
            FocusCompletionCardMetrics.confirmMinHeight, AppTabBarPresentation.minimumTouchTarget,
            "§3's 44pt touch floor is spelled as a literal. Confirm is the ONLY control on this"
                + " card, so it is the last one that should be allowed to drift under it."
        )
    }

    /// The ring is an emblem here, not an instrument — nothing is counting down any more — so it
    /// takes the COLLAPSED card's 44, which is also the Confirm button's height beside it. That
    /// equality is what keeps the card a single 44pt band rather than two mismatched rows.
    func testTheRingIsTheCollapsedSizeNotTheExpandedOne() {
        XCTAssertEqual(FocusCompletionCardMetrics.ringSize, FocusBarMetrics.collapsedRingSize)
        XCTAssertEqual(
            FocusCompletionCardMetrics.ringSize, FocusCompletionCardMetrics.confirmMinHeight,
            "The ring and the Confirm button no longer agree, so one of them now sets the card's"
                + " height on its own and the row stops being a single band."
        )
        XCTAssertLessThan(
            FocusCompletionCardMetrics.ringSize, FocusBarMetrics.expandedRingSize,
            "The completion card took the running card's 64pt countdown ring."
        )
        XCTAssertEqual(
            FocusCompletionCardMetrics.ringLineWidth, FocusBarMetrics.collapsedRingLineWidth,
            "The stroke must thin with the ring, or the arc crowds its own centre."
        )
    }

    // MARK: - The live store, both of F-FocusCard-2's keys and F-FocusCard-1's

    /// Every other test in this arc drives a recording fake. This one drives
    /// `UserDefaultsFocusSprintStore` itself — the class the app actually runs — so an encode or
    /// key mistake in the real implementation has somewhere to fail.
    func testTheLiveStoreRoundTripsTheUnconfirmedStackInOrder() throws {
        let suite = "focus.completion.live.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UserDefaultsFocusSprintStore(defaults: defaults)
        let newest = record(focusedSeconds: 900, checkpoints: 1)
        let oldest = record(focusedSeconds: 600, checkpoints: 0)

        store.writeUnconfirmedCompletions([newest, oldest])

        XCTAssertEqual(
            store.readUnconfirmedCompletions().map(\.id), [newest.id, oldest.id],
            "The stack came back reordered. Newest-first IS the presentation — F-FocusCard-3"
                + " reads a card's depth straight off its index."
        )
    }

    func testTheLiveStoreReadsAnEmptyStackBeforeAnythingIsWritten() throws {
        let suite = "focus.completion.empty.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertTrue(
            UserDefaultsFocusSprintStore(defaults: defaults).readUnconfirmedCompletions().isEmpty,
            "A first launch must read an empty stack, not crash and not carry a stale one."
        )
    }

    /// F-FocusCard-1's own live accessors, never asserted against real UserDefaults until now.
    /// **Both directions matter**: a store that only ever recorded `true` would restore a card
    /// the user deliberately expanded straight back to collapsed on the next launch.
    func testTheLiveStoreRoundTripsCollapseInBothDirections() throws {
        let suite = "focus.collapse.live.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UserDefaultsFocusSprintStore(defaults: defaults)

        XCTAssertFalse(store.readCardCollapsed(), "Every sprint starts EXPANDED.")

        store.writeCardCollapsed(true)
        XCTAssertTrue(store.readCardCollapsed())

        store.writeCardCollapsed(false)
        XCTAssertFalse(
            store.readCardCollapsed(),
            "Expanding was not persisted, so the card collapses again on the next launch."
        )
    }
}
