//
//  FocusTimerWidgetLiveActivity.swift
//  FocusTimerWidget
//

import ActivityKit
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
/// semantic system colour.
///
/// The token is consumed by catalog name rather than `.tint`/`Color.accentColor` — Live Activity
/// presentations don't apply the widget's global accent (verified in-simulator: they fall back to
/// system blue) — and rather than the generated `Color.accent` symbol, whose `ColorResource` is
/// iOS 17+ against this target's 16.1 floor. Still the colorset token; zero hex in Swift (§4).
private extension Color {
    static let sprintAccent = Color("AccentColor")
}
struct FocusTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            FocusLiveActivityLockScreenView(state: context.state, isStale: isStale(context))
                .padding(16)
        } dynamicIsland: { context in
            let isComplete = context.state.isCompleted || isStale(context)
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
                    FocusSprintProgressTrack(state: context.state, isComplete: isComplete)
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

    private var isComplete: Bool { state.isCompleted || isStale }

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

                if !isComplete, state.checkpointCount > 0 {
                    Text("\(state.checkpointsReached) of \(state.checkpointCount) checkpoints")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// The single countdown readout every presentation shares. While paused it renders a static
/// string; when complete, a checkmark replaces it.
private struct FocusCountdownReadout: View {
    let state: FocusActivityAttributes.ContentState
    let isComplete: Bool
    /// Cap for the RUNNING timer text only — `Text(timerInterval:)` claims greedy width in the
    /// island's compact slots. The static branches size to their content and must NOT share the
    /// cap: it clipped the paused readout's leading digit ("13:50" → "3:50", observed
    /// in-simulator 2026-08-19).
    var timerMaxWidth: CGFloat?

    var body: some View {
        Group {
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
            } else if state.isPaused {
                // Static text, NOT `Text(timerInterval:pauseTime:)` — the pauseTime freeze does
                // not take effect inside Live Activity presentations (observed on-device), so a
                // "paused" sprint kept counting down. The engine's frozen remainder is rendered
                // directly instead.
                Text(state.frozenRemainingText)
                    .monospacedDigit()
            } else {
                Text(timerInterval: state.timerInterval, countsDown: true, showsHours: false)
                    .monospacedDigit()
                    .frame(maxWidth: timerMaxWidth, alignment: .trailing)
            }
        }
        .multilineTextAlignment(.trailing)
        // §1 layout safety: the island's trailing regions are narrow — scale, never wrap.
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

/// Progress fill: OS-animated while running, frozen while paused, full when complete.
private struct FocusSprintProgressTrack: View {
    let state: FocusActivityAttributes.ContentState
    let isComplete: Bool

    var body: some View {
        Group {
            if state.isPaused || isComplete {
                ProgressView(value: isComplete ? 1 : state.frozenProgress)
            } else {
                ProgressView(timerInterval: state.timerInterval, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            }
        }
        .progressViewStyle(.linear)
        .tint(Color.sprintAccent)
        .accessibilityHidden(true)
    }
}

/// Status copy shared by the Lock Screen and expanded island headers, so state is never conveyed
/// by colour alone.
private enum FocusActivityCopy {
    static func status(
        for state: FocusActivityAttributes.ContentState, isComplete: Bool
    ) -> String {
        if isComplete { return "Sprint complete" }
        return state.isPaused ? "Paused" : "Focus sprint"
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
