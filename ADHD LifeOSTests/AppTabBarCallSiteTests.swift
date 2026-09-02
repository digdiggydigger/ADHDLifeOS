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

    /// The bar is added as a bottom safe-area INSET, not an overlay. It is what keeps every
    /// screen's own bottom inset — and therefore the capture disc, the focus timer bar and
    /// `captureDiscClearance()` — measured from the top of the bar rather than from the screen
    /// edge. An overlay would put the bar on top of the last row of every scroll.
    func testTheBarIsASafeAreaInsetRatherThanAnOverlay() throws {
        let source = try Self.appSource("RootView.swift")
        XCTAssertTrue(
            source.contains("safeAreaInset(edge: .bottom, spacing: 0) {"),
            "The tab bar is no longer a bottom safe-area inset. Whatever replaced it must still"
                + " reserve its own height, or it covers the bottom row of every screen."
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
