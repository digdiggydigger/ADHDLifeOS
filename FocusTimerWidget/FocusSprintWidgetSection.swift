//
//  FocusSprintWidgetSection.swift
//  FocusTimerWidget
//

import SwiftUI

/// A running sprint together with the moment to render it against.
///
/// Bundled rather than passed as two parameters precisely so they cannot drift: every readout the
/// live section shows is derived against this date, and taking it from `Date()` instead of the
/// timeline entry would defeat the entries that keep the checkpoint count moving.
struct FocusWidgetLiveSprint {
    let sprint: FocusWidgetSnapshot.ActiveSprint
    let now: Date
}

/// The Home Screen widget's live-sprint block: what you are focusing on, how long is left, and how
/// many checkpoints have gone by.
///
/// It stands in for the Active Goal block while a sprint is running, because in that moment the
/// sprint IS the goal — showing "start a session" beside a session already in flight is the same
/// mistake Home's hero used to make.
///
/// The clock is rendered by the OS from the deadline (`Text(timerInterval:)`), never by this
/// process: a widget is drawn once and then sits there, and anything this extension formatted
/// itself would be wrong within a second.
struct FocusSprintWidgetSection: View {
    let sprint: FocusWidgetSnapshot.ActiveSprint
    /// The timeline ENTRY's date, not `Date()`. The checkpoint count is derived against it, and the
    /// timeline carries an entry at every checkpoint — which is how the count keeps moving while the
    /// app is suspended and unable to publish.
    let now: Date
    /// Sized down for the small family, where the block shares 158pt with the week's total.
    var isCompact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            FocusWidgetLabel(text: sprint.isPaused ? "Sprint paused" : "Sprint running")

            // The title gets a row to itself. Sharing one with the countdown clipped it to
            // "Testing…" in the medium family, where the live block only owns half the widget
            // (observed in-simulator, 2026-08-20): `Text(timerInterval:)` claims its width first
            // and the title pays for it.
            HStack(alignment: .top, spacing: 4) {
                Text(sprint.emoji)
                    .font(.caption)
                Text(sprint.taskTitle)
                    .font(titleFont)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                countdown

                if let summary = sprint.checkpointSummary(asOf: now) {
                    Text(summary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var titleFont: Font {
        isCompact ? .footnote.weight(.bold) : .subheadline.weight(.bold)
    }

    @ViewBuilder
    private var countdown: some View {
        Group {
            if let interval = sprint.timerInterval {
                Text(timerInterval: interval, countsDown: true, showsHours: false)
                    // `Text(timerInterval:)` claims greedy width; cap it so the checkpoint caption
                    // beside it keeps its share of the row (the same trap the island's compact slot
                    // hit). Leading-aligned here — this is a readout, not a right-hand column.
                    .frame(maxWidth: 56, alignment: .leading)
            } else {
                // Paused: there is no deadline to count to, so the frozen remainder is rendered as
                // plain text — formatted the same way the OS timer would have.
                Text(sprint.frozenRemainingText)
            }
        }
        .font(.footnote.monospacedDigit().weight(.bold))
        .foregroundStyle(Color("AccentColor"))
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

#if DEBUG
private let runningSprint = FocusWidgetSnapshot.ActiveSprint(
    taskTitle: "Draft the quarterly review", emoji: "💼", durationSeconds: 900,
    deadline: Date().addingTimeInterval(420), pausedRemainingSeconds: nil,
    checkpointSeconds: [225, 450, 675]
)

private let pausedSprint = FocusWidgetSnapshot.ActiveSprint(
    taskTitle: "Draft the quarterly review", emoji: "💼", durationSeconds: 900,
    deadline: nil, pausedRemainingSeconds: 420, checkpointSeconds: [225, 450, 675]
)

private struct FocusSprintSectionGallery: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FocusSprintWidgetSection(sprint: runningSprint, now: Date())
            FocusSprintWidgetSection(sprint: pausedSprint, now: Date())
            FocusSprintWidgetSection(sprint: runningSprint, now: Date(), isCompact: true)
                .frame(width: 126)
        }
        .padding(16)
        .background(Color("PageBackground"))
    }
}

#Preview("Light") {
    FocusSprintSectionGallery()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FocusSprintSectionGallery()
        .preferredColorScheme(.dark)
}
#endif
