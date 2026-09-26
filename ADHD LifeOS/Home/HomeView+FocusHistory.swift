//
//  HomeView+FocusHistory.swift
//  ADHD LifeOS
//
//  `F-E3-OneCardToday`: Home reads the focus history itself.
//
//  It used to arrive through `FocusAnalyticsSection`'s load callback — the charts owned the fetch
//  and handed Home a copy. Round 3 took both charts off Today (*"Both charts come off Today"*), and
//  that copy is not only theirs: `publishedHistory` feeds the weekly chain's "finished a sprint"
//  signal (so the gain line on Close), the week review, and the Home Screen widget. Deleting the
//  section alone would have blanked all four without failing a single test of theirs.
//

import SwiftUI

extension HomeView {
    /// Called from `.task(id: focusReloadToken + pullRefreshCount)` — the charts' three triggers:
    /// first load, a pull, and every finished sprint.
    ///
    /// A failed read keeps the last good history rather than publishing an empty one, as the
    /// section's callback did: republishing zeros over a good snapshot would blank the widget for
    /// a transient network error.
    func loadFocusHistory() async {
        guard let sessions = try? await focusHistoryReader.fetchHistory() else { return }
        publishedHistory = sessions
        publishWidgetSnapshot(sprint: widgetSprint)
    }
}
