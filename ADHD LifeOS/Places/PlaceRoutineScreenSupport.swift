//
//  PlaceRoutineScreenSupport.swift
//  ADHD LifeOS
//
//  The routine screen's pure layer (F-Routines-3-Screen): progress semantics and every word,
//  pinned by tests the SwiftUI body cannot carry. The semantics are the plan's, settled so
//  blocks cannot pin contradictory tests:
//  - "N of M done" counts auto-done + tapped-done; a SKIPPED step counts toward the bar's
//    RESOLVED fraction but never toward the "done" wording;
//  - completion = no pending steps;
//  - Undo returns a done or skipped step to pending; auto-done steps have no Undo — they ran,
//    and the record tells the truth.
//

import Foundation

enum PlaceRoutineProgress {
    static func doneCount(_ run: RoutineRun) -> Int {
        run.steps.filter { $0.state == .autoDone || $0.state == .done }.count
    }

    static func resolvedFraction(_ run: RoutineRun) -> Double {
        guard !run.steps.isEmpty else { return 0 }
        let resolved = run.steps.filter { $0.state != .pending }.count
        return Double(resolved) / Double(run.steps.count)
    }

    static func isFullyResolved(_ run: RoutineRun) -> Bool {
        !run.steps.contains { $0.state == .pending }
    }

    /// The dominant next-step card's index — the FIRST pending step in saved order.
    static func nextPendingIndex(_ run: RoutineRun) -> Int? {
        run.steps.firstIndex { $0.state == .pending }
    }

    static func progressLabel(_ run: RoutineRun) -> String {
        "\(doneCount(run)) of \(run.steps.count) done"
    }

    /// The one state machine: pending → done/skipped (the tap and the quiet Skip);
    /// done/skipped → pending (Undo). Everything else — auto-done above all — is immutable,
    /// and an invalid ask returns the run unchanged rather than trapping.
    static func marking(
        _ run: RoutineRun, stepAt index: Int, as newState: RoutineStepState
    ) -> RoutineRun {
        guard run.steps.indices.contains(index) else { return run }
        let allowed: Bool
        switch (run.steps[index].state, newState) {
        case (.pending, .done), (.pending, .skipped),
             (.done, .pending), (.skipped, .pending):
            allowed = true
        default:
            allowed = false
        }
        guard allowed else { return run }
        var updated = run
        updated.steps[index].state = newState
        return updated
    }
}

enum PlaceRoutineScreenCopy {
    static let eyebrow = "ROUTINE"
    static let skipLabel = "Skip this step"
    static let undoLabel = "Undo"
    static let doneSubtitle = "Done"
    static let skippedSubtitle = "Skipped"

    /// The screen's large title IS the notification's moment — one voice.
    static func momentTitle(for run: RoutineRun) -> String {
        run.direction == .arrival
            ? "You're at \(run.displayName)" : "Leaving \(run.displayName)"
    }

    /// "arrived" / "left" — the relative-time line's verb, switched by direction.
    static func momentPrefix(for direction: PlaceTriggerEvent.Kind) -> String {
        direction == .arrival ? "arrived" : "left"
    }

    /// The pre-ticked auto rows' subtitle.
    ///
    /// It used to switch on direction — "when you arrived" / "when you left" — because the
    /// crossing is when the step ran. Under deferred logging (Block A) nothing runs at the
    /// crossing: the step runs when the routine STARTS, which is the tap that opened this
    /// screen. That is the same moment in both directions, so the direction goes with it.
    static let autoRanSubtitle = "Ran by itself when you started"

    static func nextEyebrow(stepNumber: Int, of total: Int) -> String {
        "NEXT — STEP \(stepNumber) OF \(total)"
    }

    static func upcomingSubtitle(stepNumber: Int, of total: Int) -> String {
        "Step \(stepNumber) of \(total)"
    }
}
