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

    // MARK: - The flush drop

    func testCollapsedCardSitsFlushOnTheTabBar() {
        // Derived, never hard-coded: a literal 68 passes today and rots silently the moment the
        // bar's chip height or lift changes. E chose "Drop it flush to the tab bar" over leaving
        // the square bottom corners hanging 100pt up.
        XCTAssertEqual(FocusBarMetrics.expandedBottomLift, AppSearchRowMetrics.bottomFurnitureLift)
        XCTAssertEqual(
            FocusBarMetrics.collapsedBottomLift, AppTabBarMetrics.rowHeight,
            "The collapsed card must clear exactly the tab bar and nothing more — that is what"
                + " \"flush\" means. Any extra and its square bottom corners hang in mid-air."
        )
        XCTAssertEqual(FocusBarMetrics.collapsedDrop, -AppSearchRowMetrics.gapAboveTabBar)
        XCTAssertEqual(
            FocusBarMetrics.collapsedDrop,
            FocusBarMetrics.collapsedBottomLift - FocusBarMetrics.expandedBottomLift,
            "The drop is the DIFFERENCE between the two lifts. Spelling it as its own constant"
                + " lets the two drift apart, which reads on device as a gap under the card."
        )
    }

    /// **The link E spotted between the two changes.** The collapsed card is dropped to a
    /// CONSTANT `rowHeight`, but the tab bar used to move inside that band — lifted 8 at rest and
    /// 4 while scrolled — so the card was flush only at rest and showed a 4pt sliver of page
    /// under its square bottom corners for as long as the page stayed scrolled (the scroll state
    /// is sticky, not transient: it latches past 24pt and releases only at <= 8pt).
    ///
    /// E's 2026-09-09 call to retire the bar's vertical morph closes that gap at the source,
    /// with no cross-component plumbing: with one lift, the band's top IS the card's top in
    /// every state.
    ///
    /// **What this asserts is the METRIC relationship, not the behaviour** — it passed before the
    /// change too, because `rowHeight` was already 68. The behavioural guarantee is
    /// `AppTabBarCallSiteTests.testTheBarsBottomPaddingIsUnconditional`; this one exists so the
    /// two numbers cannot drift apart afterwards.
    func testTheCollapsedCardIsFlushInBothBarStates() {
        XCTAssertEqual(
            FocusBarMetrics.collapsedBottomLift,
            AppTabBarMetrics.cardHeight + AppTabBarMetrics.restingLift,
            "The collapsed card no longer lands on the tab bar's top edge."
        )
        XCTAssertEqual(
            FocusBarMetrics.collapsedBottomLift, AppTabBarMetrics.rowHeight,
            "The band and the card's top have come apart, so the bar moves inside the band again"
                + " and the focus card is flush in only one of the two states."
        )
    }

    func testTheDropMovesTheCardDownNotUp() {
        // The assertion above is an identity between two constants: it passes whether the view
        // ends up moving down 32pt or UP 32pt, and a sign flip would open a 64pt gap that only
        // E's device ever sees. `collapsedDrop` is expressed in LIFT space (less lift = lower);
        // SwiftUI's `.offset(y:)` is the opposite convention, so exactly one negation exists and
        // it lives here.
        XCTAssertGreaterThan(
            FocusBarMetrics.collapsedOffsetY, 0,
            "Positive `y` is DOWNWARD in SwiftUI. A negative offset lifts the collapsed card"
                + " away from the tab bar instead of dropping it flush onto it."
        )
        XCTAssertEqual(FocusBarMetrics.collapsedOffsetY, AppSearchRowMetrics.gapAboveTabBar)
    }

    func testCollapsingActuallyShrinksTheCard() {
        // The entire point of the block, in the `testPillIsActuallySmallerThanTheDisc` mould: a
        // "collapsed" state the same height as the expanded one would pass every wiring test in
        // this arc and get nothing out of the user's way. E picked the 44pt ring + 8pt padding
        // (73pt against 148pt expanded) from measured options on 2026-09-09.
        XCTAssertLessThan(FocusBarMetrics.collapsedRingSize, FocusBarMetrics.expandedRingSize)
        XCTAssertLessThan(
            FocusBarMetrics.collapsedPaddingVertical, FocusBarMetrics.expandedPaddingVertical
        )
        // The ring must not set the collapsed row's height: Pause's 44pt touch floor does, so the
        // collapsed card is the action row E drew a black box over.
        XCTAssertLessThanOrEqual(
            FocusBarMetrics.collapsedRingSize, AppTabBarPresentation.minimumTouchTarget
        )
    }

    func testTheGrabberKeepsItsTouchTargetWithoutSettingTheHeight() {
        // §3's 44pt floor for a 5pt capsule, via the `AppTabBarMetrics.slotHitOverflow` pattern:
        // negative padding around the hit shape, so the grabber's TOUCH area is 44pt while its
        // LAYOUT height stays 5. Give it a real 44pt frame instead and the collapsed card grows
        // by 39pt — back to the height it started at.
        XCTAssertEqual(
            FocusBarMetrics.grabberHitOverflow,
            (AppTabBarPresentation.minimumTouchTarget - FocusBarMetrics.grabberHeight) / 2
        )
        XCTAssertGreaterThan(FocusBarMetrics.grabberHitOverflow, 0)
    }

    // MARK: - What the card actually measures

    /// iPhone 17 Pro's width. The card is full-bleed collapsed, so the width matters.
    private static let screenWidth: CGFloat = 393

    private func measuredHeight(collapsed: Bool) -> CGFloat {
        let service = FocusSessionService()
        service.start(
            taskId: UUID(), taskTitle: "Draft the quarterly review",
            lifeAreaEmoji: "\u{1F4BC}", durationSeconds: 1500, cadence: .count(3)
        )
        service.setCardCollapsed(collapsed)
        let host = UIHostingController(rootView: FocusTimerBar(service: service))
        return host.sizeThatFits(
            in: CGSize(width: Self.screenWidth, height: .greatestFiniteMagnitude)
        ).height
    }

    func testCollapsingHalvesTheCardOnScreen() {
        // **The measurement, not the arithmetic.** Every other test in this file asserts a
        // constant against another constant; this one hosts the real view and asks UIKit how tall
        // it came out. It is the one assertion that would have caught a grabber whose 44pt touch
        // target leaked into the layout, or a chevron frame inflating the collapsed row — both of
        // which pass every metric test while shipping a "collapsed" card the size of the open one.
        let collapsed = measuredHeight(collapsed: true)
        let expanded = measuredHeight(collapsed: false)

        // 73pt is not an approximation of E's choice — it is exactly the option E picked from
        // three measured ones, and the rendered view agrees with the arithmetic to the point:
        //     grabber 5 + spacing 8 + row 44 (Pause's own 44pt floor) + padding 8 x 2 = 73
        XCTAssertEqual(
            collapsed, 73, accuracy: 0.5,
            "The collapsed card measured \(collapsed)pt, not the 73pt E chose. The usual causes"
                + " are the grabber's 44pt touch target leaking into the layout (it must be the"
                + " negative-padding overflow) or the chevron's frame inflating the row."
        )
        // 161, not the 148 this card measured before the block: the grabber is new and present in
        // BOTH states, which costs the expanded card 5pt of capsule plus 8pt of stack spacing.
        // Flagged for E rather than silently absorbed — the record said expanded content was
        // unchanged, and this is the one respect in which it is not.
        XCTAssertEqual(expanded, 161, accuracy: 0.5)
        XCTAssertLessThan(
            collapsed, expanded / 1.8,
            "The collapse no longer roughly halves the card, which is the whole point of it."
        )
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
