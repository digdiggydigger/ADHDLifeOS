//
//  AppSearchScope.swift
//  ADHD LifeOS
//

import CoreGraphics
import Foundation

/// What the bottom search row is currently searching, and the copy that goes with it.
///
/// **Why the app draws its own search field at all.** iOS 26 renders `.searchable` as a capsule
/// pinned to the bottom of the screen, docking it into a `TabView`'s bar where one exists. The
/// Tools arc replaced `TabView` with `AppTabContent` — a `TabView` folds a sixth tab into a "More"
/// list — so the capsule had nothing to dock into, stood on its own, and landed UNDERNEATH the
/// custom bar, where E photographed it and where it could not be tapped at all. `.searchable` with
/// an explicit `.navigationBarDrawer` placement does clear it, but that puts search at the top of
/// the screen and **E rejected that**: the field belongs at the bottom, in the row the capture
/// disc already occupies.
///
/// **`.none` is a real case, not a fallback.** Three of the six tabs have nothing to search, and
/// they must not pay the row's bottom clearance for a control they never show.
enum AppSearchScope: Equatable {
    case none
    case tasks

    /// Which scope a tab is in.
    ///
    /// **Driven by `selectedTab`, deliberately, and this is the trap of the arc.**
    /// `AppTabContent` keeps every visited tab alive so scroll position and `NavigationStack`
    /// depth survive a switch — which means `.onAppear` / `.onDisappear` fire once on first build
    /// and then effectively never again. A "register my scope when I appear" design would look
    /// right and silently leave whichever tab registered last in charge forever. A pure function
    /// of a value that changes on every switch cannot go wrong that way.
    ///
    /// Captures and Journal arrive in blocks 2 and 3 **with their screens**. Adding their cases
    /// now would ship two scopes nothing renders — this repo's most repeated defect in its
    /// gated-off form — and the exhaustive `switch` in each surface is what forces them to be
    /// handled when they land.
    static func scope(for tab: AppTab) -> AppSearchScope {
        switch tab {
        case .tasks:
            return .tasks
        case .today, .areas, .journal, .captures, .tools:
            return .none
        }
    }

    /// The field's prompt, or `nil` where there is no field.
    var placeholder: String? {
        switch self {
        case .none: return nil
        case .tasks: return "Search tasks"
        }
    }

    /// Whether this screen shows the row at all — and therefore whether it pays for the room.
    var showsRow: Bool {
        placeholder != nil
    }
}

/// The row's geometry, and the bottom room a screen carrying it has to reserve.
enum AppSearchRowMetrics {
    /// §3's 44pt floor exactly. The control is a Button — it is the only way into search on the
    /// screens that have it — and it must not be taller than the disc's frame, or the row's height
    /// would be set by the field and the disc's centre would shift when the pill collapses.
    static let fieldHeight: CGFloat = 44

    /// §2's grid. The gap between the field and the disc beside it.
    static let rowSpacing: CGFloat = 16

    /// The field's capsule corner. Matches the chip radius the bar already uses at this size.
    static let fieldCornerRadius: CGFloat = 12

    /// E's 2026-08-31 margin pass, re-confirmed when approving this row: *"I just wanna make sure
    /// that you have added spacing between the top of the menu/nav tab bar and the collapsed
    /// pill."* Spelled here so a test can hold it, and read by `RootBottomOverlay`.
    static let gapAboveTabBar: CGFloat = 60

    /// What the bottom furniture actually has to be padded by, and **it is not `gapAboveTabBar`
    /// alone — that was a real bug, measured on E's device.**
    ///
    /// `RootBottomOverlay` is an `.overlay(alignment: .bottom)`, and its `.bottom` resolves to the
    /// screen's ORIGINAL safe area, **not** to the top of the tab bar, even though the bar is
    /// applied as a `safeAreaInset` before it. The file's own comment claimed the opposite and a
    /// test was written to enforce it, so the capture disc has been sitting ON the bar rather than
    /// above it. On E's iPhone 15 Pro: disc frame bottom 758pt, bar top 751pt — a **7pt overlap**.
    /// E reported it as "make sure you have added spacing between the top of the nav tab bar and
    /// the collapsed pill", which is exactly what was missing.
    ///
    /// Confirmed by a controlled probe rather than by reading: with the bar's height added the
    /// disc's frame bottom moved from 779.8 to 721.8 against an unchanged bar top of ~772 — from
    /// overlapping to the intended gap.
    static var bottomFurnitureLift: CGFloat {
        gapAboveTabBar + AppTabBarMetrics.rowHeight
    }

    /// Bottom room for a scrolling screen, with or without the search row.
    ///
    /// **Derived from `CaptureDiscMetrics.clearance`, never typed twice.** Eleven files reserve
    /// the disc's 92pt through `.captureDiscClearance()`; three of them now also carry a search
    /// row and need the extra. A second literal somewhere is how the two drift the first time the
    /// field's height moves — the failure `CaptureDiscClearanceCallSiteTests` was written for.
    static func clearance(hasSearchRow: Bool) -> CGFloat {
        CaptureDiscMetrics.clearance + (hasSearchRow ? fieldHeight + rowSpacing : 0)
    }
}
