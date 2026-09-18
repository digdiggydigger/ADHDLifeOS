//
//  TabRootLargeTitleReTap.swift
//  ADHD LifeOS
//
//  `F-JournalPencilDisc`: E kept the Journal's system nav bar and its large title ("Keep the nav
//  bar"), and Step 0 proved the tab re-tap could not bring that title back. After a scroll the
//  shipped `proxy.scrollTo(anchor: .top)` lands the content at the top of the COLLAPSED bar — 54pt,
//  offset −116 — measured on 26.5 and 27.0 (memory `large-title-retap`). A per-frame probe then
//  showed why the spring hides it: it overshoots the plain top by ~6pt, the bar pops to 106 for a
//  quarter of a second, and it collapses again as the spring settles.
//
//  A UIKit offset to the EXPANDED top restores the title (106pt, −168), and an overscroll written
//  with no finger down comes to rest at that top by itself — so the fix FINDS the top rather than
//  hard-coding the 52pt band, which grows with Dynamic Type. That behaviour was verified on 26.5 and
//  27.0 only; below 26 a bar that stretches with the overscroll could leave the page displaced by a
//  whole screen, worse than a collapsed title. So the fix is iOS 26+ with the shipped scroll as the
//  floor (§7.1's DEGRADED shape), and every page with no large title — every other tab — is handed
//  straight back to the shipped scroll, untouched.
//

import SwiftUI
import UIKit

/// What a top-level re-tap does with the page, from what the probe found. Offsets are
/// `contentOffset.y`: more negative is further UP. Pure, so `TabRootReTapPlanTests` holds it.
enum TabRootReTapPlan: Equatable {
    /// The shipped `proxy.scrollTo` — every page with no large title above its plain top.
    case scrollToAnchor
    /// Reduce Motion: straight to the expanded top. A scroll to the top is re-positioning, not an
    /// appearance, and the shipped re-tap was already instant under Reduce Motion.
    case jump(toTop: CGFloat)
    /// UIKit's own animated scroll-to-top — the status-bar tap's (Step 0's R3). Not the house
    /// spring (§5): SwiftUI cannot address an offset above the content's top, which is where the
    /// large title lives.
    case animate(toTop: CGFloat)

    /// Half a point is a pixel at 2×, not a large title.
    private static let tolerance: CGFloat = 0.5

    static func plan(plainTop: CGFloat, expandedTop: CGFloat, reduceMotion: Bool) -> TabRootReTapPlan {
        guard expandedTop < plainTop - tolerance else { return .scrollToAnchor }
        return reduceMotion ? .jump(toTop: expandedTop) : .animate(toTop: expandedTop)
    }
}

/// The re-tap's hands on UIKit. iOS 26+ only — see the file header.
@available(iOS 26.0, *)
@MainActor
enum TabRootLargeTitleReTap {
    /// Brings a collapsed large title back, or answers `false` — having put the page back exactly
    /// where it was — so the caller runs the shipped scroll untouched.
    static func restore(_ scrollView: UIScrollView?, reduceMotion: Bool) -> Bool {
        guard let scrollView, let window = scrollView.window,
              hasVisibleNavigationBar(scrollView) else { return false }
        let resting = scrollView.contentOffset
        let plainTop = -scrollView.adjustedContentInset.top
        // A screen's height above the plain top, with no finger down: UIKit brings a large-title
        // page to rest at its EXPANDED top by itself (Step 0, R4/R5), and moves nothing else.
        scrollView.setContentOffset(
            CGPoint(x: resting.x, y: plainTop - scrollView.bounds.height), animated: false
        )
        window.layoutIfNeeded()
        let expandedTop = -scrollView.adjustedContentInset.top

        switch TabRootReTapPlan.plan(plainTop: plainTop, expandedTop: expandedTop, reduceMotion: reduceMotion) {
        case .scrollToAnchor:
            scrollView.setContentOffset(resting, animated: false)
            window.layoutIfNeeded()
            return false
        case .jump(let top):
            scrollView.setContentOffset(CGPoint(x: resting.x, y: top), animated: false)
            return true
        case .animate(let top):
            // Back where the user was first, so the scroll up starts from there.
            scrollView.setContentOffset(resting, animated: false)
            window.layoutIfNeeded()
            scrollView.setContentOffset(CGPoint(x: resting.x, y: top), animated: true)
            return true
        }
    }

    /// No visible bar, no large title to bring back — and no probe. The four tabs that hide their
    /// bars are left exactly as they were: the probe's overscroll would otherwise reach the floating
    /// tab bar through `AppScrollOffsetObserver`'s KVO as an un-float then a re-float before the
    /// real scroll. Found through the responder chain, the way UIKit itself finds a view's owner.
    private static func hasVisibleNavigationBar(_ view: UIView) -> Bool {
        var responder: UIResponder? = view
        while let current = responder {
            if let controller = current as? UIViewController, let navigation = controller.navigationController {
                return !navigation.isNavigationBarHidden
            }
            responder = current.next
        }
        return false
    }
}

/// Where a tab root's re-tap finds its page's `UIScrollView`: a locator view planted INSIDE the
/// scroll content by `tabRootScrollAnchor()`, so the first scroll view above it is the page's own.
/// Searching DOWN from outside would find the chips' horizontal strip as readily as the page.
final class TabRootScrollHandle {
    weak var locator: UIView?

    var scrollView: UIScrollView? {
        locator.flatMap(AppScrollOffsetObserver.enclosingScrollView(of:))
    }
}

private struct TabRootScrollHandleKey: EnvironmentKey {
    static let defaultValue: TabRootScrollHandle? = nil
}

extension EnvironmentValues {
    /// Set by `tabRoot(_:isAtRoot:onPopToRoot:)`; `nil` outside a tab root, where an anchor's
    /// locator simply fills nothing and the re-tap keeps the shipped scroll.
    var tabRootScrollHandle: TabRootScrollHandle? {
        get { self[TabRootScrollHandleKey.self] }
        set { self[TabRootScrollHandleKey.self] = newValue }
    }
}

/// An invisible, untouchable view whose only job is to be found.
struct TabRootScrollLocator: UIViewRepresentable {
    let handle: TabRootScrollHandle?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        handle?.locator = view
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        handle?.locator = uiView
    }
}
