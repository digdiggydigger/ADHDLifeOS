//
//  JournalLargeTitleReTapTests.swift
//  ADHD LifeOSTests
//
//  `F-JournalPencilDisc`: E kept the Journal's nav bar and its large title, and Step 0 proved the
//  tab re-tap left that title COLLAPSED — `proxy.scrollTo(anchor: .top)` put the content at the
//  top of a 54pt bar and nothing brought the 106pt one back. This is Step 0's rig, committed: the
//  REAL `JournalView` in a real key window, scrolled by UIKit, re-tapped through the REAL
//  coordinator, and measured the way Step 0 measured it — the `UINavigationBar`'s height and the
//  scroll view's offset. Red on the shipped re-tap; green with the fix.
//
//  **iOS 26+ only, like the fix** (§7.1's degraded shape): the overscroll that finds the expanded
//  top was verified on 26.5 and 27.0 and nowhere below, so below 26 the shipped scroll stays and
//  these tests skip. Pure logic is in `TabRootReTapPlanTests`.
//

import SwiftUI
import UIKit
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class JournalLargeTitleReTapTests: XCTestCase {

    private var window: UIWindow!
    private var previousKeyWindow: UIWindow?
    private var coordinator: TabNavigationCoordinator!
    private var client: FakeJournalClientAdapting!

    /// Step 0's measurements, with slack for a pixel's rounding: 106 with the large title, 54 without.
    private static let largeTitleBar: CGFloat = 100
    private static let collapsedBar: CGFloat = 60

    override func setUp() async throws {
        try await super.setUp()
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("The large-title re-tap is iOS 26+; below it the shipped scroll is the floor.")
        }
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        )
        previousKeyWindow = scene.keyWindow
        coordinator = TabNavigationCoordinator()
        client = FakeJournalClientAdapting()
        client.logsResult = .success(Self.entries(count: 30))
        window = UIWindow(windowScene: scene)
        window.rootViewController = UIHostingController(
            rootView: JournalView(client: client).environmentObject(coordinator)
        )
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        // A `LazyVStack` grows its `contentSize` as rows materialise, so this asks only for enough
        // page to scroll Step 0's 420pt, not for the whole stream.
        try await waitUntil("the timeline to load and outgrow the screen") {
            (self.pageScrollView?.contentSize.height ?? 0) > self.window.bounds.height + 500
        }
        try await waitUntil("the large title at rest") { self.barHeight > Self.largeTitleBar }
    }

    override func tearDown() async throws {
        window?.rootViewController = nil
        window?.isHidden = true
        window = nil
        previousKeyWindow?.makeKeyAndVisible()
        try await super.tearDown()
    }

    // MARK: - The fix

    /// THE bug: scroll, re-tap, and the title must come back. Step 0: 54pt on the shipped re-tap.
    ///
    /// **Asserted on the SETTLED page, never on the first frame that looks right.** The first cut
    /// of this test waited for "bar > 100" and passed on the shipped code: the spring overshoots
    /// the plain top by ~6pt, the bar pops to 106 for about a quarter of a second, and then the
    /// spring settles back to −116 and the bar collapses to 54 again (a per-frame probe on 26.5,
    /// 2026-09-18). A condition poll catches the transient; what the user is left looking at is the
    /// settled state.
    func testAReTapAfterScrollingBringsTheLargeTitleBack() async throws {
        let scrollView = try XCTUnwrap(pageScrollView)
        let expandedTop = scrollView.contentOffset.y
        try await scroll(by: 420)
        try await waitUntil("the title to collapse under the scroll") { self.barHeight < Self.collapsedBar }

        coordinator.reselect(.journal)
        try await waitUntilSettled()

        XCTAssertGreaterThan(
            barHeight, Self.largeTitleBar, "The re-tap left the large title collapsed — Step 0's bug."
        )
        XCTAssertEqual(
            scrollView.contentOffset.y, expandedTop, accuracy: 1, "The re-tap did not land at the expanded top."
        )
    }

    /// A short scroll, where the bar has only begun to shrink, lands at the same place.
    func testAReTapAfterAShortScrollLandsAtTheExpandedTop() async throws {
        let scrollView = try XCTUnwrap(pageScrollView)
        let expandedTop = scrollView.contentOffset.y
        try await scroll(by: 30)

        coordinator.reselect(.journal)
        try await waitUntilSettled()

        XCTAssertGreaterThan(barHeight, Self.largeTitleBar, "A short scroll's re-tap left the title collapsed.")
        XCTAssertEqual(scrollView.contentOffset.y, expandedTop, accuracy: 1, "A short scroll's re-tap missed the top.")
    }

    /// Already at the top with the title out, a re-tap must not TAKE it in — the shipped
    /// `scrollTo` was measured putting the content at the top of a collapsed bar.
    func testAReTapAtRestLeavesTheLargeTitleExpanded() async throws {
        let scrollView = try XCTUnwrap(pageScrollView)
        let resting = scrollView.contentOffset.y

        coordinator.reselect(.journal)
        try await waitUntilSettled()

        XCTAssertGreaterThan(barHeight, Self.largeTitleBar, "A re-tap at rest collapsed the large title.")
        XCTAssertEqual(scrollView.contentOffset.y, resting, accuracy: 1, "A re-tap at rest moved the page.")
    }

    /// The probe writes an overscroll with no finger down, on a page that has `.refreshable`. The
    /// refresh control must not read that as a pull: a re-tap is not a reload.
    func testTheReTapDoesNotPullToRefresh() async throws {
        try await scroll(by: 420)
        let loads = client.fetchLogsCallCount

        coordinator.reselect(.journal)
        try await waitUntilSettled()

        XCTAssertEqual(client.fetchLogsCallCount, loads, "The re-tap's overscroll triggered a pull-to-refresh.")
    }

    // MARK: - The Reduce Motion branch, injected (§7.2: the setting cannot be set from here)

    /// Under Reduce Motion the page is simply THERE — no animation to wait for, so the title is out
    /// by the next layout pass.
    func testTheReducedPathJumpsStraightToTheExpandedTop() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("iOS 26+") }
        try await scroll(by: 420)
        try await waitUntil("the title to collapse under the scroll") { self.barHeight < Self.collapsedBar }
        let scrollView = try XCTUnwrap(pageScrollView)

        XCTAssertTrue(TabRootLargeTitleReTap.restore(scrollView, reduceMotion: true))
        window.layoutIfNeeded()

        XCTAssertGreaterThan(barHeight, Self.largeTitleBar, "The reduced re-tap left the title collapsed.")
        XCTAssertEqual(
            scrollView.contentOffset.y, -scrollView.adjustedContentInset.top, accuracy: 1,
            "The reduced re-tap did not land the content at the expanded top."
        )
    }

    // MARK: - The control: a page with no large title is handed back untouched

    /// Every other tab. The fix must find nothing, put the page back exactly where it was, and
    /// answer `false`, so the shipped `proxy.scrollTo` runs as it always has. Without this control
    /// the positive tests would pass just as well on a fix that re-drove every tab by UIKit.
    func testAPageWithoutALargeTitleIsHandedBackUntouched() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("iOS 26+") }
        window.rootViewController = UIHostingController(rootView: HiddenBarPage())
        window.layoutIfNeeded()
        try await waitUntil("the hidden-bar page to lay out") {
            (self.pageScrollView?.contentSize.height ?? 0) > self.window.bounds.height + 500
        }
        try await scroll(by: 300)
        let scrollView = try XCTUnwrap(pageScrollView)
        let resting = scrollView.contentOffset

        XCTAssertFalse(
            TabRootLargeTitleReTap.restore(scrollView, reduceMotion: false),
            "A page with no large title was taken off the shipped scroll."
        )
        XCTAssertEqual(scrollView.contentOffset, resting, "The probe did not put the page back where it was.")
    }

    // MARK: - The rig

    /// The four hidden-bar tabs' shape: a `NavigationStack` whose bar is hidden, over a tall page.
    private struct HiddenBarPage: View {
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(0..<40, id: \.self) { index in
                            Text("Row \(index)").frame(maxWidth: .infinity, minHeight: 60)
                        }
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    private static func entries(count: Int) -> [Log] {
        (0..<count).map { index in
            let date = Date().addingTimeInterval(-Double(index) * 20_000)
            return Log(
                id: UUID(), lifeAreaId: nil, type: .journal,
                body: "Entry \(index) — long enough to wrap onto a second line in the timeline's card.",
                entryDate: date, createdAt: date, energyLevel: .medium, moodEmoji: "⚡"
            )
        }
    }

    /// The page's own vertical scroll view: the tallest content in the window, so the chips' short
    /// horizontal strip is never it.
    private var pageScrollView: UIScrollView? {
        Self.all(UIScrollView.self, in: window).max { $0.contentSize.height < $1.contentSize.height }
    }

    private var barHeight: CGFloat {
        Self.all(UINavigationBar.self, in: window).first { !$0.isHidden }?.frame.height ?? 0
    }

    private static func all<T: UIView>(_ type: T.Type, in root: UIView?) -> [T] {
        guard let root else { return [] }
        return root.subviews.flatMap { subview -> [T] in
            (subview as? T).map { [$0] + all(type, in: subview) } ?? all(type, in: subview)
        }
    }

    /// UIKit scrolls, as Step 0 did — the offset written with no finger down, then laid out.
    private func scroll(by distance: CGFloat) async throws {
        let scrollView = try XCTUnwrap(pageScrollView, "No scroll view to scroll.")
        scrollView.setContentOffset(
            CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y + distance), animated: false
        )
        window.layoutIfNeeded()
        try await settle(0.3)
    }

    private func settle(_ seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        window.layoutIfNeeded()
    }

    /// Until the page has stopped moving: the offset and the bar unchanged for 0.4s straight. The
    /// shipped spring takes ~0.5s and overshoots on the way, so anything sooner reads a transient.
    private func waitUntilSettled(timeout: TimeInterval = 4) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        var last = (offset: CGFloat.nan, bar: CGFloat.nan)
        var stillSince = Date()
        while Date() < deadline {
            let now = (offset: pageScrollView?.contentOffset.y ?? .nan, bar: barHeight)
            if abs(now.offset - last.offset) >= 0.5 || now.bar != last.bar {
                last = now
                stillSince = Date()
            } else if Date().timeIntervalSince(stillSince) >= 0.4 {
                return
            }
            try await Task.sleep(nanoseconds: 16_000_000)
            window.layoutIfNeeded()
        }
        XCTFail("The page never settled after the re-tap. Bar \(barHeight)pt, offset \(last.offset).")
    }

    /// A DEADLINE, not an iteration count — memory `test-vacuity-mutation-check`: a count that is
    /// ample idle is not ample inside a 3,000-test suite.
    private func waitUntil(
        _ what: String, timeout: TimeInterval = 4, _ condition: @escaping () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                let offset = pageScrollView.map {
                    "\($0.contentOffset.y) (top inset \($0.adjustedContentInset.top), content \($0.contentSize.height))"
                }
                XCTFail("Timed out waiting for \(what). Bar \(barHeight)pt, offset \(offset ?? "no scroll view").")
                throw XCTSkip("stopped: \(what)")
            }
            try await Task.sleep(nanoseconds: 20_000_000)
            window.layoutIfNeeded()
        }
    }
}
