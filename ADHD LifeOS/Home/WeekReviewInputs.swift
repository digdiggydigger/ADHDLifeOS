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
    /// The Settings focus goal, minutes a day (`F-E4`). NOT defaulted, so neither door can forget
    /// it: `nil` is "no goal", and the one chart draws no goal bar at all (`F-E1`).
    let focusDailyGoalMinutes: Int?
}

extension WeekReviewView {
    init(inputs: WeekReviewInputs, asOf now: Date = .now, calendar: Calendar = .current) {
        self.init(
            review: MomentumWeekReview.build(
                tasks: inputs.tasks,
                lifeAreas: inputs.lifeAreas,
                sessions: inputs.sessions,
                inboxCount: inputs.inboxCount,
                asOf: now,
                calendar: calendar
            ),
            summaryCounts: WeekReviewSummaryCounts(
                open: inputs.openTaskCount,
                areas: inputs.areaCount,
                inbox: inputs.inboxCount,
                dueNudges: inputs.dueNudgeCount
            ),
            // `F-E4`, round 3: "Keep the Mon–Sun bars" — the calendar week of measured focus.
            focusWeek: FocusAnalytics.currentWeek(sessions: inputs.sessions, now: now, calendar: calendar),
            dailyGoalMinutes: inputs.focusDailyGoalMinutes ?? 0
        )
    }
}
