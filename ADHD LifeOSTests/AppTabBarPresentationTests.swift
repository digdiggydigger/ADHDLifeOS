//
//  AppTabBarPresentationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The pure rules behind the custom six-item tab bar (F-Tools-1-Bar).
///
/// The bar exists at all because iOS shows at most FIVE `.tabItem`s before folding the rest into
/// a "More" list, and E's 2026-09-02 call adds a sixth ("Tools"). So the slot list, the badge
/// rule and the width arithmetic are pinned here rather than living inside a view body — view
/// bodies in this app are ~0% covered by design.
final class AppTabBarPresentationTests: XCTestCase {

    // MARK: - The slots

    func testTabs_areTheSixInOrderWithToolsLast() {
        XCTAssertEqual(
            AppTabBarPresentation.tabs.map(\.tab),
            [.today, .tasks, .areas, .journal, .captures, .tools]
        )
    }

    func testTools_carriesTheWrenchGlyph() {
        let tools = AppTabBarPresentation.tabs.last
        XCTAssertEqual(tools?.tab, .tools)
        XCTAssertEqual(tools?.systemImage, "wrench.and.screwdriver")
        XCTAssertEqual(tools?.label, "Tools")
    }

    /// A tab added to the enum but never given a slot would simply not render — the bar is the
    /// only way in now that the system's is hidden. Totality over `AppTab` is what catches that.
    func testTabs_coverEveryAppTabCase() {
        XCTAssertEqual(AppTabBarPresentation.tabs.map(\.tab), AppTab.allCases)
    }

    func testEverySlot_carriesALabelAndAGlyph() {
        for slot in AppTabBarPresentation.tabs {
            XCTAssertFalse(slot.label.isEmpty, "\(slot.tab) has no label")
            XCTAssertFalse(slot.systemImage.isEmpty, "\(slot.tab) has no glyph")
        }
    }

    // MARK: - The badge

    /// `.badge(0)` rendered nothing, and the custom bar has to keep that: an empty inbox is
    /// silent rather than a zero. (A failed refresh keeps the LAST KNOWN count — that lives in
    /// RootView's one writer, which never assigns on failure.)
    func testShowsBadge_isSilentAtZero() {
        XCTAssertFalse(AppTabBarPresentation.showsBadge(count: 0))
    }

    func testShowsBadge_showsAnythingAboveZero() {
        XCTAssertTrue(AppTabBarPresentation.showsBadge(count: 1))
        XCTAssertTrue(AppTabBarPresentation.showsBadge(count: 99))
    }

    /// Defensive: a count can only come from an array's `.count`, but a negative one must never
    /// render "-1" over the tray glyph.
    func testShowsBadge_isSilentBelowZero() {
        XCTAssertFalse(AppTabBarPresentation.showsBadge(count: -1))
    }

    // MARK: - Slot width

    func testSlotWidth_dividesTheBarEvenly() {
        XCTAssertEqual(AppTabBarPresentation.slotWidth(barWidth: 393, count: 6), 65.5, accuracy: 0.001)
    }

    func testSlotWidth_isZeroForAnEmptyBarRatherThanDividingByZero() {
        XCTAssertEqual(AppTabBarPresentation.slotWidth(barWidth: 393, count: 0), 0)
    }

    /// **The test that stops a seventh tab being added casually.** The narrowest iPhone this app
    /// supports is the SE at 375pt; six slots there are 62.5pt, clear of §3's 44pt touch-target
    /// floor. A seventh would be 53.6 (still clear), an eighth 46.9 — and a ninth breaks it. The
    /// assertion is on SIX because six is what E chose; widening the bar is a design decision,
    /// not a arithmetic one.
    func testSixSlots_clearTheTouchTargetFloorOnTheNarrowestSupportedIPhone() {
        let width = AppTabBarPresentation.slotWidth(
            barWidth: AppTabBarPresentation.narrowestSupportedScreenWidth,
            count: AppTabBarPresentation.tabs.count
        )
        XCTAssertEqual(width, 62.5, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(width, AppTabBarPresentation.minimumTouchTarget)
    }

    // MARK: - The morph's geometry (F-Tools-2-Morph)

    /// **The band is ONE height, and both positions of the card fit inside it.** The card is the
    /// bar's `safeAreaInset`; if its height changed between the two states, every page's content
    /// would jump by the difference each time the morph fired. So `rowHeight` is DERIVED from the
    /// card plus the LARGER of the two lifts, and the card moves inside a band that does not.
    /// Equality, not merely "fits": slack would be the solid slab E objected to creeping back.
    func testTheBandIsTheCardPlusTheLargerLiftSoTheInsetNeverMoves() {
        let cardHeight = AppTabBarMetrics.chipHeight + AppTabBarMetrics.floatingPaddingVertical * 2
        XCTAssertEqual(cardHeight, AppTabBarMetrics.cardHeight)
        let largerLift = max(AppTabBarMetrics.restingLift, AppTabBarMetrics.floatingLift)
        XCTAssertEqual(cardHeight + largerLift, AppTabBarMetrics.rowHeight)
    }

    /// E's 2026-09-08 pick for the two positions — "wider, lower AND drops": at rest the card is
    /// wider (a smaller inset) and higher (a larger lift); scrolling it contracts inward and
    /// settles down. Both inequalities are the design; a tune that flattened either would make
    /// the two states the same card, which E did not choose.
    func testTheCardIsWiderAndHigherAtRestAndContractsAndDropsOnScroll() {
        XCTAssertLessThan(AppTabBarMetrics.restingInset, AppTabBarMetrics.floatingInset)
        XCTAssertGreaterThan(AppTabBarMetrics.restingLift, AppTabBarMetrics.floatingLift)
    }

    /// The resting pill still has to fit, with room to breathe. E's "really cramped" verdict was
    /// about a 20pt glyph with dead space beneath it; the pill is the chip's 34pt now and the
    /// slack around it is at least the floating card's own 8pt padding. If a future tune
    /// squeezes below that, the row is too short for what it carries.
    func testTheRowLeavesThePillRoomToBreathe() {
        let slackPerSide = (AppTabBarMetrics.rowHeight - AppTabBarMetrics.chipHeight) / 2
        XCTAssertGreaterThanOrEqual(
            slackPerSide, AppTabBarMetrics.floatingPaddingVertical,
            "The resting row is tighter around its pill than the floating card is around its chip."
        )
    }

    // MARK: - The resting pill (F-TabBar-SelectPill)

    /// Design C's rule: the label belongs to the SELECTED slot AT REST, and nowhere else. Floating,
    /// the selection is the icon-only chip (Design B, unchanged); unselected slots never carry a
    /// label in either state.
    func testShowsLabel_onlyForTheSelectedSlotAtRest() {
        XCTAssertTrue(AppTabBarPresentation.showsLabel(isSelected: true, isFloating: false))
        XCTAssertFalse(AppTabBarPresentation.showsLabel(isSelected: true, isFloating: true))
        XCTAssertFalse(AppTabBarPresentation.showsLabel(isSelected: false, isFloating: false))
        XCTAssertFalse(AppTabBarPresentation.showsLabel(isSelected: false, isFloating: true))
    }

    /// **The resting state's own "stops a seventh tab" test.** The selected pill takes what it
    /// needs (capped) and the other five share the rest, so the floor to prove is the width of an
    /// UNSELECTED slot beside the WIDEST pill the bar allows, on the narrowest supported iPhone,
    /// inside the RESTING card: (375 − 2·4 inset − 2·4 card padding − 120) / 5 = 47.8, clear of
    /// §3's 44. A seventh tab would be 39.8 and fail.
    func testRestingSlots_clearTheTouchTargetFloorBesideTheWidestPillOnTheSE() {
        let width = AppTabBarPresentation.restingSlotWidth(
            barWidth: AppTabBarPresentation.narrowestSupportedScreenWidth,
            pillWidth: AppTabBarMetrics.maximumRestingPillWidth,
            count: AppTabBarPresentation.tabs.count
        )
        XCTAssertEqual(width, 47.8, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(width, AppTabBarPresentation.minimumTouchTarget)
    }

    /// §3's 44pt target is carried by the slot's HIT AREA, which may overflow the card, never by
    /// the card growing to hold it. Round 2 shipped a 60pt card that the metrics called 50,
    /// because the slot's `minHeight` leaked into the row; the overflow is what stops that.
    func testTheTouchTargetIsCarriedByTheHitOverflowNotTheCard() {
        XCTAssertGreaterThanOrEqual(AppTabBarMetrics.slotHitOverflow, 0)
        XCTAssertGreaterThanOrEqual(
            AppTabBarMetrics.chipHeight + AppTabBarMetrics.slotHitOverflow * 2,
            AppTabBarPresentation.minimumTouchTarget
        )
    }

    /// With one slot there is nothing beside the pill to share the leftover; with none there is
    /// no pill. Neither may divide by zero.
    func testRestingSlotWidth_isZeroBelowTwoSlotsRatherThanDividingByZero() {
        XCTAssertEqual(AppTabBarPresentation.restingSlotWidth(barWidth: 375, pillWidth: 100, count: 1), 0)
        XCTAssertEqual(AppTabBarPresentation.restingSlotWidth(barWidth: 375, pillWidth: 100, count: 0), 0)
    }

    /// The pill morphs INTO the chip when the bar floats. A cap narrower than the chip would have
    /// the mark grow as the bar contracts, which is the morph running backwards.
    func testTheRestingPillIsNeverNarrowerThanTheChipItMorphsInto() {
        XCTAssertGreaterThanOrEqual(
            AppTabBarMetrics.maximumRestingPillWidth, AppTabBarMetrics.chipWidth
        )
    }

    /// Design C drew 10pt inner padding and a 6pt icon-to-label gap; §2 has neither. Every spacing
    /// the resting state introduces — the pill's own and the card's resting position — sits on
    /// the 4/8/16/24 grid.
    func testTheRestingStatesSpacingIsOnTheGrid() {
        let grid: Set<CGFloat> = [4, 8, 16, 24]
        XCTAssertTrue(grid.contains(AppTabBarMetrics.restingInset))
        XCTAssertTrue(grid.contains(AppTabBarMetrics.restingLift))
        XCTAssertTrue(grid.contains(AppTabBarMetrics.pillPaddingHorizontal))
        XCTAssertTrue(grid.contains(AppTabBarMetrics.pillGlyphToLabelSpacing))
    }

    /// E's 2026-09-08 pick: the pill has CAPSULE ends. Derived from the chip's height, so it stays
    /// a capsule if the chip is ever re-tuned rather than drifting into a rounded rectangle.
    func testThePillIsACapsule() {
        XCTAssertEqual(AppTabBarMetrics.pillCornerRadius, AppTabBarMetrics.chipHeight / 2)
    }

    /// It must not sit flush on the home indicator either. The safe area already excludes the
    /// indicator, so the lift is the gap between the card and it — at zero the card reads as
    /// jammed into the bottom edge, and the system gesture area crowds it. The floor was 8 until
    /// E's 2026-09-08 device verdict, *"the whole nav bar moved down the screen a little bit"*;
    /// it is the grid's 4 now, and zero stays out.
    func testTheFloatingCardKeepsAGapAboveTheHomeIndicator() {
        XCTAssertGreaterThanOrEqual(AppTabBarMetrics.floatingLift, 4)
    }

    /// The chip is the touch target while floating, not merely a decoration inside one.
    func testTheChipItselfHoldsTheTouchTargetWidth() {
        XCTAssertGreaterThanOrEqual(
            AppTabBarMetrics.chipWidth, AppTabBarPresentation.minimumTouchTarget
        )
    }

    /// Dark needs more body than light: the same alpha that reads as a wash on white disappears
    /// against `CardSurface`'s near-black.
    func testTheChipTintIsStrongerInDark() {
        XCTAssertGreaterThan(AppTabBarMetrics.chipTintDark, AppTabBarMetrics.chipTintLight)
    }

    func testMinimumTouchTarget_isTheHIGFloor() {
        XCTAssertEqual(AppTabBarPresentation.minimumTouchTarget, 44)
    }

    // MARK: - Badge text

    /// The system `.badge()` laid out its own number; a hand-rolled bar has no such protection,
    /// so a four-digit inbox would push the pill off the tray glyph. 99+ is the cap every native
    /// badge uses.
    func testBadgeText_isTheCountUpToNinetyNine() {
        XCTAssertEqual(AppTabBarPresentation.badgeText(count: 1), "1")
        XCTAssertEqual(AppTabBarPresentation.badgeText(count: 99), "99")
    }

    func testBadgeText_capsAtNinetyNinePlus() {
        XCTAssertEqual(AppTabBarPresentation.badgeText(count: 100), "99+")
        XCTAssertEqual(AppTabBarPresentation.badgeText(count: 4_000), "99+")
    }

    func testBadgeText_isNilWhenTheBadgeIsSilent() {
        XCTAssertNil(AppTabBarPresentation.badgeText(count: 0))
        XCTAssertNil(AppTabBarPresentation.badgeText(count: -1))
    }

    /// VoiceOver reads the slot, not the pill: without this the count is conveyed by a red dot
    /// alone, which §4 forbids.
    func testAccessibilityLabel_foldsTheCountIntoTheSlotName() {
        XCTAssertEqual(
            AppTabBarPresentation.accessibilityLabel(for: "Captures", badgeCount: 3),
            "Captures, 3 unprocessed"
        )
    }

    func testAccessibilityLabel_isJustTheSlotNameWithNoBadge() {
        XCTAssertEqual(
            AppTabBarPresentation.accessibilityLabel(for: "Captures", badgeCount: 0),
            "Captures"
        )
    }

    /// The identifier UI journeys address the bar by. `app.tabBars` cannot see a SwiftUI stack —
    /// there is no `isTabBar` accessibility trait in SwiftUI — so the journeys move to these.
    func testAccessibilityIdentifier_isStableAndPerSlot() {
        XCTAssertEqual(
            AppTabBarPresentation.tabs.map { AppTabBarPresentation.accessibilityIdentifier(for: $0) },
            ["tabBar.Today", "tabBar.Tasks", "tabBar.Areas",
             "tabBar.Journal", "tabBar.Captures", "tabBar.Tools"]
        )
    }
}
