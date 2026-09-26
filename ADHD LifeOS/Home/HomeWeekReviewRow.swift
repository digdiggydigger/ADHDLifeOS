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

    /// Through `WeekReviewView(inputs:)`, the one construction both doors share (`F-E3`), so
    /// Today's review and the Areas tab's can never be built from different parts.
    var weekReviewDestination: some View {
        WeekReviewView(inputs: WeekReviewInputs(
            tasks: homeService.allTasks,
            lifeAreas: homeService.lifeAreas,
            sessions: publishedHistory,
            inboxCount: inboxCount,
            openTaskCount: homeService.openTasks.count,
            areaCount: homeService.activeAreas.count,
            dueNudgeCount: nudgesService.dueNudges().count
        ))
    }
}
