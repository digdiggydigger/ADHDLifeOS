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
        /// Elapsed-second offsets of every checkpoint in the sprint's plan.
        ///
        /// Counts alone cannot be DRAWN — the banner has to know where each mark stands on the
        /// track — and the positions are not derivable from the count either: a mid-sprint cadence
        /// re-plan keeps every fired mark exactly where it was and re-spaces only what is still
        /// ahead, so an evenly-spaced guess would move marks the sprint has already passed.
        var checkpointSeconds: [Int]
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

        /// The checkpoint markers to draw on the progress track.
        ///
        /// Fired marks are always the LEADING PREFIX of the plan — `FocusCheckpoints.replanned`
        /// preserves that invariant across a mid-sprint re-plan — so `checkpointsReached` alone
        /// separates reached from pending, and the mark sitting at exactly that index is the one
        /// coming up.
        ///
        /// `isComplete` covers the sprint that ran out behind a locked screen: the app was
        /// suspended and could not push the final count, but every checkpoint sits strictly before
        /// the finish, so a finished sprint has passed all of them. Drawing one as "up next" on a
        /// completed card would be a lie.
        func checkpointMarks(isComplete: Bool = false) -> [FocusActivityCheckpointMark] {
            guard durationSeconds > 0 else { return [] }
            let reached = isComplete ? checkpointSeconds.count : checkpointsReached
            return checkpointSeconds.enumerated().map { index, seconds in
                FocusActivityCheckpointMark(
                    index: index,
                    fraction: min(1, max(0, Double(seconds) / Double(durationSeconds))),
                    state: index < reached ? .reached : (index == reached ? .next : .pending)
                )
            }
        }

        /// "1 of 3 checkpoints" — the caption the Lock Screen banner and the island's expanded
        /// region share. `nil` when the sprint plans no checkpoints at all.
        func checkpointSummary(isComplete: Bool = false) -> String? {
            FocusCheckpointCopy.summary(
                reached: isComplete ? checkpointCount : checkpointsReached, total: checkpointCount
            )
        }
    }
}

/// One checkpoint marker on a sprint progress track, resolved for rendering.
///
/// Positions are fractions of the planned duration rather than raw seconds, so the widget extension
/// can lay them out against any track width without re-deriving the maths — and the resolution
/// lives on the shared payload precisely so the app-side test target can assert it (the extension
/// has no test bundle of its own).
nonisolated struct FocusActivityCheckpointMark: Equatable, Sendable, Identifiable {
    nonisolated enum State: Equatable, Sendable {
        case reached
        case next
        case pending
    }

    let index: Int
    /// 0–1 along the track.
    let fraction: Double
    let state: State

    var id: Int { index }
}

/// The content state's wire keys. Declared at file scope rather than nested inside `ContentState`
/// (which is itself nested in `FocusActivityAttributes`, so a third level trips SwiftLint's nesting
/// rule) and named to say which type it belongs to.
private enum FocusActivityContentStateKey: String, CodingKey {
    case taskTitle, lifeAreaEmoji, durationSeconds, deadline, pausedAt
    case checkpointCount, checkpointsReached, checkpointSeconds, isCompleted
}

/// `nonisolated` for the same reason the type itself is: the app module compiles with default
/// MainActor isolation, so a plain extension would make these two methods main-actor-bound — and
/// the OS encodes and decodes this state off the main actor.
@available(iOS 16.1, *)
nonisolated extension FocusActivityAttributes.ContentState {
    /// Codable is hand-written purely to tolerate a payload from a build that predates
    /// `checkpointSeconds`.
    ///
    /// An Activity started before an app update is decoded by the NEW extension from the OLD
    /// archived state; a synthesized decoder would throw on the missing key and a live sprint's card
    /// would go blank mid-sprint. It degrades to "no markers" instead — the counts still render.
    /// Everything else matches the synthesis exactly, and `encode` is written alongside so both
    /// directions demonstrably agree on the key names. Declared in an extension so the memberwise
    /// initialiser survives.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FocusActivityContentStateKey.self)
        self.init(
            taskTitle: try container.decode(String.self, forKey: .taskTitle),
            lifeAreaEmoji: try container.decode(String.self, forKey: .lifeAreaEmoji),
            durationSeconds: try container.decode(Int.self, forKey: .durationSeconds),
            deadline: try container.decode(Date.self, forKey: .deadline),
            pausedAt: try container.decodeIfPresent(Date.self, forKey: .pausedAt),
            checkpointCount: try container.decode(Int.self, forKey: .checkpointCount),
            checkpointsReached: try container.decode(Int.self, forKey: .checkpointsReached),
            checkpointSeconds: try container.decodeIfPresent([Int].self, forKey: .checkpointSeconds) ?? [],
            isCompleted: try container.decode(Bool.self, forKey: .isCompleted)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FocusActivityContentStateKey.self)
        try container.encode(taskTitle, forKey: .taskTitle)
        try container.encode(lifeAreaEmoji, forKey: .lifeAreaEmoji)
        try container.encode(durationSeconds, forKey: .durationSeconds)
        try container.encode(deadline, forKey: .deadline)
        try container.encodeIfPresent(pausedAt, forKey: .pausedAt)
        try container.encode(checkpointCount, forKey: .checkpointCount)
        try container.encode(checkpointsReached, forKey: .checkpointsReached)
        try container.encode(checkpointSeconds, forKey: .checkpointSeconds)
        try container.encode(isCompleted, forKey: .isCompleted)
    }
}
