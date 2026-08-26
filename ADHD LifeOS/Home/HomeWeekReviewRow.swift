//
//  HomeWeekReviewRow.swift
//  ADHD LifeOS
//
//  Today's week-review door, split from HomeMomentumSections on the house pattern to
//  keep that file inside the 400-line budget.
//

import SwiftUI

extension HomeView {
    var weekReviewRow: some View {
        Button {
            isPresentingWeekReview = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.accentColor)
                Text("Week review")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .bentoCard()
        .accessibilityIdentifier("homeWeekReviewRow")
    }

    var weekReviewDestination: some View {
        WeekReviewView(
            review: MomentumWeekReview.build(
                tasks: homeService.allTasks,
                lifeAreas: homeService.lifeAreas,
                sessions: publishedHistory,
                inboxCount: inboxCount
            ),
            summaryCounts: WeekReviewSummaryCounts(
                open: homeService.openTasks.count,
                areas: homeService.activeAreas.count,
                inbox: inboxCount,
                dueNudges: nudgesService.dueNudges().count
            )
        )
    }
}
