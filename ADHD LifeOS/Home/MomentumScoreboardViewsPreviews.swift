//
//  MomentumScoreboardViewsPreviews.swift
//  ADHD LifeOS
//
//  The scoreboard gallery previews, split out on the house pattern to keep
//  MomentumScoreboardViews.swift inside the 400-line file budget.
//

import SwiftUI

#if DEBUG
private struct MomentumScoreboardGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                MomentumRingCard(
                    closedToday: 2, goal: 5, streak: 7, bestStreak: 9, openCount: 3,
                    weekFlags: [true, true, true, true, true, true, false],
                    nextEffortLabel: "15 min"
                )
                BestNextMoveCard(
                    task: TaskSummary(
                        lifeAreaId: nil,
                        status: .open, title: "Sort through mail pile on kitchen counter",
                        priority: .p2, notes: "Trash junk mail immediately. Only keep bills to scan.",
                        dueDate: Date(), focusDurationSeconds: 900
                    ),
                    lifeArea: LifeArea(id: UUID(), name: "Admin", colour: "📝", sortOrder: 0),
                    isDueNow: true, isClosing: false, showsStartSession: true,
                    loggedTodayLabel: "1 session · 12 min today",
                    onClose: {}, onStartSession: {}
                )
                ClosureCelebrationCard(
                    taskTitle: "Sort through mail pile",
                    line: "Third today. Admin & Home is up to 75% this week.",
                    nextLabel: "Next: 20 min",
                    onUndo: {}, onNext: {}
                )
                AreaMomentumList(items: MomentumScoreboard.areaMomentum(
                    areas: [
                        LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 0),
                        LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 1)
                    ],
                    openTasks: [], allTasks: []
                ))
            }
            .padding(16)
        }
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    MomentumScoreboardGallery()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    MomentumScoreboardGallery()
        .preferredColorScheme(.dark)
}
#endif
