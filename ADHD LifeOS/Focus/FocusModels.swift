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
    /// Elapsed-second offsets at which a checkpoint nudge fires. Mutable only through
    /// `replanCheckpoints(to:)`, which is the one operation allowed to reshape the plan — and
    /// which never disturbs a mark the sprint already crossed.
    private(set) var nudgeCheckpoints: [Int]
    private(set) var triggeredCheckpointIndices: Set<Int>

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

    /// Re-plans the sprint's remaining checkpoints under a new cadence, mid-flight.
    ///
    /// The rule, and the reason this can't just recompute `nudgeCheckpoints`: **the past is
    /// immutable.** Every mark the sprint already crossed keeps its position and stays counted (so
    /// the "N of M passed" readout and the history record never rewrite themselves), while every
    /// un-fired mark is discarded and replaced by the new cadence's marks that are still ahead of
    /// the playhead. A new mark that lands behind the playhead is dropped rather than fired — it
    /// is a moment that has already gone by.
    mutating func replanCheckpoints(to cadence: FocusNudgeCadence) {
        let replanned = FocusCheckpoints.replanned(
            existing: nudgeCheckpoints,
            triggeredIndices: triggeredCheckpointIndices,
            proposed: cadence.checkpoints(forDurationSeconds: durationSeconds),
            elapsedSeconds: elapsedSeconds
        )
        nudgeCheckpoints = replanned.checkpoints
        triggeredCheckpointIndices = replanned.triggeredIndices
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
    /// WHERE the sprint ran (F-Location-Tagging, block 3 remainder). Stamped only when the sprint
    /// ends in a LIVE app — `stop`, and the replacement path in `start` — never when a sprint
    /// that expired while the app was dead is settled at the next launch: the device's location
    /// at `endedAt` is unknown by then, and a wrong place is worse than none. `var` because the
    /// stamp is applied to the record `finishCurrentSprint` returns — that teardown is
    /// synchronous and cannot await a fix.
    var placeId: UUID?
    var latitude: Double?
    var longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id, taskId = "task_id", taskTitle = "task_title", latitude, longitude
        case lifeAreaEmoji = "life_area_emoji"
        case plannedSeconds = "planned_seconds", focusedSeconds = "focused_seconds"
        case checkpointsReached = "checkpoints_reached"
        case completedNaturally = "completed_naturally"
        case startedAt = "started_at", endedAt = "ended_at"
        case placeId = "place_id"
    }

    /// A copy carrying `stamp`, or `self` untouched when there is none — additive only, the same
    /// no-failure-path rule every other stamped record follows.
    func stamped(with stamp: LocationStamp?) -> CompletedFocusSession {
        guard let stamp else { return self }
        var stamped = self
        stamped.placeId = stamp.placeId
        stamped.latitude = stamp.coordinate.latitude
        stamped.longitude = stamp.coordinate.longitude
        return stamped
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

    /// Merges a freshly-computed plan into a sprint already in flight — the maths behind
    /// `FocusSession.replanCheckpoints(to:)`, split out so the rule is testable without a session.
    ///
    /// Fired marks (`triggeredIndices` into `existing`) are preserved verbatim; un-fired ones are
    /// dropped; `proposed` contributes only its marks strictly ahead of the playhead. Because every
    /// kept mark is behind the playhead and every contributed one ahead of it, the two sets never
    /// overlap and the fired indices always come out as the leading prefix of the merged plan.
    static func replanned(
        existing: [Int],
        triggeredIndices: Set<Int>,
        proposed: [Int],
        elapsedSeconds: Int
    ) -> (checkpoints: [Int], triggeredIndices: Set<Int>) {
        let kept = existing.enumerated()
            .filter { triggeredIndices.contains($0.offset) }
            .map(\.element)
            .sorted()
        let upcoming = proposed.filter { $0 > elapsedSeconds }.sorted()
        return (kept + upcoming, Set(kept.indices))
    }
}

/// `MM:SS`, the web's `formatDigitalTime`. Hours roll into the minutes field exactly as the web
/// version does (a 90-minute sprint reads `90:00`), so long sessions stay unambiguous.
enum FocusTimeFormatting {
    static func digital(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }

    /// The web's `formatFocusDuration` verbatim: sub-minute sprints keep their seconds (`30s`),
    /// whole minutes drop them (`15m`), and mixed values show both (`7m 30s`). Used wherever a
    /// per-task sprint length is displayed (card chip, detail screen, launch button).
    static func human(seconds: Int) -> String {
        let clamped = max(0, seconds)
        guard clamped >= 60 else { return "\(clamped)s" }
        let minutes = clamped / 60
        let remainder = clamped % 60
        return remainder == 0 ? "\(minutes)m" : "\(minutes)m \(remainder)s"
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
