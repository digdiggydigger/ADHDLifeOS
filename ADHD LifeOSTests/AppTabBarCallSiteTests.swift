//
//  AppTabBarCallSiteTests.swift
//  ADHD LifeOSTests
//
//  Reachability guards for the custom tab bar, in the `CaptureDiscPillCallSiteTests` mould and
//  for the same reason. This repo's most repeated defect is a component that is written,
//  documented and unit-tested while nothing renders it — `AppTabBarPresentation` would pass all
//  seventeen of its own tests with a `RootView` that still drew the system bar. Tests prove
//  correctness, never reachability; these read the source, which is the layer a wiring claim
//  actually lives in.
//

import XCTest
@testable import ADHD_LifeOS

final class AppTabBarCallSiteTests: XCTestCase {

    func testRootViewRendersTheCustomBar() throws {
        XCTAssertTrue(
            try Self.appSource("RootView.swift").contains("AppTabBar("),
            "RootView never renders `AppTabBar`, so the app has no tab bar at all — the system's"
                + " is hidden below and nothing stands in its place."
        )
    }

    /// **The bar's height must be RESERVED as layout space, and the bar drawn over that reserve.**
    ///
    /// It was a `safeAreaInset` on the container first, and E's device screenshot showed the
    /// Journal composer sliced in half by the bar, its caption line gone. A SwiftUI
    /// `safeAreaInset` applied outside a view does not reach into that view's own
    /// `NavigationStack` — and the Journal composer, the inbox's Sorted bar and the app picker's
    /// footer all pin themselves with exactly that modifier, inside exactly such a stack.
    /// `TabView` never had the problem because UIKit sets `additionalSafeAreaInsets` on each
    /// tab's view CONTROLLER, which a nested `UINavigationController` inherits.
    ///
    /// So the two halves are asserted together: the reserve exists in `AppTabContent`, and
    /// RootView draws the bar as an overlay rather than an inset. Either one alone is the bug —
    /// a reserve with an inset double-counts the height, an overlay with no reserve is what E saw.
    func testTheBarsHeightIsReservedAsLayoutSpaceAndTheBarOverlaysIt() throws {
        let container = try Self.appSource("AppTabContent.swift")
        XCTAssertTrue(
            container.contains("frame(height: AppTabBarMetrics.rowHeight)"),
            "`AppTabContent` no longer reserves the bar's height, so the bar covers the bottom of"
                + " every screen — and every screen that pins its own bottom bar loses it."
        )
        let root = try Self.appSource("RootView.swift")
        // The bar's own call site must sit under a `.bottom` overlay. Matched as two adjacent
        // lines rather than one blob so re-indenting the file cannot break the guard.
        let overlayLine = ".overlay(alignment: .bottom) {"
        let barLine = "AppTabBar(selection: $selectedTab, captureInboxCount: captureInboxCount)"
        let overlaidBar = root
            .components(separatedBy: overlayLine)
            .dropFirst()
            .contains { $0.prefix(200).contains(barLine) }
        XCTAssertTrue(
            overlaidBar,
            "The bar is no longer drawn as a bottom overlay over the reserved height."
        )
        XCTAssertFalse(
            root.contains("safeAreaInset(edge: .bottom, spacing: 0) {"),
            "The bar is a `safeAreaInset` again. That is the arrangement that sliced the Journal"
                + " composer in half — an outer inset does not reach past a child's NavigationStack."
        )
    }

    /// The capture disc, the offline sprint card and the focus timer bar all ride one stack, and
    /// its lift is measured from the top of the BAR. With the bar an overlay rather than an
    /// inset, `.bottom` means the safe area's bottom — so the bar's own height has to be in the
    /// sum, or E's 60pt gap puts the disc on the bar instead of above it.
    func testTheBottomFurnitureClearsTheBarsHeight() throws {
        XCTAssertTrue(
            try Self.appSource("RootBottomOverlay.swift")
                .contains("liftAboveBar + AppTabBarMetrics.rowHeight"),
            "The bottom furniture no longer adds the bar's height to its lift, so the capture disc"
                + " and the focus timer bar sit on top of the tab bar."
        )
    }

    /// **The trap this block actually hit.** `TabView` is a `UITabBarController`, and past five
    /// tabs UIKit folds the overflow into its `moreNavigationController` — which renders tabs
    /// five and six with a "More" back button and an edge-swipe to a list the app never shows.
    /// Hiding the bar does not undo it; dropping `.tabItem` does not either. Proven on the
    /// simulator with a six-tab probe: the sixth tab's accessibility tree still carried
    /// `AXUniqueId: "BackButton", AXLabel: "More"`.
    ///
    /// So the guard is that no `TabView` comes back. `AppTabContent` replaced it, and its own
    /// laziness and state retention are pinned by `AppTabVisitLogTests`.
    func testTheSignedInShellIsNotATabView() throws {
        let source = try Self.appSource("RootView.swift")
        XCTAssertFalse(
            source.contains("TabView("),
            "A `TabView` is back in RootView. With six tabs UIKit folds the last two into its"
                + " More navigation controller, which puts a \"More\" back button on Captures"
                + " and Tools — hiding the tab bar does not prevent it."
        )
        XCTAssertFalse(
            source.contains(".tabItem"),
            "`.tabItem` only means anything to a `TabView`, and this shell no longer has one."
        )
        XCTAssertTrue(
            source.contains("AppTabContent(selection: selectedTab)"),
            "RootView no longer uses `AppTabContent`, so whatever replaced it owes an answer to"
                + " the same three questions: laziness, scroll position, navigation depth."
        )
    }

    /// Superseded, not merely unused: E's morph (F-Tools-2-Morph) answers the same need as
    /// `tabBarMinimizeBehavior(.onScrollDown)` and the two must not both ship — one is a system
    /// behaviour on a bar that no longer exists.
    func testTheSystemMinimiseBehaviourIsGone() throws {
        XCTAssertFalse(
            try Self.appSource("RootView.swift").contains("minimizesTabBarOnScrollDown"),
            "`minimizesTabBarOnScrollDown()` is back. It drove the SYSTEM bar, which is now"
                + " hidden — so it would be a no-op competing with the custom bar's own morph."
        )
    }

    /// Every slot on the bar has a screen behind it.
    ///
    /// The `switch tab` inside `AppTabContent` is exhaustive over `AppTab`, so the COMPILER
    /// already refuses a tab with no screen — a stronger guarantee than any grep, and the reason
    /// the old `.tag(AppTab.…)` check is gone rather than rewritten. What is left to check is the
    /// other direction: that the bar's slot list and the enum have not come apart.
    func testEveryTabCaseHasASlotOnTheBar() {
        XCTAssertEqual(
            Set(AppTabBarPresentation.tabs.map(\.tab)), Set(AppTab.allCases),
            "A tab exists that the bar has no slot for. The bar is the only way in now, so that"
                + " tab is unreachable by any tap."
        )
    }

    func testTheToolsTabRendersToolsView() throws {
        XCTAssertTrue(
            try Self.appSource("RootView.swift").contains("ToolsView()"),
            "The Tools tab does not render `ToolsView`."
        )
    }

    /// The badge's one number reaches the bar. Without this the count could be fetched, stored
    /// and never displayed — the shape the tray wells were in before the tab took the badge.
    func testTheInboxCountReachesTheBar() throws {
        XCTAssertTrue(
            try Self.appSource("RootView.swift").contains("captureInboxCount: captureInboxCount"),
            "RootView keeps the inbox count and never hands it to the bar, so the Captures badge"
                + " can never appear however full the inbox gets."
        )
    }

    // MARK: - Reading the tree

    private static func appSource(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw BarSourceError.unreadable(url.path)
        }
        return text
    }

    /// Loud rather than skipped — a guard that quietly disables itself is the failure mode these
    /// tests exist to prevent.
    private enum BarSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from"
                    + " (`#filePath`)."
            }
        }
    }
}
