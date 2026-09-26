//
//  AreasWeekReviewDoor.swift
//  ADHD LifeOS
//
//  `F-E3-OneCardToday`, round 5b: *"Week review door → 'Both.' ... AND a row sits at the top of the
//  Areas tab."* The pushed half of that row: it reads the two streams the Areas tab never loads —
//  focus sessions and nudges — only once the review is actually opened, then shows the SAME review
//  Today's done line opens, built through `WeekReviewView(inputs:)`.
//

import SwiftUI

struct AreasWeekReviewDoor: View {
    let load: () async -> WeekReviewInputs
    @State private var inputs: WeekReviewInputs?

    var body: some View {
        // A real container, not `Group`: `Group` hands `.task` to each child, so the swap from the
        // spinner to the review would start the read a second time (`FocusAnalyticsSection`'s
        // lesson, 2026-08-19).
        ZStack {
            if let inputs {
                WeekReviewView(inputs: inputs)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.pageBackground.ignoresSafeArea())
                    .accessibilityIdentifier("areasWeekReviewLoading")
            }
        }
        .task { inputs = await load() }
    }
}

#if DEBUG
private enum AreasWeekReviewDoorPreviewData {
    static let inputs = WeekReviewInputs(
        tasks: [], lifeAreas: [], sessions: [], inboxCount: 2,
        openTaskCount: 5, areaCount: 4, dueNudgeCount: 1, focusDailyGoalMinutes: nil
    )
}

#Preview("Light") {
    NavigationStack {
        AreasWeekReviewDoor { AreasWeekReviewDoorPreviewData.inputs }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        AreasWeekReviewDoor { AreasWeekReviewDoorPreviewData.inputs }
    }
    .preferredColorScheme(.dark)
}
#endif
