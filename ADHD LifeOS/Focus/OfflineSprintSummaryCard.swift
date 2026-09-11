//
//  OfflineSprintSummaryCard.swift
//  ADHD LifeOS
//

import SwiftUI

/// The confirmation card for a sprint that finished while the app was dead (E's review note,
/// 2026-08-25): on relaunch the progress must be SEEN, not silently filed into history. Same
/// green-washed v3 language as the closure celebration, shown above the timer bar's slot until
/// acknowledged — and it survives further relaunches until then.
///
/// **Not the completion card, and deliberately not unified with it.** `FocusCompletionCard` (the
/// F-FocusCard arc) is the LIVE path: a sprint that ends while the app is running. This is the
/// app-was-dead path only, reached from `restorePersistedSprint()`, with its own UserDefaults key
/// (`unacknowledgedCompletion`) and its own published property; there is no migration between
/// the two. E kept them separate on 2026-09-09. The two can co-exist in `RootBottomOverlay`'s
/// column — see the note there — which is documented and unfixed by decision.
struct OfflineSprintSummaryCard: View {
    let record: CompletedFocusSession
    let onAcknowledge: () -> Void

    /// "25 of 25 minutes logged · 2 checkpoints" — pure, locked by tests.
    static func summaryLine(for record: CompletedFocusSession) -> String {
        let minutes = "\(record.focusedSeconds / 60) of \(record.plannedSeconds / 60) minutes logged"
        guard record.checkpointsReached > 0 else { return minutes }
        let checkpoints = record.checkpointsReached == 1
            ? "1 checkpoint"
            : "\(record.checkpointsReached) checkpoints"
        return "\(minutes) · \(checkpoints)"
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color("StateGo"))
            Text("Sprint finished while you were away")
                .sectionLabel()
                .foregroundStyle(.secondary)
            Text("\(record.lifeAreaEmoji) \(record.taskTitle)")
                .font(.headline)
                .tracking(-0.5)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(Self.summaryLine(for: record))
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Button("Got it", action: onAcknowledge)
                .buttonStyle(MomentumSolidButtonStyle(fill: Color("StateGo"), foreground: Color("OnStateGo")))
                .accessibilityIdentifier("offlineSprintSummaryDismissButton")
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color("StateGo").opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color("StateGo").opacity(0.3), lineWidth: 1)
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("offlineSprintSummaryCard")
    }
}

#if DEBUG
#Preview("Light") {
    OfflineSprintSummaryCard(
        record: CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Break down Q3 Project Proposal",
            lifeAreaEmoji: "💼", plannedSeconds: 1500, focusedSeconds: 1500,
            checkpointsReached: 2, completedNaturally: true, startedAt: .now, endedAt: .now
        ),
        onAcknowledge: {}
    )
    .padding(16)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    OfflineSprintSummaryCard(
        record: CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Break down Q3 Project Proposal",
            lifeAreaEmoji: "💼", plannedSeconds: 1500, focusedSeconds: 1500,
            checkpointsReached: 2, completedNaturally: true, startedAt: .now, endedAt: .now
        ),
        onAcknowledge: {}
    )
    .padding(16)
    .preferredColorScheme(.dark)
}
#endif
