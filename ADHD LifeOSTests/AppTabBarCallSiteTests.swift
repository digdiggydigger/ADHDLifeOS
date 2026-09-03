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

    /// **Content must run BEHIND the bar, not stop above it.**
    ///
    /// This flipped twice. The bar began as a `safeAreaInset`; E's screenshot showed the Journal
    /// composer sliced in half by it, because a SwiftUI safe-area inset does not cross into a
    /// child's own `NavigationStack`. The fix was to reserve the bar's height in the container —
    /// which worked, and was wrong: a reserve is a strip of dead layout the page cannot enter, so
    /// the bar sat on a plinth. E: *"I'd much rather the background surrounding the nav bar is
    /// transparent so that I can see the content scrolling behind it."*
    ///
    /// So the inset is back and the reserve is gone, with the two screens that pin their own
    /// furniture asking for room explicitly. Both halves are asserted, because either alone is a
    /// bug: an inset with a reserve double-counts the height, and a reserve without the inset is
    /// the plinth E rejected.
    func testTheBarIsASafeAreaInsetAndTheContainerReservesNothing() throws {
        let root = try Self.appSource("RootView.swift")
        XCTAssertTrue(
            root.contains("safeAreaInset(edge: .bottom, spacing: 0) {"),
            "The tab bar is no longer a bottom safe-area inset, so scroll views are not inset for"
                + " it and the last row of every screen sits under the bar unreachable."
        )
        let container = try Self.appSource("AppTabContent.swift")
        XCTAssertFalse(
            container.contains("frame(height: AppTabBarMetrics.rowHeight)"),
            "`AppTabContent` is reserving the bar's height again. That is the plinth: content"
                + " stops above the bar instead of scrolling behind it."
        )
    }

    /// The two screens that pin their OWN bottom furniture inside a `NavigationStack`, and so
    /// never inherit the bar's inset. A helper nothing calls is this repo's most repeated defect,
    /// so the call sites are enumerated rather than the definition.
    func testEveryTabLevelPinnedBarAsksForTabBarClearance() throws {
        for (file, furniture) in [
            ("Journal/JournalView.swift", "composerBar"),
            ("Capture/CaptureInboxView.swift", "bottomBar")
        ] {
            XCTAssertTrue(
                try Self.appSource(file)
                    .contains(".safeAreaInset(edge: .bottom) { \(furniture).appTabBarClearance() }"),
                "\(file) pins `\(furniture)` without `appTabBarClearance()`, so it sits under the"
                    + " tab bar — the Journal composer's caption line is what this looked like."
            )
        }
    }

    /// **This assertion used to say the opposite, and it was enforcing a bug.**
    ///
    /// The claim was: the bar is a `safeAreaInset`, so `.bottom` alignment in the overlay already
    /// means the top of the bar, and adding the bar's height would double-count. That is not what
    /// SwiftUI does. An `.overlay(alignment: .bottom)` resolves `.bottom` against the screen's
    /// ORIGINAL safe area, so the furniture was being lifted 60pt off the home indicator rather
    /// than 60pt off the bar — and the capture disc overlapped the bar by 7pt on E's iPhone 15 Pro
    /// (disc frame bottom 758pt, bar top 751pt). E reported it as missing spacing between the bar
    /// and the collapsed pill.
    ///
    /// Proven by a controlled probe, not by reading: adding the bar's height moved the disc's
    /// frame bottom from 779.8 to 721.8 against an unchanged bar top of ~772.
    func testTheBottomFurnitureIsLiftedFromTheTopOfTheBar() throws {
        let source = try Self.appSource("RootBottomOverlay.swift")
        XCTAssertTrue(
            source.contains("AppSearchRowMetrics.bottomFurnitureLift"),
            "The bottom furniture is no longer lifted by the bar's height. `.bottom` in this"
                + " overlay is the screen's safe area, not the top of the bar, so without it the"
                + " capture disc sits ON the bar — which is what E photographed."
        )
        XCTAssertGreaterThan(
            AppSearchRowMetrics.bottomFurnitureLift, AppTabBarMetrics.rowHeight,
            "The lift no longer clears the bar at all, so the furniture overlaps it."
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

    // MARK: - The morph (F-Tools-2-Morph)

    /// **The failure mode this guards is silent.** Both window-level observers are idempotent via
    /// `guard shared == nil`, and **the FIRST install's callbacks win** — a second call no-ops,
    /// the model never hears anything, and the bar simply never moves. Nothing errors; nothing
    /// logs. So each is installed exactly once, and each install's callback is asserted.
    func testEachWindowObserverIsInstalledExactlyOnceAndFeedsItsModel() throws {
        let source = try Self.appSource("RootView.swift")
        XCTAssertEqual(
            source.components(separatedBy: "CaptureDiscPanObserver.installOnKeyWindow").count - 1, 1,
            "The disc's pan observer is installed more than once. The second silently no-ops."
        )
        XCTAssertEqual(
            source.components(separatedBy: "AppScrollOffsetObserver.installOnKeyWindow").count - 1, 1,
            "The scroll-offset observer is installed more than once. The second silently no-ops."
        )
        XCTAssertTrue(
            source.contains("onDragMoved: discScrollActivity.dragMoved"),
            "The disc's model is no longer fed by its observer, so the capture disc can never"
                + " collapse to its pill."
        )
        XCTAssertTrue(
            source.contains("tabBarScrollActivity.offsetChanged(distanceFromTop: distance)"),
            "`TabBarScrollActivity` is not fed any scroll offsets, so the bar never morphs —"
                + " and nothing errors to tell you."
        )
    }

    /// E's rule for the bar is about POSITION, and E's follow-up answer kept the DISC on its own
    /// gesture rule. Mixing them would quietly re-litigate a decision E has now made twice.
    func testTheBarReadsPositionAndTheDiscStillReadsTheGesture() throws {
        let bar = try Self.appSource("Theme/TabBarScrollActivity.swift")
        XCTAssertTrue(
            bar.contains("distanceFromTop"),
            "The bar's model no longer reads scroll position, so \"hold until near the top\""
                + " cannot be what it implements."
        )
        XCTAssertFalse(
            bar.contains("translationY"),
            "The bar's model is reading pan translation again. Translation cannot answer"
                + " \"are we near the top\" — that is why it reads offsets."
        )
        XCTAssertTrue(
            try Self.appSource("Theme/CaptureDiscScrollActivity.swift").contains("translationY"),
            "The DISC's model stopped reading the gesture. Its rule is E's 2026-08-31 call and"
                + " was explicitly left alone when the bar's changed."
        )
    }

    /// A tab change resets BOTH, for the same reason: a bar stuck mid-morph, or a disc stuck as
    /// a pill, on a screen the user never scrolled reads as a bug.
    func testATabChangeResetsBothScrollModels() throws {
        let source = try Self.appSource("RootView.swift")
        XCTAssertTrue(source.contains("discScrollActivity.reset()"))
        XCTAssertTrue(
            source.contains("tabBarScrollActivity.reset()"),
            "Switching tabs leaves the bar in whatever shape the last scroll left it."
        )
    }

    /// The bar has to be TOLD which shape to be. Without this the model can be perfectly
    /// correct, perfectly tested, and drive nothing — this repo's most repeated defect.
    func testTheFloatingFlagReachesTheBar() throws {
        XCTAssertTrue(
            try Self.appSource("RootView.swift")
                .contains("isFloating: tabBarScrollActivity.isFloating"),
            "`TabBarScrollActivity` is never handed to `AppTabBar`, so the bar cannot morph."
        )
    }

    /// The disc's own model must keep the behaviour E settled on 2026-08-31. The morph is
    /// momentary; the disc is sticky; they are deliberately no longer in lockstep.
    func testTheDiscsStickyModelWasNotEditedIntoATimer() throws {
        let source = try Self.appSource("Theme/CaptureDiscScrollActivity.swift")
        XCTAssertFalse(
            source.contains("Timer") || source.contains("asyncAfter") || source.contains("sleep"),
            "A timer has appeared in the DISC's activity model. Its stickiness is E's settled"
                + " call — the momentary signal belongs in `TabBarScrollActivity`, not here."
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
