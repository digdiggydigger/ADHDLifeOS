//
//  HomeView+TabRoot.swift
//  ADHD LifeOS
//

import SwiftUI

/// Today's answer to the tab re-tap (E's rule, 2026-09-08). Its own file because `HomeView.swift`
/// sits at the 400-line budget, and because listing every push in one place is the point: a
/// door added to Today that is not listed here is a door a re-tap cannot close.
extension HomeView {
    /// Every way Today can be deeper than its top-level page: the four flag pushes, and the
    /// life-area rows, which push by VALUE into `homePath`.
    var isAtTabRoot: Bool {
        !isPresentingNudges && inspectingHomeCapture == nil && inspectingTask == nil
            && !isPresentingWeekReview && homePath.isEmpty
    }

    /// Clears them all. Nested screens above any of these collapse with them (probed 2026-09-08).
    func popToTabRoot() {
        isPresentingNudges = false
        inspectingHomeCapture = nil
        inspectingTask = nil
        isPresentingWeekReview = false
        homePath = NavigationPath()
    }
}
