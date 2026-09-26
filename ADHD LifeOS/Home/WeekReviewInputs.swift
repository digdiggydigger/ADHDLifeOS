//
//  WeekReviewInputs.swift
//  ADHD LifeOS
//
//  `F-E3-OneCardToday`, round 5b: *"Week review door → 'Both.'"* — Today's done line AND a row at
//  the top of the Areas tab. Two doors must open ONE review: the same week, the same counts, and so
//  the same AI summary. Each door gathers these inputs from what it holds, and both build the view
//  through `WeekReviewView(inputs:)`, so neither can assemble the review from loose parts of its own
//  (`TodayOneCardCallSiteTests` holds that).
//

import Foundation

struct WeekReviewInputs: Equatable {
    let tasks: [TaskItem]
    let lifeAreas: [LifeArea]
    let sessions: [CompletedFocusSession]
    let inboxCount: Int
    let openTaskCount: Int
    /// Unarchived areas only — what Today has always counted for the summary.
    let areaCount: Int
    let dueNudgeCount: Int
}

extension WeekReviewView {
    init(inputs: WeekReviewInputs) {
        self.init(
            review: MomentumWeekReview.build(
                tasks: inputs.tasks,
                lifeAreas: inputs.lifeAreas,
                sessions: inputs.sessions,
                inboxCount: inputs.inboxCount
            ),
            summaryCounts: WeekReviewSummaryCounts(
                open: inputs.openTaskCount,
                areas: inputs.areaCount,
                inbox: inputs.inboxCount,
                dueNudges: inputs.dueNudgeCount
            )
        )
    }
}
