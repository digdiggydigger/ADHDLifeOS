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
//  §7 availability: ActivityKit is 16.1+ against the app's 16.0 floor, so the whole type is
//  gated. The routine SCREEN is 17-gated anyway, so in practice this only ever runs on 17+.
//

import Foundation

/// The seam, so the screen can be built and tested without ActivityKit.
@MainActor
protocol RoutineActivityPresenting {
    func started(_ run: RoutineRun)
    func updated(_ run: RoutineRun)
    func ended()
}

/// A no-op for previews and for the 16.0–16.1 window where ActivityKit is unavailable.
@MainActor
struct InertRoutineActivityPresenter: RoutineActivityPresenting {
    func started(_ run: RoutineRun) {}
    func updated(_ run: RoutineRun) {}
    func ended() {}
}
