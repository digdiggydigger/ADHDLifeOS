//
//  RootView+Furniture.swift
//  ADHD LifeOS
//
//  The bottom furniture's three derived members, moved out of `RootView.swift` in
//  `F-CTACelebrations-3`'s room-first commit: that file stood at 394 lines against SwiftLint's 400
//  ceiling, and the block adds a mount, an environment pair and a `@StateObject` to it.
//
//  **Nothing here changed except its file and its access level.** `private` in Swift is FILE-scoped,
//  so a member moved to an extension file stops being visible to the body that reads it — the trap
//  `F-CTACelebrations-1` paid for four times. All three are `internal` for exactly that reason, and
//  so is `RootView.captureInboxCount`, which `refreshCaptureInboxCount()` writes.
//

import SwiftUI

extension RootView {
    /// What the bottom row searches RIGHT NOW: the selected tab's scope, masked to `.none` while
    /// that tab is deeper than its top-level page (F-TabDepth-2 — E's screenshot of a pushed
    /// task detail with "Search tasks" still beside the disc). The depth is what every tab root
    /// reports into the coordinator, so this file never learns how each tab pushes.
    var searchScope: AppSearchScope {
        AppSearchScope.scope(for: selectedTab, isAtRoot: tabNavigation.isAtRoot(selectedTab))
    }

    /// The pill is a STICKY scrolled-down state (F-PillStay, E's call 2026-08-31: "stay in
    /// pill form until the page is scrolled upwards again"). An open fan forces the full disc:
    /// its scrim blocks scrolling anyway, and the ✕ rotation reads as a disc, not a sliver.
    var showsPill: Bool {
        discScrollActivity.prefersPill && !isFabOpen
    }

    /// The tab badge's one writer. A failure leaves the previous number standing rather than
    /// dropping to zero: an offline moment is not an empty inbox.
    func refreshCaptureInboxCount() async {
        guard let captures = try? await captureClient.fetchUnprocessedCaptures() else { return }
        captureInboxCount = captures.count
    }
}
