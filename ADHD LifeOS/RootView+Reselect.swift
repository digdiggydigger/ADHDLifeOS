//
//  RootView+Reselect.swift
//  ADHD LifeOS
//
//  The bar's repeat tap, out of `RootView.swift` for the reason the doors are: that file sits
//  at SwiftLint's 400-line bar. The two members this touches are `internal` on RootView with a
//  comment saying why — Swift `private` is file-scoped, the HomeView.arrangeAreas precedent.
//

import SwiftUI

extension RootView {
    /// Routes a tap on the already-selected tab (E's rule, 2026-09-08) into the coordinator —
    /// and, when the tab is at its top-level page so the answer is a scroll to the top, restores
    /// the capture disc from its pill.
    ///
    /// **Why the disc needs telling (E's GIF, 2026-09-08 evening).** The pill's only inputs are
    /// the window-level pan gesture's finger travel and the reset on a tab change. A re-tap's
    /// scroll-to-top is `proxy.scrollTo` — a programmatic scroll with no touch — so the pan
    /// recogniser reports nothing and the pill stayed collapsed over a page sitting at the top,
    /// while the tab bar, which reads the scroll view's offset, restored on its own. E's
    /// 2026-08-31 rule is "stay in pill form until the page is scrolled upwards again"; this IS
    /// that scroll, so it is the second restore that isn't a gesture, beside the tab change. A
    /// pop-to-root re-tap leaves the pill alone: the list comes back at its old offset.
    func reselectTab(_ tab: AppTab) {
        let response = TabReselectionResponse.response(isAtRoot: tabNavigation.isAtRoot(tab))
        tabNavigation.reselect(tab)
        if response.restoresCaptureDisc {
            discScrollActivity.reset()
        }
    }
}
