//
//  HomeView+TabRoot.swift
//  ADHD LifeOS
//

import SwiftUI

/// Today's answer to the tab re-tap (E's rule, 2026-09-08). Its own file because `HomeView.swift`
/// sits at the 400-line budget, and because listing every push in one place is the point: a
/// door added to Today that is not listed here is a door a re-tap cannot close.
extension HomeView {
    /// Every way Today can be deeper than its top-level page. Since `F-E3-OneCardToday` there are
    /// two: a task pushed from the one card's "then" list or the arrival card, and the week review
    /// the done line opens. (The nudges manager, the inbox peek's captures and the life-area rows
    /// left Today with their sections; Nudges' door is in Tools now.)
    var isAtTabRoot: Bool {
        inspectingTask == nil && !isPresentingWeekReview
    }

    /// Clears them all. Nested screens above any of these collapse with them (probed 2026-09-08).
    func popToTabRoot() {
        inspectingTask = nil
        isPresentingWeekReview = false
    }
}
