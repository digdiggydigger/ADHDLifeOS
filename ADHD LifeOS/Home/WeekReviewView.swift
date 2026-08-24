//
//  WeekReviewView.swift
//  ADHD LifeOS
//
//  S5 as shipped (block M6): the week's evidence — closures, focus stamina, the honest quiet —
//  derived locally and pushed from Home. The AI-written daily summary card stays where it was;
//  this is the numbers, with counterweights.
//

import SwiftUI

struct WeekReviewView: View {
    let review: MomentumWeekReview

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                barsCard
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
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("weekReviewView")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("The last seven days")
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

    /// One bar per day, oldest to today. Heights are proportional to the week's own best day —
    /// the chart compares this week with itself, not with an imagined quota.
    private var barsCard: some View {
        let peak = max(review.dayCounts.max() ?? 0, 1)
        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(zip(review.dayLabels, review.dayCounts).enumerated()), id: \.offset) { _, day in
                VStack(spacing: 4) {
                    Capsule()
                        .fill(day.1 > 0 ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color(.tertiarySystemFill)))
                        .frame(height: max(8, CGFloat(day.1) / CGFloat(peak) * 64))
                        .frame(maxHeight: 64, alignment: .bottom)
                    Text(day.0)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.0), \(day.1) closed")
            }
        }
        .bentoCard()
        .accessibilityIdentifier("weekReviewBars")
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
                            .foregroundStyle(.green)
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
#Preview("Light") {
    NavigationStack {
        WeekReviewView(review: MomentumWeekReview(
            headline: "8 closed · 220 focus minutes",
            dayCounts: [1, 0, 2, 1, 0, 3, 1],
            dayLabels: ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"],
            dopamineWins: ["Synthesized the user research", "Hydration goal two days running"],
            staminaLine: "83% of targeted minutes actually logged",
            quietLine: "Nothing closed in Hobbies this week, and 4 captures are still unfiled. "
                + "Neither is a failure — they are just what next week starts with.",
            kickstart: ["15 min · Sort the mail pile", "5 min · Bin the two oldest captures"]
        ))
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        WeekReviewView(review: MomentumWeekReview(
            headline: "0 closed · 0 focus minutes",
            dayCounts: [0, 0, 0, 0, 0, 0, 0],
            dayLabels: ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"],
            dopamineWins: [],
            staminaLine: nil,
            quietLine: nil,
            kickstart: []
        ))
    }
    .preferredColorScheme(.dark)
}
#endif
