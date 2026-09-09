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

    /// **E widened it twice.** The first pass took E's marked red lines literally — inset 44,
    /// card 305pt — and E rejected that on device: *"the width of the collapsed bar can be
    /// extended MORE to the left and the right"*. It is now 16, which is also the EXPANDED card's
    /// inset, so **collapsing changes HEIGHT only, not width**.
    ///
    /// That equality is the assertion, and it is deliberate rather than incidental: re-narrowing
    /// the collapsed card is a design change E has already reversed once, so it should fail here
    /// and be taken back to E rather than tuned in passing.
    func testCollapsingChangesHeightOnlyNotWidth() {
        XCTAssertEqual(FocusBarMetrics.collapsedInset, 16, accuracy: 0.01)
        XCTAssertEqual(
            FocusBarMetrics.collapsedInset, FocusBarMetrics.expandedInset,
            "The collapsed card has been re-narrowed. E chose the expanded card's own inset on"
                + " 2026-09-09 after rejecting 44 on device."
        )
        XCTAssertEqual(Self.deviceWidth - FocusBarMetrics.collapsedInset * 2, 361, accuracy: 0.01)
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

    // MARK: - The keyline (E, 2026-09-09: "REMOVE the bottom border on the collapsed card tab")

    /// Sampled through the STROKE, not the path: an open path has no interior, so `contains` on
    /// the path itself answers nothing useful. Stroking it turns the keyline into a fillable
    /// region, and then "is there a border at the bottom edge?" is a real question.
    private func borderCoversBottomEdge(collapsed: Bool) -> Bool {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let stroked = FocusBarCardBorder(cornerRadius: 24, omitsBottomEdge: collapsed)
            .path(in: rect)
            .strokedPath(StrokeStyle(lineWidth: 2))
        return stroked.contains(CGPoint(x: 50, y: 99.5))
    }

    func testTheCollapsedCardHasNoBottomKeyline() {
        XCTAssertFalse(
            borderCoversBottomEdge(collapsed: true),
            "The collapsed card still draws a bottom border. It sits flush on the tab bar, so that"
                + " hairline lands exactly on the join and reads as a seam between two slabs."
        )
    }

    func testTheExpandedCardKeepsAllFourEdges() {
        // The expanded card floats with a 16pt inset on every side — drop its bottom edge and it
        // reads as unfinished. This is the assertion that stops the fix being applied to both.
        XCTAssertTrue(
            borderCoversBottomEdge(collapsed: false),
            "The expanded card lost its bottom border too."
        )
    }

    func testTheBorderStillCoversTheTopEdgeInBothStates() {
        for collapsed in [true, false] {
            let stroked = FocusBarCardBorder(cornerRadius: 24, omitsBottomEdge: collapsed)
                .path(in: CGRect(x: 0, y: 0, width: 100, height: 100))
                .strokedPath(StrokeStyle(lineWidth: 2))
            XCTAssertTrue(
                stroked.contains(CGPoint(x: 50, y: 0.5)),
                "The top keyline is missing (collapsed: \(collapsed)) — only the BOTTOM edge goes."
            )
        }
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

        // **60pt — the tab bar's own height exactly, and E's pick.** The 73pt version drew "way
        // too tall!"; the fix was the grabber moving into the top padding (-13pt), which is worth
        // the whole difference on its own. E then chose to spend the freed room on LEGIBILITY
        // rather than take it as more height: the ring went back to the 44pt originally picked
        // and the Pause glyph grew, once the chevron and PAUSED badge left the collapsed row.
        XCTAssertEqual(collapsed, 60, accuracy: 1)
        XCTAssertLessThanOrEqual(
            collapsed, AppTabBarMetrics.cardHeight,
            "The collapsed card is TALLER than the tab bar beneath it — the 73pt state E rejected"
                + " as \"way too tall\". Matching the bar is E's chosen ceiling, exceeding it is not."
        )
        // Back to 148, the height this card was BEFORE the arc started. The grabber briefly cost
        // the expanded card 13pt as a stack child; as an overlay in the padding it costs nothing.
        XCTAssertEqual(expanded, 148, accuracy: 0.5)
        XCTAssertLessThan(
            collapsed, expanded / 1.8,
            "The collapse no longer roughly halves the card, which is the whole point of it."
        )
    }
}
