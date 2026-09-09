//
//  FocusBarGeometryTests.swift
//  ADHD LifeOSTests
//
//  Split out of `FocusBarCollapseTests` when that file hit SwiftLint's 400-line ceiling, on a
//  real seam rather than an arbitrary cut: everything here is about where the collapsed card
//  SITS and how big it is — the flush drop onto the tab bar, the width E marked on 2026-09-09,
//  and the one test that hosts the real view and measures it. The behavioural half (the swipe's
//  direction rule, the card's shape, and collapse surviving a relaunch) stayed behind.
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class FocusBarGeometryTests: XCTestCase {

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

    // MARK: - E's marked width (2026-09-09)

    /// iPhone 15/17 Pro. The tab bar divides the same width the bottom overlay does — it is a
    /// bottom `safeAreaInset` on the very view carrying the overlay, and a bottom inset does not
    /// change horizontal width.
    private static let deviceWidth: CGFloat = 393

    private static func tabBarCardWidth(inset: CGFloat) -> CGFloat {
        deviceWidth - inset * 2
    }

    /// **E's call, 2026-09-09, from a marked-up screenshot**: the collapsed card must *"stop being
    /// total full-screen-width and become smaller than the nav bar below it"*. This is the whole
    /// requirement, and it has to hold in BOTH bar states — the bar's own width still morphs
    /// (`restingInset` 4 → `floatingInset` 8), so a card that cleared only the narrower one would
    /// sit proud of the bar at rest.
    func testTheCollapsedCardIsNarrowerThanTheTabBarInBothStates() {
        let card = Self.deviceWidth - FocusBarMetrics.collapsedInset * 2
        XCTAssertLessThan(
            card, Self.tabBarCardWidth(inset: AppTabBarMetrics.restingInset),
            "The collapsed card is wider than the RESTING tab bar, so it overhangs the bar it is"
                + " supposed to sit on — the full-bleed problem E rejected, just less of it."
        )
        XCTAssertLessThan(
            card, Self.tabBarCardWidth(inset: AppTabBarMetrics.floatingInset),
            "The collapsed card is wider than the SCROLLED tab bar."
        )
    }

    /// E drew the width as two red lines at **41.8pt and 348.7pt** (width 306.8pt). Measured
    /// against the same screenshot, those land on the first and last tab ICON centres — 42.5 and
    /// 350.2 — and the bar's own constants predict 42.75 / 350.25 for the scrolled state.
    ///
    /// **Spelled as a constant, not derived from the slot geometry, and that is deliberate.** The
    /// alignment E's marks happen to hit exists only while the bar is SCROLLED: at rest the
    /// selected tab renders as a pill with an intrinsic width (`maximumRestingPillWidth`), so the
    /// six slots are unequal and the outer icon centres move with the SELECTION — roughly 34pt
    /// with a middle tab selected, ~59pt with Today selected. No constant, and no `isFloating`
    /// morph, can track that. So the width is the requirement and the alignment is a coincidence
    /// of the state E screenshotted; 44 is E's number to within 1.25pt and sits on §2's grid.
    func testTheCollapsedInsetIsEsMarkedWidth() {
        XCTAssertEqual(FocusBarMetrics.collapsedInset, 44, accuracy: 0.01)
        let width = Self.deviceWidth - FocusBarMetrics.collapsedInset * 2
        XCTAssertEqual(
            width, 306.8, accuracy: 3,
            "The collapsed card is no longer the width E marked (306.8pt on a 393pt screen)."
        )
    }

    /// It must not become an inset card and keep the expanded card's inset — the two are
    /// different numbers for different jobs, and collapsing has to be a visible change of width.
    func testTheTwoStatesUseDifferentInsets() {
        XCTAssertGreaterThan(FocusBarMetrics.collapsedInset, FocusBarMetrics.expandedInset)
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
}
