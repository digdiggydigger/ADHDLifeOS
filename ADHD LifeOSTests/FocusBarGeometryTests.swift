//
//  FocusBarGeometryTests.swift
//  ADHD LifeOSTests
//
//  Split out of `FocusBarCollapseTests` when that file hit SwiftLint's 400-line ceiling, on a
//  real seam rather than an arbitrary cut: everything here is about where the collapsed card
//  SITS and how big it is — its line above the tab bar (the flush drop until E reversed it on
//  2026-09-17), the width E marked on 2026-09-09,
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

        // F-FocusCard-2's second widening. See `FocusCompletionStackServiceTests`.
        var unconfirmed: [CompletedFocusSession] = []
        func readUnconfirmedCompletions() -> [CompletedFocusSession] { unconfirmed }
        func writeUnconfirmedCompletions(_ records: [CompletedFocusSession]) { unconfirmed = records }
    }

    // MARK: - The line (the flush drop, REVERSED 2026-09-17)

    /// **REVERSED by E on 2026-09-17 — `F-CollapsedBarLift`.** This test was
    /// `testCollapsedCardSitsFlushOnTheTabBar`: the collapsed card lifted only
    /// `AppTabBarMetrics.rowHeight`, 32pt less than the expanded one, so it sat ON the bar. E chose
    /// that on 2026-09-09 — *"Drop it flush to the tab bar"* over leaving square bottom corners
    /// hanging 100pt up — and kept it through `F-FocusCard-Corners` (*"the flush drop STAYS"*).
    ///
    /// Looking at it in landscape on 2026-09-17, E asked for the opposite: *"it needs to have some
    /// margin space added BELOW The card bottom-left AND ABOVE The NAV tap menu bar"*; then, offered
    /// landscape only, *"Portrait too"*; and for how much, *"Line up with the Disc, But when there
    /// are multiple cards being displayed, then maintain the alignment."*
    ///
    /// So there is ONE lift, in both states: the disc's resting line, `bottomFurnitureLift`, which
    /// clears the tab bar by the 32pt E measured for the disc. The claim is reversed rather than
    /// deleted, and its name with it, so the history reads.
    func testTheCollapsedCardSitsOnTheDiscsLineNotOnTheTabBar() {
        XCTAssertEqual(
            FocusBarMetrics.bottomLift, AppSearchRowMetrics.bottomFurnitureLift,
            "The card's line is not the disc's line, so it no longer lines up with the disc."
        )
        XCTAssertEqual(
            FocusBarMetrics.bottomLift - AppTabBarMetrics.rowHeight, AppSearchRowMetrics.gapAboveTabBar,
            "The card does not clear the tab bar by the disc's 32pt margin."
        )
        XCTAssertGreaterThan(
            FocusBarMetrics.bottomLift, AppTabBarMetrics.rowHeight,
            "The card sits on the tab bar again — the flush drop E reversed on 2026-09-17."
        )
    }

    /// **The link E spotted between the two changes, and it still holds the other way round.** The
    /// tab bar used to move inside its band — lifted 8 at rest and 4 while scrolled — so the old
    /// flush card was flush only at rest and showed a 4pt sliver of page under it while scrolled.
    /// E's 2026-09-09 call retired the bar's vertical morph, so the band's top IS the bar's top in
    /// every state.
    ///
    /// **REVERSED 2026-09-17 with the test above** (it was `testTheCollapsedCardIsFlushInBothBarStates`):
    /// what must now hold in both bar states is the MARGIN, not flushness — a bar that moved inside
    /// its band again would make E's 32pt read 28 while scrolled. This asserts the metric
    /// relationship; `AppTabBarCallSiteTests.testTheBarsBottomPaddingIsUnconditional` is the
    /// behaviour.
    func testTheMarginAboveTheTabBarIsTheSameInBothBarStates() {
        XCTAssertEqual(
            AppTabBarMetrics.rowHeight, AppTabBarMetrics.cardHeight + AppTabBarMetrics.restingLift,
            "The band and the bar's top have come apart, so the bar moves inside the band again."
        )
        XCTAssertEqual(
            FocusBarMetrics.bottomLift - (AppTabBarMetrics.cardHeight + AppTabBarMetrics.restingLift),
            AppSearchRowMetrics.gapAboveTabBar,
            "The margin under the collapsed card is not E's 32pt against the bar's own top."
        )
    }

    /// **REVERSED 2026-09-17** (it was `testTheDropMovesTheCardDownNotUp`). That test guarded the
    /// flush drop's SIGN: `collapsedDrop` in lift space, `collapsedOffsetY` in `.offset`'s
    /// downward-positive space, exactly one negation between them, because a flipped sign would
    /// have opened a 64pt gap only E's device would see. With no drop there is no sign to get
    /// wrong — and the honest guard is that the metrics which existed ONLY for the drop are gone,
    /// rather than left behind as named zeros for someone to wire back in.
    func testTheDropsMetricsAreGoneSoThereIsNoSignToGetWrong() throws {
        let metrics = try Self.appCode("Focus/FocusBarCollapse.swift")
        for name in ["collapsedOffsetY", "collapsedDrop", "collapsedBottomLift", "expandedBottomLift"] {
            XCTAssertFalse(
                metrics.contains("static var \(name)") || metrics.contains("static let \(name)"),
                "`FocusBarMetrics.\(name)` is back. It existed only for the flush drop E reversed."
            )
        }
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

    // MARK: - The radius E chose by looking (`F-FocusCard-Corners`)

    /// **E picked this by sight, from a render, and it must not be "tidied" away** — the
    /// `peekStep` precedent exactly (CLAUDE.md §2), minus the waiver, because 24 is on the grid.
    ///
    /// E was shown the collapsed card at 0 (what shipped), 8, 16 and 24pt against the real tab bar
    /// and chose **24, matching the top corners**: `screenshots/focus-card-bottom-corners/`.
    /// "Leave it square after all" was offered explicitly and was not chosen.
    func testTheCollapsedBottomRadiusIsTheValueEChoseByLooking() {
        XCTAssertEqual(
            FocusBarMetrics.collapsedBottomCornerRadius, FocusBarMetrics.cornerRadius,
            "E chose \"match the top\" from four rendered options. A different number here is not"
                + " a tidy-up, it is a design decision nobody took."
        )
        XCTAssertGreaterThan(
            FocusBarMetrics.collapsedBottomCornerRadius, 0,
            "The collapsed card is square-bottomed again. E reversed that on 2026-09-11"
                + " (\"Round them\") and confirmed the radius by looking on 2026-09-13."
        )
    }

    /// The card and its keyline are cut from ONE silhouette, so they cannot disagree about where
    /// the corner is. This asserts the consequence rather than the arrangement: the fill's edge and
    /// the keyline meet at the same place on the bottom-left arc.
    func testTheFillAndTheKeylineAgreeAboutTheBottomCorner() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let fill = FocusBarCardShape(
            cornerRadius: 24, bottomCornerRadius: FocusBarMetrics.collapsedBottomCornerRadius
        ).path(in: rect)
        let keyline = strokedBorder(collapsed: true)
        // Just inside the fill's bottom-left arc, and under the keyline that traces it.
        XCTAssertTrue(fill.contains(CGPoint(x: 9, y: 92)))
        XCTAssertTrue(keyline.contains(CGPoint(x: 7.4, y: 92.6)))
        // Outside both: the square corner the card no longer has.
        XCTAssertFalse(fill.contains(CGPoint(x: 1, y: 99)))
        XCTAssertFalse(keyline.contains(CGPoint(x: 1, y: 99)))
    }

    // MARK: - The keyline (E removed its bottom run on 2026-09-09; it came back 2026-09-17)

    /// Sampled through the STROKE, not the path: a keyline is a line, so `contains` on the path's
    /// interior answers the wrong question. Stroking it turns the keyline into a fillable region,
    /// and then "is there a border at the bottom edge?" is a real question.
    private func borderCoversBottomEdge(collapsed: Bool, bottomCornerRadius: CGFloat = 24) -> Bool {
        strokedBorder(collapsed: collapsed, bottomCornerRadius: bottomCornerRadius)
            .contains(CGPoint(x: 50, y: 99.5))
    }

    /// The keyline as `FocusTimerBar` draws it since `F-CollapsedBarLift`: `strokeBorder` on the
    /// card's own shape, which insets it by half the 1pt line so the line lands inside the bounds.
    /// `FocusBarCardBorder`, the open-path keyline this replaced, is deleted. The collapsed card's
    /// bottom radius is E's *"Round them"* (`F-FocusCard-Corners`).
    private func strokedBorder(collapsed: Bool, bottomCornerRadius: CGFloat = 24) -> Path {
        FocusBarCardShape(cornerRadius: 24, bottomCornerRadius: collapsed ? bottomCornerRadius : 24)
            .inset(by: 0.5)
            .path(in: CGRect(x: 0, y: 0, width: 100, height: 100))
            .strokedPath(StrokeStyle(lineWidth: 2))
    }

    /// **REVERSED 2026-09-17** (it was `testTheCollapsedCardHasNoBottomKeyline`). E's 2026-09-09
    /// call — *"REMOVE the bottom border on the collapsed card tab"* — was right for a card sitting
    /// flush ON the tab bar: a hairline at the join read as a seam between two slabs. With the
    /// flush drop reversed there is no join, and a card outlined on three sides floating 32pt above
    /// the bar reads unfinished. The run returns as a CONSEQUENCE of E's call, not a new decision.
    func testTheCollapsedCardHasItsBottomKeylineBack() {
        XCTAssertTrue(
            borderCoversBottomEdge(collapsed: true),
            "The collapsed card has no bottom border. It floats above the tab bar now, so an"
                + " outline open at the bottom reads as a card left unfinished."
        )
    }

    func testTheExpandedCardKeepsAllFourEdges() {
        // The expanded card floats with a 16pt inset on every side — drop its bottom edge and it
        // reads as unfinished. It always kept all four; since 2026-09-17 the collapsed card does too.
        XCTAssertTrue(
            borderCoversBottomEdge(collapsed: false),
            "The expanded card lost its bottom border too."
        )
    }

    func testTheBorderStillCoversTheTopEdgeInBothStates() {
        for collapsed in [true, false] {
            XCTAssertTrue(
                strokedBorder(collapsed: collapsed).contains(CGPoint(x: 50, y: 0.5)),
                "The top keyline is missing (collapsed: \(collapsed))."
            )
        }
    }

    /// **`F-FocusCard-Corners`, and the coupling that is easy to miss.** Rounding only the FILL
    /// leaves the keyline tracing the old square outline: two 24pt tails running down past the
    /// curve to a corner the card no longer has. So the border rounds with it. (It used to add
    /// "and still omits the flat bottom RUN"; E's 2026-09-17 reversal of the flush drop brought
    /// the run back — see `testTheCollapsedCardHasItsBottomKeylineBack`.)
    ///
    /// Sampled on the bottom-left arc at 135°, which no square-cornered path passes near.
    func testTheCollapsedBorderFollowsTheRoundedBottomCorners() {
        XCTAssertTrue(
            strokedBorder(collapsed: true).contains(CGPoint(x: 7.4, y: 92.6)),
            "The keyline does not follow the rounded bottom corner, so it ends in mid-air where"
                + " the fill has already curved away."
        )
        XCTAssertFalse(
            strokedBorder(collapsed: true).contains(CGPoint(x: 0.5, y: 99)),
            "The keyline still runs all the way down to the old square corner."
        )
    }

    /// The floor of the morph: at radius 0 the collapsed keyline reaches the square corner.
    ///
    /// **Its second half REVERSED 2026-09-17** (the name was
    /// `testTheCollapsedBorderIsUnchangedAtRadiusZero`): it asserted the bottom RUN stayed absent
    /// — *"E removed it and has not reversed that"*. E reversed the flush drop the removal
    /// depended on, so the run is drawn at every radius now, the square floor included.
    func testTheCollapsedBorderReachesTheSquareCornerAndCloses_AtRadiusZero() {
        XCTAssertTrue(
            strokedBorder(collapsed: true, bottomCornerRadius: 0).contains(CGPoint(x: 0.5, y: 99)),
            "Radius 0 no longer reproduces the square-cornered keyline, so the morph has no floor."
        )
        XCTAssertTrue(
            borderCoversBottomEdge(collapsed: true, bottomCornerRadius: 0),
            "At radius 0 the keyline stops at the corner instead of closing along the bottom."
        )
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

    // MARK: - Source

    /// The app file as source, comment lines dropped — the `FocusBarCollapseCallSiteTests` reader.
    private static func appCode(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        let text = try String(contentsOf: url, encoding: .utf8)
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }
}
