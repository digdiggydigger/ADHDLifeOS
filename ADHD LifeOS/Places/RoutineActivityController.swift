//
//  RoutineActivityController.swift
//  ADHD LifeOS
//
//  Drives the routine's Live Activity (F-Routines-5).
//
//  **ActivityKit cannot START an Activity from the background**, and a crossing arrives with
//  the app backgrounded — so the Activity begins when the routine SCREEN opens, in the
//  foreground, and not at the crossing. That is a platform floor, not a gap to fix later.
//  Updates and ends from the running process are fine.
//
//  §7 availability: nothing here is gated — ActivityKit sits below the 18 floor (`F-Floor18`).
//

import Foundation

/// The seam, so the screen can be built and tested without ActivityKit.
@MainActor
protocol RoutineActivityPresenting {
    func started(_ run: RoutineRun)
    func updated(_ run: RoutineRun)
    func ended()
}

/// A no-op for previews, so the routine screen renders in the canvas without a real Activity.
@MainActor
struct InertRoutineActivityPresenter: RoutineActivityPresenting {
    func started(_ run: RoutineRun) {}
    func updated(_ run: RoutineRun) {}
    func ended() {}
}
