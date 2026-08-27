//
//  NudgeDueCard.swift
//  ADHD LifeOS
//

import SwiftUI

/// A due nudge as v3's card: the label large, the green "Done for now", and — once the stamps have
/// accrued — the streak dots with their honest line.
///
/// Lifted out of `NudgesView` when nudges lost their tab (E, 2026-08-28) and Today became the
/// place a due nudge is met. Both screens render THIS, rather than each keeping a copy: a card
/// that drifts between the two surfaces is a nudge that looks like two different things depending
/// on where you happened to meet it. The dismiss identifier travels with it, so the UI journey
/// finds the same control on either screen.
struct NudgeDueCard: View {
    let nudge: Nudge
    /// The Settings charts/streaks preference, resolved by the caller — this view reads no
    /// defaults of its own so a preview can render both faces.
    let showStreaks: Bool
    let onDismiss: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(nudge.label)
                .font(.title3.bold())
                .tracking(-0.3)
            Text(NudgeSchedule.summary(cronString: nudge.schedule) ?? nudge.schedule)
                .font(.footnote)
                .foregroundStyle(.secondary)
            if showStreaks, let dates = nudge.completionDates, !dates.isEmpty {
                streak(dates)
            }
            Button("Done for now") {
                Haptics.play(.light)
                Task { await onDismiss() }
            }
            .buttonStyle(MomentumSolidButtonStyle(fill: Color("StateGo"), foreground: Color("OnStateGo")))
            .accessibilityLabel("Dismiss \(nudge.label)")
            .accessibilityIdentifier("nudgeDismissButton-\(nudge.id)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoCard()
    }

    @ViewBuilder
    private func streak(_ dates: [Date]) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(NudgeStreak.weekFlags(dates: dates).enumerated()), id: \.offset) { _, hit in
                Circle()
                    .fill(hit ? Color("StateGoVivid") : Color("TrackNeutralStrong"))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityHidden(true)
        if let line = NudgeStreak.line(dates: dates) {
            Text(line)
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
private struct NudgeDueCardPreview: View {
    private static let sample = Nudge(
        id: UUID(),
        label: "Stretch your back",
        schedule: "0 9 * * 0,1,2,3,4,5,6",
        active: true,
        completionDates: [
            Date().addingTimeInterval(-86_400), Date().addingTimeInterval(-2 * 86_400)
        ],
        createdAt: Date(),
        updatedAt: Date()
    )

    var body: some View {
        VStack(spacing: 16) {
            NudgeDueCard(nudge: Self.sample, showStreaks: true, onDismiss: {})
            NudgeDueCard(nudge: Self.sample, showStreaks: false, onDismiss: {})
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    NudgeDueCardPreview().preferredColorScheme(.light)
}

#Preview("Dark") {
    NudgeDueCardPreview().preferredColorScheme(.dark)
}
#endif
