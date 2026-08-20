//
//  FocusActivityComponents.swift
//  FocusTimerWidget
//
//  The pieces the Lock Screen banner and the Dynamic Island both draw. Split out of
//  `FocusTimerWidgetLiveActivity` when the progress track grew checkpoint markers — that file was
//  approaching the 400-line budget, and these are genuinely shared between two presentations.
//

import SwiftUI

/// The coral token, consumed by catalog NAME rather than `.tint`/`Color.accentColor` — Live Activity
/// presentations don't apply the widget's global accent (verified in-simulator: they fall back to
/// system blue) — and rather than the generated `Color.accent` symbol, whose `ColorResource` is
/// iOS 17+ against this target's 16.1 floor. Still the colorset token; zero hex in Swift (§4).
extension Color {
    static let sprintAccent = Color("AccentColor")
}

/// Progress fill with the sprint's checkpoint markers standing on it.
///
/// The fill itself is OS-animated while running (`ProgressView(timerInterval:)`, so neither process
/// renders time per second), frozen while paused and full when complete. The markers are drawn on
/// top from the content state's positions — before this, the banner showed a bare bar and the
/// checkpoints the sprint was actually built around were invisible on the Lock Screen.
@available(iOS 16.1, *)
struct FocusSprintProgressTrack: View {
    let state: FocusActivityAttributes.ContentState
    let isComplete: Bool

    /// Tall enough for the 12pt "next" marker and its ring to sit centred on the 4pt bar without
    /// clipping; the bar centres itself inside it.
    private let trackHeight: CGFloat = 16

    var body: some View {
        ZStack {
            fill
            markers
        }
        .frame(height: trackHeight)
        // The "N of M checkpoints" caption beside the track carries this in words, so the markers
        // never have to be interpreted by colour — or read out twice (§4).
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var fill: some View {
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
    }

    private var markers: some View {
        GeometryReader { geometry in
            ForEach(state.checkpointMarks(isComplete: isComplete)) { mark in
                FocusCheckpointMarker(state: mark.state)
                    .position(
                        // Inset by the marker's radius so a mark at 0 or 1 stands ON the track
                        // rather than half-off its end.
                        x: markerCentre(fraction: mark.fraction, width: geometry.size.width),
                        y: geometry.size.height / 2
                    )
            }
        }
    }

    private func markerCentre(fraction: Double, width: CGFloat) -> CGFloat {
        let radius = FocusCheckpointMarker.maximumDiameter / 2
        let usable = max(0, width - FocusCheckpointMarker.maximumDiameter)
        return radius + usable * fraction
    }
}

/// A single checkpoint dot.
///
/// The palette mirrors the app-side `FocusCheckpointDotState` exactly (E's 2026-08-20 direction:
/// reached green, next `.primary`, pending a muted grey that still reads on the coral fill), so the
/// floating bar, the sprint modal and the Lock Screen all mark a checkpoint the same way. The two
/// can't share one type — `FocusCheckpointDotState` resolves from a `FocusSession`, which is an
/// app-target model the extension has no access to — so the parity is deliberate duplication.
struct FocusCheckpointMarker: View {
    let state: FocusActivityCheckpointMark.State

    /// The largest dot the track has to make room for.
    static let maximumDiameter: CGFloat = 12

    var body: some View {
        Circle()
            .fill(fillColor)
            .frame(width: diameter, height: diameter)
            // The next marker is bigger AND ringed, so it is identifiable by SHAPE and not only by
            // colour (§4).
            .overlay {
                if state == .next {
                    Circle().strokeBorder(Color(.systemBackground), lineWidth: 2)
                }
            }
    }

    private var fillColor: Color {
        switch state {
        case .reached: return .green
        case .next: return .primary
        case .pending: return Color(.tertiaryLabel)
        }
    }

    private var diameter: CGFloat {
        state == .next ? Self.maximumDiameter : 8
    }
}

/// The single countdown readout every presentation shares. While paused it renders a static string;
/// when complete, a checkmark replaces it.
@available(iOS 16.1, *)
struct FocusCountdownReadout: View {
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

/// The "N of M checkpoints" caption. One view rather than two copies of the same modifiers, because
/// it now appears on the Lock Screen banner, in the island's expanded region, and on both surfaces'
/// completed frame.
@available(iOS 16.1, *)
struct FocusCheckpointCaption: View {
    let state: FocusActivityAttributes.ContentState
    let isComplete: Bool

    var body: some View {
        if let summary = state.checkpointSummary(isComplete: isComplete) {
            Text(summary)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

/// Status copy shared by the Lock Screen and expanded island headers, so state is never conveyed
/// by colour alone.
@available(iOS 16.1, *)
enum FocusActivityCopy {
    static func status(
        for state: FocusActivityAttributes.ContentState, isComplete: Bool
    ) -> String {
        if isComplete { return "Sprint complete" }
        return state.isPaused ? "Paused" : "Focus sprint"
    }
}
