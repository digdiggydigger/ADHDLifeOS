//
//  AppTabBarPresentation.swift
//  ADHD LifeOS
//

import CoreGraphics
import Foundation

/// The pure rules behind `AppTabBar` — the slot list, the badge, the width arithmetic and the
/// accessibility strings. Kept out of the view body for the reason every presentation type in
/// this app is: view bodies here are ~0% covered by design, so any rule left inside one is a
/// rule nothing checks. `PlaceAppPickerPresentation` is the house pattern.
enum AppTabBarPresentation {

    /// One station on the bar. `Identifiable` by its tab, so `ForEach` needs no index.
    struct Slot: Identifiable, Equatable {
        let tab: AppTab
        let label: String
        let systemImage: String

        var id: AppTab { tab }
    }

    /// The six, in E's order. Glyphs are the ones the system `.tabItem`s carried, unchanged, so
    /// the bar swap is not also a glyph change — Tools is the only new one
    /// (`wrench.and.screwdriver`, E's pick).
    ///
    /// Order is asserted, not incidental: Tools is LAST because it is the least-used station,
    /// and the four in the middle keep the positions muscle memory already has.
    static let tabs: [Slot] = [
        Slot(tab: .today, label: "Today", systemImage: "chart.line.uptrend.xyaxis"),
        Slot(tab: .tasks, label: "Tasks", systemImage: "checklist"),
        Slot(tab: .areas, label: "Areas", systemImage: "square.grid.2x2"),
        Slot(tab: .journal, label: "Journal", systemImage: "book"),
        Slot(tab: .captures, label: "Captures", systemImage: "tray.full"),
        Slot(tab: .tools, label: "Tools", systemImage: "wrench.and.screwdriver")
    ]

    // MARK: - The Captures badge

    /// `.badge(0)` rendered nothing, and that behaviour is the point: an empty inbox is SILENT
    /// rather than a zero. (The other half — a failed refresh keeping the last known number —
    /// lives in RootView's single writer, which simply never assigns on failure. "Never having
    /// looked ≠ nothing there.")
    static func showsBadge(count: Int) -> Bool {
        count > 0
    }

    /// The pill's text, or `nil` when the badge is silent.
    ///
    /// The system badge laid out its own number and grew the bar to fit; a hand-rolled pill has
    /// no such protection, so the count is capped the way every native badge caps it.
    static func badgeText(count: Int) -> String? {
        guard showsBadge(count: count) else { return nil }
        return count > badgeCap ? "\(badgeCap)+" : "\(count)"
    }

    private static let badgeCap = 99

    // MARK: - Width

    /// §3's floor. Every slot must clear it, in every state of the bar.
    static let minimumTouchTarget: CGFloat = 44

    /// The iPhone SE — the narrowest screen this app supports. Named so the six-slot floor test
    /// reads as a claim about hardware rather than a magic 375.
    static let narrowestSupportedScreenWidth: CGFloat = 375

    /// Slots divide the bar evenly — **the floating state's arithmetic** (Design B: six equal
    /// slots in the card). `0` for an empty bar rather than a division by zero — the list is a
    /// constant today, but the arithmetic is what the floor test leans on.
    static func slotWidth(barWidth: CGFloat, count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        return barWidth / CGFloat(count)
    }

    /// **The resting state's arithmetic** (Design C: the selected pill takes what it needs, the
    /// others share the rest). The width of ONE unselected slot when the pill is `pillWidth`
    /// wide, inside the RESTING card — after its inset from the screen edges and its own inner
    /// padding. `0` below two slots: with one there is nothing beside the pill to share the
    /// leftover, with none there is no pill.
    static func restingSlotWidth(barWidth: CGFloat, pillWidth: CGFloat, count: Int) -> CGFloat {
        guard count > 1 else { return 0 }
        let cardWidth = barWidth - AppTabBarMetrics.restingInset * 2
        let leftover = cardWidth - AppTabBarMetrics.floatingPaddingHorizontal * 2 - pillWidth
        return leftover / CGFloat(count - 1)
    }

    // MARK: - The label

    /// Design C's rule, E's 2026-09-08 pick: the selected tab alone grows a label, and only
    /// while the bar is at rest. Floating (Design B, unchanged) the selection is the icon-only
    /// chip, and an unselected slot never carries a label in either state.
    static func showsLabel(isSelected: Bool, isFloating: Bool) -> Bool {
        isSelected && !isFloating
    }

    // MARK: - Accessibility

    /// VoiceOver reads the slot, not the pill — without this the count would be conveyed by a
    /// red dot alone, which §4 forbids.
    static func accessibilityLabel(for label: String, badgeCount: Int) -> String {
        guard showsBadge(count: badgeCount) else { return label }
        return "\(label), \(badgeCount) unprocessed"
    }

    /// UI journeys used to reach the tabs through `app.tabBars.buttons[name]`. A SwiftUI stack is
    /// not a tab bar to XCUITest — SwiftUI exposes no `isTabBar` trait — so the journeys address
    /// these identifiers instead. Per-BUTTON, never on the container: an identifier on a
    /// container is inherited by its children, which would make all six ambiguous.
    static func accessibilityIdentifier(for slot: Slot) -> String {
        "tabBar.\(slot.label)"
    }

    /// What a tap on a slot means (E's rule, 2026-09-08): a different tab is selected; the tab
    /// you are already on is RE-selected, which the coordinator turns into pop-to-root or
    /// scroll-to-top — `TabView` did both for free, and the custom bar had lost both.
    enum TapOutcome: Equatable {
        case select(AppTab)
        case reselect(AppTab)
    }

    static func tapOutcome(current: AppTab, tapped: AppTab) -> TapOutcome {
        tapped == current ? .reselect(tapped) : .select(tapped)
    }
}

/// The bar's geometry, in one place so block 2's floating state and this resting one cannot
/// drift apart. Spacing obeys §2's 4/8/16/24 grid; the rest are component DIMENSIONS (like
/// `CaptureDiscMetrics.pillHeight`), which the grid does not govern.
enum AppTabBarMetrics {
    /// The row of slots — **derived from the floating card, so the two states occupy exactly the
    /// same band**.
    ///
    /// The history is worth keeping, because the number moved three times and each move had a
    /// reason. 56 first (the system bar's 49pt content height plus room for the dot); E's device
    /// verdict was *"really cramped, not much spacing/padding"*, and the measurement agreed —
    /// glyph, gap and dot came to 37pt inside 56, so content sat high with dead space beneath it,
    /// and the glyph was 20pt against the 25 the concept drew. 72 then, the roomiest of three
    /// rendered variants, which E approved: *"spacing is so much better"*.
    ///
    /// Then derived, on E's *"why don't you reduce the size of the solid pane view the same sizing
    /// as the floating tab bar?"*: the floating card's own height plus the gap it floats by —
    /// 58pt, the two states covering an identical footprint.
    ///
    /// **Now (2026-09-08) the card plus the LARGER of its two lifts — 66pt.** The flat pane is
    /// gone; the card floats in both states, higher at rest and lower while scrolling. The band
    /// is the bar's `safeAreaInset`, so it must be ONE height whichever state applies — a band
    /// that changed with the morph would move every page's content by the difference each time
    /// it fired. The card moves inside the band; the band does not. It is not a chosen number,
    /// so §2's grid does not govern it; change the chip, the padding or either lift and this
    /// follows rather than drifting.
    ///
    /// The glyph is UNCHANGED at 25pt. E's cramped verdict was about the glyph and the dead space
    /// under it, not the row, and both of those stay fixed — the slack around the content is the
    /// floating card's own 8pt padding.
    static var rowHeight: CGFloat {
        cardHeight + max(restingLift, floatingLift)
    }

    /// The floating card's own height: the chip (or the pill, the same height) plus the card's
    /// vertical padding. 50pt. The same in both states — only the card's POSITION morphs.
    static var cardHeight: CGFloat {
        chipHeight + floatingPaddingVertical * 2
    }

    /// One `matchedGeometryEffect` id, so the mark TRAVELS between slots instead of blinking out
    /// and back. There is exactly one mark now — the resting pill and the floating chip are the
    /// same view at two sizes — so this is purely the slot-to-slot slide on a tab change.
    static let indicatorID = "appTabBarIndicator"

    /// The count pill: 16pt round for a single digit, a capsule beyond that.
    static let badgeDiameter: CGFloat = 16

    // MARK: - Design B, the floating state (F-Tools-2-Morph)

    /// While the page is moving the bar contracts to its scrolled position — E's pick for the
    /// second half of the morph. These are the concept's numbers, on §2's grid where the concept
    /// was already on it and rounded onto it where it was not (the concept drew a 6/4 inner
    /// padding; 8/4 is the nearest grid pair and reads identically at this size). Since
    /// 2026-09-08 the card is the bar in BOTH states; `floatingInset` / `floatingLift` are its
    /// SCROLLED position, `restingInset` / `restingLift` its resting one. **The inset is 8, down
    /// from the concept's 12**, on E's second device verdict — *"WIDEN the horizontal width"* —
    /// so the scrolled card still contracts from the resting 4, by the same 4pt as before.
    static let floatingInset: CGFloat = 8
    static let floatingCornerRadius: CGFloat = 22
    static let floatingPaddingVertical: CGFloat = 8
    static let floatingPaddingHorizontal: CGFloat = 4

    /// The selected indicator's floating form: the resting pill contracts into a tinted chip
    /// behind the glyph. 44 wide is the concept's, and not a coincidence — it keeps §3's touch
    /// target satisfied by the chip itself, not merely by the slot around it.
    ///
    /// **44 tall since E's 2026-09-08 device verdict** (*"increase the inner-padding of the icon
    /// inside the blue highlight"*), up from the concept's 34: the ~25pt glyph now has ~10pt
    /// above and below it instead of ~4. The height is shared by the pill, so the morph between
    /// them stays width-only — and at 44 the highlight IS the touch target, so `slotHitOverflow`
    /// is zero and the card is exactly what the metrics say.
    static let chipWidth: CGFloat = 44
    static let chipHeight: CGFloat = 44
    static let chipCornerRadius: CGFloat = 11

    /// How far each slot's HIT AREA may extend above and below the highlight to reach §3's 44pt,
    /// without the card growing to hold it. Round 2 shipped a 60pt card that the metrics called
    /// 50: the slot's `minHeight` leaked into the row. The overflow is applied as negative
    /// vertical padding around the slot's `contentShape`, so the layout stays the chip's height
    /// while taps a little above or below the highlight still land.
    static var slotHitOverflow: CGFloat {
        max(0, (AppTabBarPresentation.minimumTouchTarget - chipHeight) / 2)
    }

    /// Accent at 12% in light and 20% in dark: the same tint reads as a wash on white and needs
    /// more body to register against `CardSurface`'s near-black.
    static let chipTintLight: CGFloat = 0.12
    static let chipTintDark: CGFloat = 0.20

    // MARK: - Design C, the resting state (F-TabBar-SelectPill)

    /// At rest the selected slot is a tinted PILL holding glyph and label — E's 2026-09-08 call,
    /// combining B and C from the original six: C's pill at the top of the page, B's chip once
    /// scrolled. The pill is the chip's height, so the morph into it is the label collapsing
    /// and the corners squaring off; nothing else about the mark changes.
    ///
    /// C drew a 10pt inner padding and a 6pt icon-to-label gap; neither is on §2's grid, and §2
    /// beats the concept (CLAUDE.md §7). The gap rounds to 8. **The inner padding is 16 since
    /// E's 2026-09-08 device verdict** (*"increase the inner-padding of the icon inside the blue
    /// highlight"*), up from the 8 that shipped in round 2. The card's own inner padding stays
    /// B's 4 in both states (E: *"Keep B's 4pt"*).
    static let pillPaddingHorizontal: CGFloat = 16
    static let pillGlyphToLabelSpacing: CGFloat = 8

    /// E's pick: **capsule ends** on the pill. Derived from the chip's height so it stays a
    /// capsule if the chip is re-tuned. The chip keeps its own 11 — B is unchanged — and the
    /// mark animates between the two radii as the label collapses.
    static var pillCornerRadius: CGFloat {
        chipHeight / 2
    }

    /// **Where the card sits at rest — E's 2026-09-08 pick, "wider, lower AND drops."** The flat
    /// pane that ran to the bottom of the screen is gone on E's first device verdict (*"the nav
    /// bar shouldn't extend down to the bottom of the screen"*): the card floats in BOTH states,
    /// and the two positions differ in both axes so the morph is legible. At rest it is wider
    /// (inset 4 against the scrolled 8) and higher (lift 8 against the scrolled 4); scrolling,
    /// it contracts inward and settles down.
    ///
    /// Round 2 shipped 8 / 16; E's second device verdict tuned both — *"the whole nav bar moved
    /// down the screen a little bit to create more space"* and *"WIDEN the horizontal width"*,
    /// with red marks about 6pt in from each screen edge. Both halved onto the grid, and the
    /// scrolled pair moved with them so the morph keeps its shape. Still the tunables.
    static let restingInset: CGFloat = 4
    static let restingLift: CGFloat = 8

    /// The widest a resting pill may be. This is what turns §3's floor into a GUARANTEE rather
    /// than a font-metrics estimate: the five unselected slots share what the pill leaves inside
    /// the resting card, so the floor test is (375 − 2·4 − 2·4 − 120) / 5 = 47.8 on the SE,
    /// whatever the label measures. "Captures" — the longest label — needs ~115pt at the default
    /// size with the 16pt inner padding and ~138 at the bar's largest clamped size (xxxLarge),
    /// so the cap bites only towards the top of the range, where the label's
    /// `minimumScaleFactor` (0.8, so down to ~110) absorbs it (§1: never clip, never truncate).
    static let maximumRestingPillWidth: CGFloat = 120

    /// How far the card sits off the bottom of the safe area WHILE SCROLLING.
    ///
    /// **8, down from the concept's 22**, on E's GIF verdict: *"when scrolling, the icon nav bar
    /// should move further down the page to create more space"*; **then 4**, on E's 2026-09-08
    /// device verdict, *"the whole nav bar moved down the screen a little bit"*. That verdict is
    /// the morph's vertical half: the card rests at `restingLift` and drops to this.
    ///
    /// Not zero: the safe area already excludes the home indicator, so this is the gap above it,
    /// and at zero the card reads as jammed into the bottom edge. `rowHeight` is derived from
    /// the larger of the two lifts, so the band follows any change here or to `restingLift`
    /// rather than having to be re-tuned alongside it.
    static let floatingLift: CGFloat = 4

    /// Where the pill sits against the glyph's top-trailing corner. §2 allows 4pt for micro
    /// positioning; the concept's 9/-5 is rounded onto that grid.
    static let badgeOffset = CGSize(width: 8, height: -4)
}
