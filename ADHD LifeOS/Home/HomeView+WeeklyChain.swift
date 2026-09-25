//
//  HomeView+WeeklyChain.swift
//  ADHD LifeOS
//
//  `F-E1-WeeklyChain`: Home is the one screen that holds all four of the chain's signals — closed
//  tasks (`homeService.allTasks`), finished sprints (`publishedHistory`), sorted captures and
//  journal lines — so it is the one screen whose "makes today count" can never under-report.
//  In its own file because `HomeView.swift` sits at SwiftLint's 400-line budget; only the two
//  stored stamp arrays had to live on the type.
//

import SwiftUI

extension HomeView {
    /// Everything that made a day active, as Home knows it.
    var activitySignals: WeeklyActiveChain.Signals {
        WeeklyActiveChain.Signals(
            tasks: homeService.allTasks,
            sessions: publishedHistory,
            capturesCleared: clearedCaptureStamps,
            journalLines: journalLineStamps
        )
    }

    /// Round 8b's condition for the gain line on the close button.
    var hasCountedToday: Bool {
        WeeklyActiveChain.hasCountedToday(activitySignals)
    }

    /// The journal signal: every line's `createdAt`, the "fetch all, filter client-side" shape
    /// `closedThisWeek` already uses on `allTasks`. With no journal client (previews, tests) or a
    /// failed fetch, the last known stamps stand — a missing signal can only under-report.
    func refreshJournalLines() async {
        guard let logs = try? await journalClient?.fetchLogs() else { return }
        journalLineStamps = logs.map(\.createdAt)
    }
}
