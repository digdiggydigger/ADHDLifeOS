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

    /// **The two states occupy exactly the same band.** E: *"why don't you reduce the size of the
    /// solid pane view the same sizing as the floating tab bar?"* — so `rowHeight` is DERIVED
    /// from the floating card's height plus its lift, and the resting pane is no taller than the
    /// floating state needs. Equality, not merely "fits": slack would be the solid slab E
    /// objected to creeping back.
    func testTheRestingPaneIsExactlyTheFloatingStatesFootprint() {
        let cardHeight = AppTabBarMetrics.chipHeight + AppTabBarMetrics.floatingPaddingVertical * 2
        XCTAssertEqual(cardHeight + AppTabBarMetrics.floatingLift, AppTabBarMetrics.rowHeight)
    }

    /// The glyph and its indicator still have to fit, with room to breathe. E's "really cramped"
    /// verdict was about a 20pt glyph with dead space beneath it; the glyph is 25 now and the
    /// slack is the floating card's own 8pt padding. If a future tune squeezes below that, the
    /// row is too short for what it carries.
    func testTheRowLeavesTheGlyphStackRoomToBreathe() {
        let glyphStack: CGFloat = 25
            + AppTabBarMetrics.glyphToIndicatorSpacing
            + AppTabBarMetrics.indicatorDotDiameter
        let slackPerSide = (AppTabBarMetrics.rowHeight - glyphStack) / 2
        XCTAssertGreaterThanOrEqual(
            slackPerSide, AppTabBarMetrics.floatingPaddingVertical,
            "The resting row is tighter around its glyphs than the floating card is around its."
        )
    }

    /// It must not sit flush on the home indicator either. The safe area already excludes the
    /// indicator, so the lift is the gap between the card and it — at zero the card reads as
    /// jammed into the bottom edge, and the system gesture area crowds it.
    func testTheFloatingCardKeepsAGapAboveTheHomeIndicator() {
        XCTAssertGreaterThanOrEqual(AppTabBarMetrics.floatingLift, 8)
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
