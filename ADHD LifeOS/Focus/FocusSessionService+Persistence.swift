//
//  FocusSessionService+Persistence.swift
//  ADHD LifeOS
//
//  Sprint persistence (F-SprintPersistence), in its own file so `FocusSessionService` stays
//  inside its length budgets — the same arrangement as `CaptureInboxService+Create` and peers.
//  Everything it touches on the service is internal rather than private for exactly this reason.
//

import Foundation

extension FocusSessionService {
    /// Reinstates a sprint the process died holding: running sprints recompute from the saved
    /// deadline (checkpoints crossed while dead are marked fired WITHOUT nudging), paused ones
    /// come back frozen, an expired one settles: logged whole, Activity ended, store cleared.
    func restorePersistedSprint() async {
        guard let sprintStore else { return }
        if offlineCompletionSummary == nil {
            offlineCompletionSummary = sprintStore.readUnacknowledgedCompletion()
        }
        guard session == nil, let saved = sprintStore.read() else { return }
        cadence = saved.cadence
        startedAt = saved.startedAt
        var restored = FocusSession(
            taskId: saved.taskId,
            taskTitle: saved.taskTitle,
            lifeAreaEmoji: saved.lifeAreaEmoji,
            durationSeconds: saved.durationSeconds,
            remainingSeconds: saved.pausedRemainingSeconds ?? saved.durationSeconds,
            isPaused: saved.deadline == nil,
            nudgeCheckpoints: saved.nudgeCheckpoints,
            triggeredCheckpointIndices: Set(saved.triggeredCheckpointIndices)
        )
        if let savedDeadline = saved.deadline {
            let remaining = Int(savedDeadline.timeIntervalSince(now()).rounded(.up))
            _ = restored.advance(toRemaining: remaining)
            session = restored
            deadline = savedDeadline
            if restored.isComplete {
                // Finished while dead: settle it AND make the finish visible — the record feeds
                // the confirmation card and is held until the user acknowledges it.
                if let record = finishCurrentSprint(completedNaturally: true) {
                    offlineCompletionSummary = record
                    sprintStore.writeUnacknowledgedCompletion(record)
                    // Deliberately UNSTAMPED, unlike stop(): this sprint ended while the app was
                    // dead, and the device's location at that moment is unknown by now — a stamp
                    // taken here would record wherever the user is at THIS launch. No place beats
                    // a wrong one.
                    await log(record)
                }
                return
            }
            startTicking()
        } else {
            session = restored
        }
        activityMirror?.sprintRestored(FocusActivitySnapshot(session: restored, deadline: deadline))
        rescheduleNotifications()
        persistCurrentSprint()
    }

    /// The confirmation card's dismissal: clears the published summary and its persisted copy.
    func acknowledgeOfflineCompletion() {
        offlineCompletionSummary = nil
        sprintStore?.clearUnacknowledgedCompletion()
    }

    /// Snapshots the running sprint into the store — or clears it if none is running. Internal
    /// rather than private because its callers (start, pause, extend, re-plan, ticks) live in the
    /// main file.
    func persistCurrentSprint() {
        guard let sprintStore else { return }
        guard let session, let startedAt else {
            sprintStore.clear()
            return
        }
        sprintStore.write(
            PersistedFocusSprint(session: session, startedAt: startedAt, deadline: deadline, cadence: cadence)
        )
    }
}
