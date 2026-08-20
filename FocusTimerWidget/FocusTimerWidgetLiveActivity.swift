//
//  FocusTimerWidgetLiveActivity.swift
//  FocusTimerWidget
//

import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// The focus sprint's Lock Screen banner and Dynamic Island presentations.
///
/// The OS renders the countdown itself from the content state's deadline
/// (`Text(timerInterval:)` / `ProgressView(timerInterval:)`), so the app only pushes updates on
/// pause/resume/extend/stop and checkpoint crossings — required on a free developer account
/// (locally-updated Activities only) and kinder to an ADHD focus path anyway: the Activity never
/// flickers with per-second churn.
///
/// §4 note: the extension can't see the app's asset catalog, so the coral `AccentColor` colorset
/// is duplicated into this target's catalog (hex stays in colorsets only) and everything else is
/// semantic system colour. The shared pieces — the marked progress track, the countdown readout,
/// the checkpoint caption — live in `FocusActivityComponents`.
struct FocusTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            FocusLiveActivityLockScreenView(state: context.state, isStale: isStale(context))
                .padding(16)
        } dynamicIsland: { context in
            let isComplete = context.state.isCompleted || isStale(context)
                || context.state.hasElapsed(asOf: Date())
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.lifeAreaEmoji)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(FocusActivityCopy.status(for: context.state, isComplete: isComplete))
                            .font(.caption2.monospaced().weight(.bold))
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                        Text(context.state.taskTitle)
                            .font(.footnote.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    FocusCountdownReadout(state: context.state, isComplete: isComplete, timerMaxWidth: 72)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.sprintAccent)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        FocusSprintProgressTrack(state: context.state, isComplete: isComplete)

                        HStack(spacing: 8) {
                            // The expanded island drew the track but never said how many
                            // checkpoints the sprint had passed — the one number the markers
                            // beneath it can only hint at. It now reads out on every frame,
                            // finished ones included.
                            FocusCheckpointCaption(state: context.state, isComplete: isComplete)

                            Spacer(minLength: 0)

                            if !isComplete, #available(iOS 17.0, *) {
                                FocusSprintControls(state: context.state)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Text(context.state.lifeAreaEmoji)
            } compactTrailing: {
                FocusCountdownReadout(state: context.state, isComplete: isComplete, timerMaxWidth: 56)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.sprintAccent)
            } minimal: {
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.sprintAccent)
                } else {
                    Text(context.state.lifeAreaEmoji)
                }
            }
            .keylineTint(Color.sprintAccent)
        }
    }

    /// `isStale` (16.2+) flips when the deadline-derived stale date passes while the app is
    /// suspended — the one transition a locally-updated Activity can't be told about.
    private func isStale(_ context: ActivityViewContext<FocusActivityAttributes>) -> Bool {
        guard #available(iOS 16.2, *) else { return false }
        return context.isStale
    }
}

/// The Lock Screen / banner presentation, extracted so it previews on its own (§6).
struct FocusLiveActivityLockScreenView: View {
    let state: FocusActivityAttributes.ContentState
    let isStale: Bool

    /// `Date()` at render time, not a stored value: the Activity re-renders on every push and when
    /// the system marks it stale, and on those renders this is what catches a sprint that ended
    /// while the app was suspended.
    private var isComplete: Bool { state.isCompleted || isStale || state.hasElapsed(asOf: Date()) }

    // Prominence pass (E, 2026-08-19): the countdown is the hero — a large coral numeral rather
    // than the earlier small pill — with 16pt group separation so the banner reads airy, not
    // cramped, at a glance.
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(state.lifeAreaEmoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(FocusActivityCopy.status(for: state, isComplete: isComplete))
                        .font(.caption2.monospaced().weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(isComplete ? Color.sprintAccent : Color.secondary)
                    Text(state.taskTitle)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 8)

                FocusCountdownReadout(state: state, isComplete: isComplete)
                    .font(.title.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.sprintAccent)
            }

            VStack(alignment: .leading, spacing: 8) {
                FocusSprintProgressTrack(state: state, isComplete: isComplete)

                HStack(spacing: 8) {
                    // Shown on the completed frame too, where it becomes the acknowledgement:
                    // "3 of 3 checkpoints" is what the sprint actually achieved.
                    FocusCheckpointCaption(state: state, isComplete: isComplete)

                    Spacer(minLength: 0)

                    if !isComplete, #available(iOS 17.0, *) {
                        FocusSprintControls(state: state)
                    }
                }
            }
        }
    }
}

/// The sprint controls, mirroring the in-app bar: pause/resume in coral, stop in red. Their
/// `LiveActivityIntent`s run in the app's process, so they drive the real engine — no push
/// plumbing, works on the free account.
///
/// iOS 17+ (`Button(intent:)`); on 16.x the Activity stays display-only. Two §-notes for the
/// build report: §3's 44pt targets can't fit the Live Activity's 160pt height cap alongside the
/// prominence layout (these sit at ~38pt, the size the system Timer Activity uses), and §3's
/// custom pressed-scale ButtonStyle can't run in archived Activity rendering — the system
/// provides its own press highlight.
@available(iOS 17.0, *)
private struct FocusSprintControls: View {
    let state: FocusActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 8) {
            Button(intent: PauseResumeFocusSprintIntent()) {
                Label(
                    state.isPaused ? "Resume" : "Pause",
                    systemImage: state.isPaused ? "play.fill" : "pause.fill"
                )
                .font(.caption.weight(.bold))
                .padding(.vertical, 4)
            }
            .tint(Color.sprintAccent)

            Button(intent: StopFocusSprintIntent()) {
                Label("Stop", systemImage: "stop.fill")
                    .font(.caption.weight(.bold))
                    .padding(.vertical, 4)
            }
            .tint(.red)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .lineLimit(1)
        // The buttons never truncate ("Resume" → "Res…"); the checkpoint caption beside them
        // scales down instead.
        .fixedSize()
    }
}

#if DEBUG
private extension FocusActivityAttributes.ContentState {
    static func sample(pausedAt: Date? = nil, isCompleted: Bool = false) -> Self {
        FocusActivityAttributes.ContentState(
            taskTitle: "Draft the quarterly review",
            lifeAreaEmoji: "💼",
            durationSeconds: 900,
            deadline: Date().addingTimeInterval(600),
            pausedAt: pausedAt,
            checkpointCount: 3,
            checkpointsReached: 1,
            checkpointSeconds: [225, 450, 675],
            isCompleted: isCompleted
        )
    }
}

#Preview("Lock Screen — Light") {
    VStack(spacing: 16) {
        FocusLiveActivityLockScreenView(state: .sample(), isStale: false)
        FocusLiveActivityLockScreenView(state: .sample(pausedAt: Date()), isStale: false)
        FocusLiveActivityLockScreenView(state: .sample(isCompleted: true), isStale: false)
    }
    .padding(16)
    .preferredColorScheme(.light)
}

#Preview("Lock Screen — Dark") {
    VStack(spacing: 16) {
        FocusLiveActivityLockScreenView(state: .sample(), isStale: false)
        FocusLiveActivityLockScreenView(state: .sample(pausedAt: Date()), isStale: false)
        FocusLiveActivityLockScreenView(state: .sample(isCompleted: true), isStale: false)
    }
    .padding(16)
    .preferredColorScheme(.dark)
}
#endif
