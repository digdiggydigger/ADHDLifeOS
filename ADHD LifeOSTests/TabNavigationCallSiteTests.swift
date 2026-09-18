//
//  TabNavigationCallSiteTests.swift
//  ADHD LifeOSTests
//
//  Reachability for the tab re-tap rule (E, 2026-09-08). `TabNavigationTests` proves the
//  coordinator and the rule; nothing there proves a single tab root LISTENS. This repo has shipped
//  six defects where a helper was written, documented and unit-tested and then called by nothing,
//  so what a unit test CAN see — the modifier at each call site — is what this reads.
//
//  Comment lines are stripped before searching, the `ToolsPageCallSiteTests` scar.
//

import XCTest

final class TabNavigationCallSiteTests: XCTestCase {

    /// One file per tab, the file whose `NavigationStack` IS that tab.
    private static let tabRoots = [
        "Home/HomeView.swift",
        "Tasks/TaskListView.swift",
        "Areas/AreasView.swift",
        "Journal/JournalView.swift",
        "Capture/CaptureInboxView.swift",
        "Tools/ToolsView.swift"
    ]

    /// Where each tab's vertical scroll content lives — not always the root file.
    private static let tabScrollContent = [
        "Home/HomeView.swift",
        "Tasks/TaskListView.swift",
        "Areas/AreasView.swift",
        "Journal/JournalTimelineSections.swift",
        "Capture/CaptureInboxView.swift",
        "Tools/ToolsView.swift"
    ]

    func testEveryTabRootWiresTheCoordinator() throws {
        for path in Self.tabRoots {
            XCTAssertTrue(
                try Self.appCode(path).contains(".tabRoot("),
                "\(path) never calls `.tabRoot(`, so a re-tap on that tab does nothing — the rule"
                    + " exists and this screen cannot hear it."
            )
        }
    }

    func testEveryTabCarriesAScrollAnchorForTheTopLevelReTap() throws {
        for path in Self.tabScrollContent {
            XCTAssertTrue(
                try Self.appCode(path).contains(".tabRootScrollAnchor()"),
                "\(path) never applies `.tabRootScrollAnchor()`, so a re-tap at that tab's top"
                    + " level has nothing to scroll to."
            )
        }
    }

    func testTheBarRoutesARepeatTapThroughTheRule() throws {
        let bar = try Self.appCode("Theme/AppTabBar.swift")
        XCTAssertTrue(
            bar.contains("AppTabBarPresentation.tapOutcome("),
            "`AppTabBar` decides a tap without `tapOutcome`, so a repeat tap is whatever the"
                + " button happens to do rather than the rule."
        )
        XCTAssertTrue(
            bar.contains("onReselect("),
            "`AppTabBar` never calls `onReselect`, so the coordinator never hears a repeat tap."
        )
    }

    func testRootViewOwnsTheCoordinatorAndHandsTheBarItsReselect() throws {
        let root = try Self.appCode("RootView.swift")
        XCTAssertTrue(
            root.contains(".environmentObject(tabNavigation)"),
            "`RootView` does not inject `tabNavigation`, so no tab root can reach the coordinator."
        )
        XCTAssertTrue(
            root.contains("onReselect: reselectTab"),
            "`RootView` does not route the bar's `onReselect` through `reselectTab`, so the"
                + " coordinator never hears a repeat tap — or hears it without the capture disc."
        )
    }

    // MARK: - A scroll-to-top re-tap restores the capture disc (E's GIF, 2026-09-08)

    /// The rule can be right and the disc still stay a pill: `TabNavigationTests` proves
    /// `restoresCaptureDisc`, and only this proves the root ACTS on it. The pill's inputs are the
    /// pan gesture and the tab-change reset; a programmatic scroll is neither, so the root has
    /// to tell it. Read from `RootView+Reselect.swift` — the method lives there because
    /// `RootView.swift` sits at the 400-line bar (the doors precedent).
    func testAScrollToTopReTapRestoresTheCaptureDisc() throws {
        let reselect = try Self.appCode("RootView+Reselect.swift")
        XCTAssertTrue(
            reselect.contains("TabReselectionResponse.response(isAtRoot: tabNavigation.isAtRoot(tab))"),
            "`reselectTab` does not ask the rule which response the tab gets, so it cannot know"
                + " whether the page is about to scroll to the top."
        )
        XCTAssertTrue(
            reselect.contains("tabNavigation.reselect(tab)"),
            "`reselectTab` never tells the coordinator, so no tab root pops or scrolls."
        )
        XCTAssertTrue(
            reselect.contains("if response.restoresCaptureDisc {"),
            "`reselectTab` ignores `restoresCaptureDisc`, so the pill stays collapsed over a page"
                + " the re-tap has just scrolled to the top — E's GIF, unchanged."
        )
        XCTAssertTrue(
            reselect.contains("discScrollActivity.reset()"),
            "`reselectTab` decides the disc should restore and never resets the pill state."
        )
    }

    // MARK: - The re-tap brings a large title back (F-JournalPencilDisc)

    /// §7.4: BOTH branches by string. Step 0 proved the shipped `proxy.scrollTo` leaves a large
    /// title collapsed; the fix is iOS 26+ only (the overscroll that finds the expanded top was
    /// verified on 26.5 and 27.0 and nowhere below), with the shipped scroll as the floor — §7.1's
    /// DEGRADED shape. A test that pinned only the modern branch would stay green on a build that
    /// dropped the floor; one that pinned only the floor would miss the fix going dead.
    func testTheTopLevelReTapHasAModernTierAndTheShippedScrollAsItsFloor() throws {
        let code = try Self.flattenedAppCode("TabNavigation.swift")
        guard let gate = code.range(of: "if #available(iOS 26.0, *) {") else {
            return XCTFail("The re-tap has no iOS 26 gate, so the large-title fix is either absent or ungated.")
        }
        let modern = code[gate.upperBound...]
        guard let floor = modern.range(of: "} else {") else {
            return XCTFail("The iOS 26 gate has no `else`: below 26 a re-tap would do nothing at all.")
        }
        XCTAssertTrue(
            modern[..<floor.lowerBound].contains(
                "TabRootLargeTitleReTap.restore(scrollHandle.scrollView, reduceMotion: reduceMotion)"
            ),
            "The modern branch never asks the large-title fix, so Step 0's collapsed title ships."
        )
        XCTAssertTrue(
            modern[..<floor.lowerBound].contains("scrollToAnchor(proxy)"),
            "On 26+ a page with no large title has lost the shipped scroll — every other tab."
        )
        let floorBranch = modern[floor.upperBound...]
        XCTAssertTrue(
            floorBranch.prefix(80).contains("scrollToAnchor(proxy)"),
            "The floor branch no longer runs the shipped scroll, so below 26 a re-tap does nothing."
        )
        XCTAssertTrue(
            code.contains("proxy.scrollTo(TabRootScrollAnchor.id, anchor: .top)"),
            "The shipped `proxy.scrollTo` is gone — the floor has nothing to run."
        )
    }

    /// The fix FINDS the page's scroll view from inside its content, never by searching down from
    /// outside, where the chips' horizontal strip is a candidate too (memory `large-title-retap`).
    /// So the anchor carries a locator, and the root hands the anchor the handle it fills.
    func testTheScrollAnchorCarriesTheLocatorAndTheRootHandsItTheHandle() throws {
        let code = try Self.flattenedAppCode("TabNavigation.swift")
        XCTAssertTrue(
            code.contains(".environment(\\.tabRootScrollHandle, scrollHandle)"),
            "The tab root never hands its scroll handle down, so the anchor's locator fills nothing."
        )
        XCTAssertTrue(
            code.contains("TabRootScrollLocator(handle: handle)"),
            "The scroll anchor carries no locator, so the fix never finds a scroll view."
        )
    }

    // MARK: - No pushed screen without a way back (E's Nudges report)

    /// A pushed screen that hides the navigation bar has no back chevron, and this app's tab
    /// roots hide theirs on purpose — all but the Journal since `F-JournalPencilDisc` (2026-09-18),
    /// whose large title E kept ("Keep the nav bar"); the exemption below is by file, so it stays
    /// correct either way. Every OTHER screen that hides it must draw its own back
    /// control — `TaskDetailView`'s chevron is the house pattern — or E's "no way to get back
    /// to the Today main page" ships again on the next screen someone styles this way.
    func testNoPushedScreenHidesTheNavigationBarWithoutABackControl() throws {
        let rootNames = Set(Self.tabRoots.map { ($0 as NSString).lastPathComponent })
        let offenders = try Self.allAppCode()
            .filter { $0.code.contains(".toolbar(.hidden, for: .navigationBar)") }
            .filter { !rootNames.contains($0.name) }
            .filter { !$0.code.contains("chevron.backward") }
            .map(\.name)
            .sorted()
        XCTAssertEqual(
            offenders, [],
            "These pushed screens hide the navigation bar and draw no back control, so the only"
                + " way out is the edge swipe. Show the bar, or draw the `chevron.backward`"
                + " control `TaskDetailView` does."
        )
    }

    // MARK: - Tools pushes the way a re-tap can pop

    /// Probed on the simulator 2026-09-08: a closure-based `NavigationLink` push is invisible to
    /// its stack's `NavigationPath` and survives a path reset; only clearing a flag, or resetting
    /// a path that HOLDS a value, pops. Tools' top-level pushes were closure links, so nothing
    /// could pop them. They push by flag now; the closure links deeper in that stack collapse
    /// with the screen below them, which the same probe showed.
    func testToolsTopLevelPushesAreFlagsNotClosureLinks() throws {
        for path in ["Tools/ToolsView.swift", "Tools/ToolsRoutinesSection.swift"] {
            XCTAssertFalse(
                try Self.appCode(path).contains("NavigationLink {"),
                "\(path) still pushes with a closure-based `NavigationLink`, which a re-tap on"
                    + " Tools cannot pop."
            )
        }
        XCTAssertTrue(
            try Self.appCode("Tools/ToolsView.swift").contains("navigationDestination(isPresented:"),
            "`ToolsView` no longer pushes its destinations by flag."
        )
    }

    // MARK: - Reading the tree

    private static func stripComments(_ text: String) -> String {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }

    private static var appRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
    }

    private static func appCode(_ relativePath: String) throws -> String {
        let url = appRoot.appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw SourceError.unreadable(url.path)
        }
        return stripComments(text)
    }

    /// The same code on one line, each line trimmed and joined by a single space, so an anchor
    /// does not have to know how a call was wrapped.
    private static func flattenedAppCode(_ relativePath: String) throws -> String {
        try appCode(relativePath)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
    }

    private static func allAppCode() throws -> [(name: String, code: String)] {
        guard let walker = FileManager.default.enumerator(at: appRoot, includingPropertiesForKeys: nil) else {
            throw SourceError.unreadable(appRoot.path)
        }
        let swiftFiles = walker.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        guard !swiftFiles.isEmpty else { throw SourceError.unreadable(appRoot.path) }
        return try swiftFiles.map { url in
            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                throw SourceError.unreadable(url.path)
            }
            return (url.lastPathComponent, stripComments(text))
        }
    }

    private enum SourceError: Error, CustomStringConvertible {
        case unreadable(String)
        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from (`#filePath`)."
            }
        }
    }
}
