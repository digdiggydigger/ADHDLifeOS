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

    /// **A covered system bar still eats touches**, so "hidden" has to mean hidden. The modifier
    /// goes on the views INSIDE the `TabView` — a `.toolbar` modifier looks UP for the bar it
    /// governs, so applied to the container it finds nothing and the system bar survives.
    func testEveryTabHidesTheSystemBar() throws {
        let source = try Self.appSource("RootView.swift")
        let hides = source.components(separatedBy: ".toolbar(.hidden, for: .tabBar)").count - 1
        XCTAssertEqual(
            hides, AppTabBarPresentation.tabs.count,
            "There are \(AppTabBarPresentation.tabs.count) tabs but \(hides) hide the system bar."
                + " Any tab that does not gets the system bar back, under ours, still hittable."
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

    /// The sixth tab has to be tagged AND rendered. A slot in `AppTabBarPresentation.tabs` with
    /// no matching `.tag` in the `TabView` is a button that selects a tab that does not exist.
    func testEverySlotHasATaggedTabInTheTabView() throws {
        let source = try Self.appSource("RootView.swift")
        for slot in AppTabBarPresentation.tabs {
            XCTAssertTrue(
                source.contains(".tag(AppTab.\(slot.tab))"),
                "`\(slot.tab)` is a slot on the bar with no tagged tab in the TabView — tapping"
                    + " it would select a tab that renders nothing."
            )
        }
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
