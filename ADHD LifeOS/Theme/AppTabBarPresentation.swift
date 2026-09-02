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

    /// Slots divide the bar evenly. `0` for an empty bar rather than a division by zero — the
    /// list is a constant today, but the arithmetic is what the floor test leans on.
    static func slotWidth(barWidth: CGFloat, count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        return barWidth / CGFloat(count)
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
}

/// The bar's geometry, in one place so block 2's floating state and this resting one cannot
/// drift apart. Spacing obeys §2's 4/8/16/24 grid; the rest are component DIMENSIONS (like
/// `CaptureDiscMetrics.pillHeight`), which the grid does not govern.
enum AppTabBarMetrics {
    /// The row of slots.
    ///
    /// 56 first — the system bar's 49pt content height plus room for the dot. E's device verdict
    /// (2026-09-02) was *"really cramped, not much spacing/padding"*, and the measurement agreed:
    /// glyph, gap and dot came to 37pt inside 56, so the content sat high with dead space beneath
    /// it, and the glyph was 20pt against the 25 the approved concept drew. 72 is the roomiest of
    /// three variants E was shown, and stays on §2's base-8 grid.
    static let rowHeight: CGFloat = 72

    /// Gap between a slot's glyph and its indicator. The concept drew 7; §2 has no 7.
    static let glyphToIndicatorSpacing: CGFloat = 8

    /// Design F's position mark: a 5pt accent dot under the selected glyph.
    static let indicatorDotDiameter: CGFloat = 5

    /// One `matchedGeometryEffect` id, so the mark TRAVELS between slots instead of blinking out
    /// and back. Block 2's chip inherits it, which is what lets the dot grow into the chip rather
    /// than cross-fade.
    static let indicatorID = "appTabBarIndicator"

    /// The count pill: 16pt round for a single digit, a capsule beyond that.
    static let badgeDiameter: CGFloat = 16

    // MARK: - Design B, the floating state (F-Tools-2-Morph)

    /// While the page is moving the bar contracts to a floating card — E's pick for the second
    /// half of the morph. These are the concept's numbers, on §2's grid where the concept was
    /// already on it and rounded onto it where it was not (the concept drew a 6/4 inner padding;
    /// 8/4 is the nearest grid pair and reads identically at this size).
    static let floatingInset: CGFloat = 12
    static let floatingCornerRadius: CGFloat = 22
    static let floatingPaddingVertical: CGFloat = 8
    static let floatingPaddingHorizontal: CGFloat = 4

    /// The selected indicator's OTHER form: the dot grows into a tinted chip behind the glyph.
    /// 44×34 is the concept's, and the 44 is not a coincidence — it keeps §3's touch target
    /// satisfied by the chip itself, not merely by the slot around it.
    static let chipWidth: CGFloat = 44
    static let chipHeight: CGFloat = 34
    static let chipCornerRadius: CGFloat = 11

    /// Accent at 12% in light and 20% in dark: the same tint reads as a wash on white and needs
    /// more body to register against `CardSurface`'s near-black.
    static let chipTintLight: CGFloat = 0.12
    static let chipTintDark: CGFloat = 0.20

    /// How far the floating card sits off the bottom — **derived, not chosen**, so the two states
    /// occupy exactly the same band. `AppTabContent` reserves `rowHeight` once and never reflows
    /// it as you scroll (content shifting under a morphing bar would be intolerable), so B must
    /// fit inside that reserve rather than merely be near it: card height + lift == rowHeight.
    ///
    /// It lands on 22 with today's numbers, which is what the concept drew — but as a
    /// consequence rather than a coincidence. Change `rowHeight` or the chip and this follows.
    static var floatingLift: CGFloat {
        rowHeight - (chipHeight + floatingPaddingVertical * 2)
    }

    /// Where the pill sits against the glyph's top-trailing corner. §2 allows 4pt for micro
    /// positioning; the concept's 9/-5 is rounded onto that grid.
    static let badgeOffset = CGSize(width: 8, height: -4)
}
