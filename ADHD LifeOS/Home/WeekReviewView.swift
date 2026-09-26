//
//  WeekReviewView.swift
//  ADHD LifeOS
//
//  S5 in the v3 voice (F-V3-WeekReview): the week's evidence — closures in closure-green,
//  focus stamina, the honest quiet — derived locally, with the AI-written summary card living
//  HERE now rather than on Today (v3: the recap is weekly evidence, not a daily verdict).
//

import SwiftUI

/// The AI-written summary's inputs, carried into the review by Home.
struct WeekReviewSummaryCounts: Equatable {
    let open: Int
    let areas: Int
    let inbox: Int
    let dueNudges: Int
}

struct WeekReviewView: View {
    let review: MomentumWeekReview
    /// When present, the AI summary card moves here from Today (v3's S5: the recap is weekly
    /// evidence, not a daily verdict). `nil` hides it (previews).
    var summaryCounts: WeekReviewSummaryCounts?
    /// The review's ONE chart (`F-E4`): Monday–Sunday focus minutes, oldest first.
    var focusWeek: [FocusDayBucket] = []
    /// 0 = no goal set, so no goal bar (`F-E1`).
    var focusDailyGoalMinutes: Int = 0

    init(
        review: MomentumWeekReview,
        summaryCounts: WeekReviewSummaryCounts? = nil,
        focusWeek: [FocusDayBucket] = [],
        dailyGoalMinutes: Int = 0
    ) {
        self.review = review
        self.summaryCounts = summaryCounts
        self.focusWeek = focusWeek
        self.focusDailyGoalMinutes = dailyGoalMinutes
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                // Round 3: "One bar chart in Week review" — the Mon–Sun focus bars replace the
                // rolling closures bars; closures stay as words below (the headline, the wins).
                WeeklyFocusSummaryWidget(buckets: focusWeek, dailyGoalMinutes: focusDailyGoalMinutes)
                if !review.dopamineWins.isEmpty {
                    winsSection
                }
                if let staminaLine = review.staminaLine {
                    labelledCard("Focus stamina", body: staminaLine, identifier: "weekReviewStamina")
                }
                if let quietLine = review.quietLine {
                    labelledCard("Quiet this week", body: quietLine, identifier: "weekReviewQuiet")
                }
                if !review.kickstart.isEmpty {
                    kickstartSection
                }
                if let counts = summaryCounts {
                    DailySummaryView(
                        openTaskCount: counts.open,
                        lifeAreaCount: counts.areas,
                        inboxCount: counts.inbox,
                        dueNudgeCount: counts.dueNudges
                    )
                }
            }
            .padding(16)
        }
        .captureDiscClearance()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("weekReviewView")
    }

    /// "Sunday · 8–14 Aug" — v3's eyebrow: today's weekday and the rolling window it closes.
    private var windowLine: String {
        let today = Date()
        let start = Calendar.current.date(byAdding: .day, value: -6, to: today) ?? today
        let range = "\(start.formatted(.dateTime.day()))–\(today.formatted(.dateTime.day().month(.abbreviated)))"
        return "\(today.formatted(.dateTime.weekday(.wide))) · \(range)"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(windowLine)
                .sectionLabel()
                .foregroundStyle(Color.accentColor)
            Text("Week review")
                .font(.largeTitle.bold())
                .tracking(-0.5)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(review.headline)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("weekReviewHeader")
    }

    private var winsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dopamine wins")
                .sectionLabel()
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(review.dopamineWins, id: \.self) { win in
                    Label {
                        Text(win)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color("StateGo"))
                    }
                }
            }
            .bentoCard()
        }
        .accessibilityIdentifier("weekReviewWins")
    }

    private var kickstartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gentle kickstart")
                .sectionLabel()
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(review.kickstart, id: \.self) { line in
                    Label {
                        Text(line)
                            .font(.subheadline)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "arrow.right.circle")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .bentoCard()
        }
        .accessibilityIdentifier("weekReviewKickstart")
    }

    private func labelledCard(_ title: String, body text: String, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .sectionLabel()
                .foregroundStyle(.secondary)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .bentoCard()
        }
        .accessibilityIdentifier(identifier)
    }
}

#if DEBUG
/// A deterministic Monday-first week — no `Date()` drift between snapshots.
private func previewFocusWeek() -> [FocusDayBucket] {
    let monday = Date(timeIntervalSince1970: 1_786_924_800)
    return [25, 50, 0, 75, 30, 0, 45].enumerated().map { index, minutes in
        FocusDayBucket(
            date: monday.addingTimeInterval(TimeInterval(index * 86_400)),
            focusedSeconds: minutes * 60, sessionCount: minutes > 0 ? 1 : 0, completedCount: minutes > 0 ? 1 : 0
        )
    }
}

#Preview("Light") {
    NavigationStack {
        WeekReviewView(review: MomentumWeekReview(
            headline: "8 closed · 220 focus minutes",
            dopamineWins: ["Synthesized the user research", "Hydration goal two days running"],
            staminaLine: "83% of targeted minutes actually logged",
            quietLine: "Nothing closed in Hobbies this week, and 4 captures are still unfiled. "
                + "Neither is a failure — they are just what next week starts with.",
            kickstart: ["15 min · Sort the mail pile", "5 min · Bin the two oldest captures"]
        ), focusWeek: previewFocusWeek(), dailyGoalMinutes: 45)
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        WeekReviewView(review: MomentumWeekReview(
            headline: "0 closed · 0 focus minutes",
            dopamineWins: [],
            staminaLine: nil,
            quietLine: nil,
            kickstart: []
        ))
    }
    .preferredColorScheme(.dark)
}
#endif
