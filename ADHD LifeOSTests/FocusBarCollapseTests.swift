//
//  FocusBarCollapseTests.swift
//  ADHD LifeOSTests
//
//  F-FocusCard-1. The collapsible sprint card's pure maths — the swipe's direction rule, the
//  card's top-only rounding, and the flush-drop geometry — plus the collapse flag's round trip
//  through `FocusSprintPersisting`.
//
//  Written before the implementation (`claudecode.md`). Each test's failure message says what a
//  plausible-but-wrong implementation reads, because several of these guard against stubs that
//  pass every OTHER test in the file.
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class FocusBarCollapseTests: XCTestCase {

    // MARK: - The swipe

    func testSwipeDownCollapsesOnlyPastTheThreshold() {
        XCTAssertEqual(
            FocusBarCollapseSwipe.outcome(forTranslation: 40, isCollapsed: false), .collapse,
            "A clear downward drag on an expanded card must collapse it — the screenshot's three"
                + " green arrows point DOWN."
        )
        XCTAssertEqual(
            FocusBarCollapseSwipe.outcome(forTranslation: 4, isCollapsed: false), .none,
            "A 4pt twitch is a tap that wandered. Below the threshold nothing may happen, or the"
                + " card collapses under the user's thumb while they reach for Pause."
        )
        XCTAssertEqual(
            FocusBarCollapseSwipe.outcome(
                forTranslation: FocusBarCollapseSwipe.threshold, isCollapsed: false
            ),
            .collapse,
            "The threshold itself must be inclusive — an exclusive `>` leaves a dead pixel that"
                + " reads on device as an intermittently unresponsive card."
        )
    }

    func testSwipeIsDirectionAwareNotAToggle() {
        // The discriminator for the whole gesture. An implementation that simply flips the flag on
        // any drag past the threshold passes the test above and fails both of these.
        XCTAssertEqual(
            FocusBarCollapseSwipe.outcome(forTranslation: 40, isCollapsed: true), .none,
            "Dragging DOWN on an already-collapsed card expanded it — the swipe is being read as"
                + " a toggle. Down collapses; down again does nothing."
        )
        XCTAssertEqual(
            FocusBarCollapseSwipe.outcome(forTranslation: -40, isCollapsed: false), .none,
            "Dragging UP on an already-expanded card collapsed it. Up expands; up again is a no-op."
        )
        XCTAssertEqual(
            FocusBarCollapseSwipe.outcome(forTranslation: -40, isCollapsed: true), .expand,
            "An upward drag on a collapsed card must expand it — the other half of E's"
                + " \"swipe up and down to switch between the 2 different states\"."
        )
    }

    // MARK: - The card's shape

    /// A 100x100 probe rect at the card's own 24pt radius. The two sampled points are chosen so
    /// that **no single stock shape passes both assertions**: a `RoundedRectangle` fails the
    /// bottom-left one, a plain `Rectangle` fails the top-left one.
    private static let probe = CGRect(x: 0, y: 0, width: 100, height: 100)

    func testCardShapeRoundsOnlyTheTopWhenCollapsed() {
        let path = FocusBarCardShape(cornerRadius: 24, roundsBottomCorners: false).path(in: Self.probe)
        XCTAssertTrue(
            path.contains(CGPoint(x: 1, y: 99)),
            "The collapsed card's BOTTOM-left corner is rounded. It is dropped flush onto the tab"
                + " bar, so a rounded bottom leaves a visible notch of page showing through."
        )
        XCTAssertFalse(
            path.contains(CGPoint(x: 1, y: 1)),
            "The collapsed card's TOP-left corner is square. E chose full-bleed WITH rounded top"
                + " corners over a squared-off strip."
        )
    }

    func testCardShapeRoundsAllFourWhenExpanded() {
        // Proves the flag actually branches rather than being stored and ignored — the stub that
        // always draws the collapsed shape passes the test above on its own.
        let path = FocusBarCardShape(cornerRadius: 24, roundsBottomCorners: true).path(in: Self.probe)
        XCTAssertFalse(
            path.contains(CGPoint(x: 1, y: 99)),
            "`roundsBottomCorners` is being ignored — the expanded card is inset by 16pt on both"
                + " sides and hangs in mid-air, so all four corners must be round."
        )
        XCTAssertFalse(path.contains(CGPoint(x: 1, y: 1)))
    }

    func testInsetShrinksTheShape() {
        // `InsettableShape` is required so the existing `.overlay(shape.strokeBorder(...))` keeps
        // its 1pt border INSIDE the bounds. `inset(by:)` returning `self` — the plausible stub —
        // compiles, conforms, and puts half the stroke outside the card.
        let shape = FocusBarCardShape(cornerRadius: 24, roundsBottomCorners: false)
        let full = shape.path(in: Self.probe).boundingRect
        let inset = shape.inset(by: 4).path(in: Self.probe).boundingRect

        XCTAssertLessThan(inset.width, full.width, "`inset(by:)` did not shrink the shape's width.")
        XCTAssertLessThan(inset.height, full.height, "`inset(by:)` did not shrink the shape's height.")
        XCTAssertEqual(inset.minX, full.minX + 4, accuracy: 0.01)
        XCTAssertEqual(inset.maxY, full.maxY - 4, accuracy: 0.01)
    }

    // MARK: - Collapse survives, and only Confirm clears it

    private final class FakeFocusSprintStore: FocusSprintPersisting {
        var stored: PersistedFocusSprint?
        var unacknowledged: CompletedFocusSession?
        var cardCollapsed = false

        func read() -> PersistedFocusSprint? { stored }
        func write(_ state: PersistedFocusSprint) { stored = state }
        func clear() { stored = nil }
        func readUnacknowledgedCompletion() -> CompletedFocusSession? { unacknowledged }
        func writeUnacknowledgedCompletion(_ record: CompletedFocusSession) { unacknowledged = record }
        func clearUnacknowledgedCompletion() { unacknowledged = nil }
        func readCardCollapsed() -> Bool { cardCollapsed }
        func writeCardCollapsed(_ isCollapsed: Bool) { cardCollapsed = isCollapsed }
    }

    func testAFirstSprintOnAFreshInstallStartsExpanded() {
        // Narrow on purpose, and the name now says so. "Every sprint starts expanded" is TRUE of
        // a fresh install and FALSE across a manual stop — see the test below, which pins the
        // difference deliberately rather than leaving this one's name overclaiming.
        let service = FocusSessionService(sprintStore: FakeFocusSprintStore())
        XCTAssertFalse(service.isCardCollapsed)
    }

    func testAManualStopLeavesTheCardCollapsedIntoTheNextSprint() async {
        // **E chose this knowing the consequence, and it is stated in the design record**: only a
        // NATURAL completion produces a confirmation card, so a manual Stop has nothing to reset
        // collapse — the card stays collapsed into the next sprint until expanded by hand.
        //
        // This test exists so nobody "fixes" it. Expanding on `start()` looks like an obvious
        // improvement, reads as making the collapsed card less sticky, and would quietly overrule
        // a decision E made with the trade-off in front of them. If this behaviour is ever to
        // change it is E's call, not a passing tidy-up's.
        let service = FocusSessionService(sprintStore: FakeFocusSprintStore())
        service.start(taskId: nil, taskTitle: "Draft the review", lifeAreaEmoji: "\u{1F4BC}", durationSeconds: 100)
        service.setCardCollapsed(true)

        await service.stop()
        service.start(taskId: nil, taskTitle: "Second sprint", lifeAreaEmoji: "\u{1F4BC}", durationSeconds: 100)

        XCTAssertTrue(
            service.isCardCollapsed,
            "The card expanded itself on a new sprint. That is a reasonable-looking change and it"
                + " is not this block's to make — E accepted sticky-across-a-stop explicitly, and"
                + " Confirm (F-FocusCard-2) is the only thing that may clear collapse."
        )
    }

    func testClearingTheRunningSprintDoesNotClearCollapse() {
        // The storage half of the same fact: `clear()` drops "focus.sprint.running" and must
        // leave "focus.card.collapsed" alone. Two keys, two lifetimes — the running sprint dies
        // with the stop, the card's posture outlives it until Confirm.
        let store = FakeFocusSprintStore()
        store.cardCollapsed = true
        store.stored = nil
        store.clear()
        XCTAssertTrue(store.cardCollapsed)
    }

    func testCollapseIsPersistedAndRestored() async {
        // A SECOND service over the same store is the whole test: collapse held in `@State`, or
        // in an unpersisted `@Published`, passes a same-instance round trip and loses the state
        // on the next launch. E's requirement is that it survives backgrounding and relaunch.
        let store = FakeFocusSprintStore()
        let first = FocusSessionService(sprintStore: store)
        first.setCardCollapsed(true)
        XCTAssertTrue(store.cardCollapsed, "Collapsing never reached the store.")

        let relaunched = FocusSessionService(sprintStore: store)
        await relaunched.restorePersistedSprint()

        XCTAssertTrue(
            relaunched.isCardCollapsed,
            "The card came back expanded after a relaunch. Collapse memory expires on Confirm"
                + " alone — not on a tab switch, not on backgrounding, not on a cold launch."
        )
    }

    func testCollapseSurvivesWithNoSprintStored() async {
        // The ordering trap. `restorePersistedSprint` returns early at
        // `guard session == nil, let saved = sprintStore.read()`, and NOTHING is stored here —
        // so a collapse read written below that guard never runs. On device that reads as
        // "collapse survives a relaunch only if a sprint happened to be mid-flight", which is
        // most of the time, which is exactly how it would ship.
        let store = FakeFocusSprintStore()
        store.cardCollapsed = true
        store.stored = nil

        let service = FocusSessionService(sprintStore: store)
        await service.restorePersistedSprint()

        XCTAssertTrue(
            service.isCardCollapsed,
            "The collapse read is sitting BELOW the `guard session == nil, let saved =` early"
                + " return in `FocusSessionService+Persistence.swift`. Move it above, beside the"
                + " `offlineCompletionSummary` read."
        )
    }

    func testExpandingIsPersistedToo() {
        // The reverse write. A store that only ever records `true` restores a card the user
        // deliberately expanded straight back to collapsed on the next launch.
        let store = FakeFocusSprintStore()
        let service = FocusSessionService(sprintStore: store)
        service.setCardCollapsed(true)
        service.setCardCollapsed(false)

        XCTAssertFalse(service.isCardCollapsed)
        XCTAssertFalse(store.cardCollapsed, "Expanding never reached the store.")
    }

    func testCollapseWorksWithNoStoreAtAll() {
        // `sprintStore` is optional across this service, and several call sites build one without.
        // Collapse must still toggle in memory rather than trapping on a `nil` store.
        let service = FocusSessionService()
        service.setCardCollapsed(true)
        XCTAssertTrue(service.isCardCollapsed)
    }
}
