//
//  FocusModels.swift
//  ADHD LifeOS
//

import Foundation

/// A running focus sprint. Mirrors the web prototype's `FocusSessionState` (`src/types.ts`),
/// minus the fields that only existed for its localStorage rehydration.
struct FocusSession: Equatable, Sendable {
    let taskId: UUID?
    let taskTitle: String
    /// The life area's emoji (stored in `LifeArea.colour`), or a target glyph when unassigned.
    let lifeAreaEmoji: String
    /// `var` because the bar's +30s / +5m controls extend a running sprint. Checkpoints are
    /// computed once at start and deliberately NOT recomputed on extension — the web behaves the
    /// same way, and re-spacing mid-sprint would move a checkpoint the user already passed.
    var durationSeconds: Int
    var remainingSeconds: Int
    var isPaused: Bool
    /// Elapsed-second offsets at which a checkpoint nudge fires.
    let nudgeCheckpoints: [Int]
    var triggeredCheckpointIndices: Set<Int>

    init(
        taskId: UUID?,
        taskTitle: String,
        lifeAreaEmoji: String,
        durationSeconds: Int,
        remainingSeconds: Int? = nil,
        isPaused: Bool = false,
        nudgeCheckpoints: [Int] = [],
        triggeredCheckpointIndices: Set<Int> = []
    ) {
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.lifeAreaEmoji = lifeAreaEmoji
        self.durationSeconds = durationSeconds
        self.remainingSeconds = remainingSeconds ?? durationSeconds
        self.isPaused = isPaused
        self.nudgeCheckpoints = nudgeCheckpoints
        self.triggeredCheckpointIndices = triggeredCheckpointIndices
    }

    var elapsedSeconds: Int { max(0, durationSeconds - remainingSeconds) }

    /// 0...1, clamped — drives the bar's progress fill.
    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(1, max(0, Double(elapsedSeconds) / Double(durationSeconds)))
    }

    var isComplete: Bool { remainingSeconds <= 0 }

    /// The soonest checkpoint still ahead of the playhead, with its index — the web's
    /// `upcomingCheckpoints[0]`.
    var nextCheckpoint: (index: Int, atSeconds: Int)? {
        nudgeCheckpoints.enumerated()
            .filter { !triggeredCheckpointIndices.contains($0.offset) && $0.element > elapsedSeconds }
            .min { $0.element < $1.element }
            .map { (index: $0.offset, atSeconds: $0.element) }
    }

    var secondsUntilNextCheckpoint: Int? {
        nextCheckpoint.map { max(0, $0.atSeconds - elapsedSeconds) }
    }

    /// Advances the playhead and reports which checkpoints the move crossed, so the caller can
    /// fire exactly one nudge per checkpoint. Pure — no timers, no side effects.
    mutating func advance(toRemaining newRemaining: Int) -> [Int] {
        remainingSeconds = max(0, min(durationSeconds, newRemaining))
        let crossed = nudgeCheckpoints.enumerated()
            .filter { !triggeredCheckpointIndices.contains($0.offset) && $0.element <= elapsedSeconds }
            .map(\.offset)
        triggeredCheckpointIndices.formUnion(crossed)
        return crossed.sorted()
    }

    /// ADHD coaching copy for a checkpoint, ported verbatim in spirit from the web's
    /// `getNudgePromptForIndex`.
    static func checkpointPrompt(index: Int, total: Int) -> String {
        if total == 1 {
            return "Midpoint check-in: take one grounding breath. Still on your single micro-step?"
        }
        if index == 0 {
            return "Flow calibration: check your posture, relax your shoulders, re-affirm the task."
        }
        if index == total - 1 {
            return "Final cadence: you're near the finish line — bring this to a clean close."
        }
        return "Checkpoint \(index + 1): gentle reset. Keep momentum without context switching."
    }
}

/// A finished sprint, persisted to Firestore so the weekly/trend analytics have real history.
struct CompletedFocusSession: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let taskId: UUID?
    let taskTitle: String
    let lifeAreaEmoji: String
    /// What the sprint was set to run for.
    let plannedSeconds: Int
    /// What actually elapsed — less than `plannedSeconds` when stopped early.
    let focusedSeconds: Int
    let checkpointsReached: Int
    let completedNaturally: Bool
    let startedAt: Date
    let endedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, taskId = "task_id", taskTitle = "task_title"
        case lifeAreaEmoji = "life_area_emoji"
        case plannedSeconds = "planned_seconds", focusedSeconds = "focused_seconds"
        case checkpointsReached = "checkpoints_reached"
        case completedNaturally = "completed_naturally"
        case startedAt = "started_at", endedAt = "ended_at"
    }
}

/// Checkpoint cadence math, ported from the web's `calculateNudgeCheckpoints` /
/// `calculateIntervalNudgeCheckpoints` (`src/hooks/useLifeOSState.ts`). Pure and total, so the
/// cadence rules are unit-testable without a running timer.
enum FocusCheckpoints {
    /// The web enforces a 30-second floor on interval cadence; the same floor applies to a
    /// session's total duration, since a sprint shorter than one interval has no checkpoints.
    static let minimumIntervalSeconds = 30
    /// Below this the web returns no checkpoints at all (`durationSeconds < 10`).
    static let minimumDurationForCheckpoints = 10

    /// `count` evenly-spaced checkpoints, excluding the start and finish boundaries.
    static func evenlySpaced(durationSeconds: Int, count: Int) -> [Int] {
        guard count > 0, durationSeconds >= minimumDurationForCheckpoints else { return [] }
        let segment = Double(durationSeconds) / Double(count + 1)
        var checkpoints: [Int] = []
        for step in 1...count {
            let elapsed = Int((segment * Double(step)).rounded())
            if elapsed > 0, elapsed < durationSeconds, !checkpoints.contains(elapsed) {
                checkpoints.append(elapsed)
            }
        }
        return checkpoints.sorted()
    }

    /// A checkpoint every `intervalSeconds`, floored at 30s, up to (not including) the finish.
    static func interval(durationSeconds: Int, intervalSeconds: Int) -> [Int] {
        let safeInterval = max(minimumIntervalSeconds, intervalSeconds)
        guard durationSeconds > 0 else { return [] }
        return Array(stride(from: safeInterval, to: durationSeconds, by: safeInterval))
    }
}

/// `MM:SS`, the web's `formatDigitalTime`. Hours roll into the minutes field exactly as the web
/// version does (a 90-minute sprint reads `90:00`), so long sessions stay unambiguous.
enum FocusTimeFormatting {
    static func digital(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }

    /// Human duration for the analytics cards — the web's `formatFocusDuration`. Whole minutes
    /// below an hour (`45m`), hours-and-minutes above (`1h 25m`, `2h`), and `0m` for nothing.
    static func duration(seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        guard minutes >= 60 else { return "\(minutes)m" }
        let hours = minutes / 60
        let remainder = minutes % 60
        return remainder == 0 ? "\(hours)h" : "\(hours)h \(remainder)m"
    }
}
