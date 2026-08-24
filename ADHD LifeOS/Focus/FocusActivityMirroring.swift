//
//  FocusActivityMirroring.swift
//  ADHD LifeOS
//

import Foundation

/// A value snapshot of the running sprint, handed to the Live Activity mirror on every lifecycle
/// event. Pure data with no ActivityKit dependency, so `FocusSessionService`'s mirroring stays
/// unit-testable on the iOS 16.0 floor with a fake — the same seam convention as
/// `FocusSessionLogging` and the rest of the `*Adapting` family.
struct FocusActivitySnapshot: Equatable, Sendable {
    let taskTitle: String
    let lifeAreaEmoji: String
    /// Total planned length including +30s/+5m extensions, so the Activity's progress fill stays
    /// truthful — mirrors how `addSeconds` grows `durationSeconds` in the engine.
    let durationSeconds: Int
    /// The wall-clock instant the countdown hits zero. `nil` while paused; re-anchored on resume,
    /// exactly like the engine's own deadline bookkeeping.
    let deadline: Date?
    /// The frozen remaining time while paused; `nil` while running.
    let pausedRemainingSeconds: Int?
    let checkpointCount: Int
    let checkpointsReached: Int
    /// Elapsed-second offsets of every checkpoint in the plan, so the Activity can draw real
    /// markers on its track. Carried alongside the count rather than derived from it: a mid-sprint
    /// cadence re-plan keeps fired marks exactly where they were, so an evenly-spaced guess in the
    /// extension would move marks the sprint has already passed.
    let checkpointSeconds: [Int]
}

/// Seam over ActivityKit: the service reports sprint lifecycle events, the live implementation
/// (`FocusActivityKitMirror`) projects them onto the Lock Screen / Dynamic Island Activity, and
/// tests assert the call sequences with a fake. The OS renders the countdown itself from the
/// snapshot's deadline, so these events are the ONLY updates an Activity ever receives — never
/// per-second ticks.
@MainActor
protocol FocusActivityMirroring: AnyObject {
    func sprintStarted(_ snapshot: FocusActivitySnapshot)
    /// A sprint reinstated from persistence after the process died mid-flight
    /// (F-SprintPersistence). Distinct from `sprintStarted` because the live implementation must
    /// sequence AFTER its orphan sweep — the Activity surviving on the Lock Screen belongs to
    /// this very sprint.
    func sprintRestored(_ snapshot: FocusActivitySnapshot)
    /// Pause, resume, extend, and checkpoint crossings.
    func sprintUpdated(_ snapshot: FocusActivitySnapshot)
    /// Manual stop, natural completion, and the retirement of a sprint a replacement displaces.
    func sprintEnded(completedNaturally: Bool)
}
