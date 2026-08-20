//
//  FocusActivityAttributes.swift
//  FocusTimerWidget
//
//  Compiled into BOTH the app and the widget extension (ActivityKit matches the Activity across
//  the two processes by this type), so it must stay free of app-module dependencies.
//  `nonisolated` because the app module compiles with default-MainActor isolation and the OS
//  encodes/decodes this state off the main actor.
//

import ActivityKit
import Foundation

@available(iOS 16.1, *)
nonisolated struct FocusActivityAttributes: ActivityAttributes {
    /// Everything sprint-specific lives in the content state — a replacement sprint is just a
    /// fresh Activity with fresh state — so the fixed attributes carry nothing.
    nonisolated struct ContentState: Codable, Hashable {
        var taskTitle: String
        var lifeAreaEmoji: String
        /// Total planned length including +30s/+5m extensions, for a truthful progress fill.
        var durationSeconds: Int
        /// When the countdown hits zero. While paused this is synthesized as `pausedAt` plus the
        /// frozen remainder, so `Text(timerInterval:pauseTime:)` renders the frozen clock — the
        /// OS formats every readout; neither process ever renders time per-second itself.
        var deadline: Date
        /// Non-nil while paused: the instant the countdown display is pinned to.
        var pausedAt: Date?
        var checkpointCount: Int
        var checkpointsReached: Int
        /// Set on the final frame of a naturally-finished sprint.
        var isCompleted: Bool

        var isPaused: Bool { pausedAt != nil }

        /// Whether the countdown has run out, judged against a caller-supplied `now`.
        ///
        /// Belt and braces for the one transition a locally-updated Activity can't be told about:
        /// when the sprint ends behind a locked screen, the app is suspended and cannot push a
        /// final frame. `isStale` covers this in principle, but it was observed NOT to have flipped
        /// on a real device — the Lock Screen still offered Pause/Stop on a sprint sitting at 0:00
        /// (E, 2026-08-20). Checking the deadline at render time closes that hole.
        ///
        /// Paused sprints are excluded deliberately: their `deadline` is synthesized from `pausedAt`
        /// plus the frozen remainder, so it slides into the past as real time passes and would
        /// otherwise report a paused sprint as finished.
        func hasElapsed(asOf now: Date) -> Bool {
            !isPaused && deadline <= now
        }

        /// The OS-rendered countdown range. The visual start is derived back from the deadline so
        /// the elapsed fraction stays truthful across pauses and extensions.
        var timerInterval: ClosedRange<Date> {
            deadline.addingTimeInterval(-TimeInterval(max(0, durationSeconds)))...deadline
        }

        /// Static 0–1 progress for the paused and completed presentations, where the OS timer
        /// view isn't running.
        var frozenProgress: Double {
            guard durationSeconds > 0 else { return 0 }
            if isCompleted { return 1 }
            let remaining = pausedAt.map { deadline.timeIntervalSince($0) } ?? 0
            return min(1, max(0, (Double(durationSeconds) - remaining) / Double(durationSeconds)))
        }

        /// The paused frame's readout, rendered as plain text because
        /// `Text(timerInterval:pauseTime:)` does not actually freeze inside Live Activity
        /// presentations (observed live on-device, 2026-08-19). Formatted like the OS timer's
        /// `showsHours: false` rendering — unpadded minutes, padded seconds, hours rolled into
        /// minutes — so pausing doesn't visibly shift the format. Meaningful only while paused.
        var frozenRemainingText: String {
            let remaining = max(0, Int((pausedAt.map { deadline.timeIntervalSince($0) } ?? 0).rounded()))
            return "\(remaining / 60):" + String(format: "%02d", remaining % 60)
        }
    }
}
