//
//  RoutineActivityState.swift
//  ADHD LifeOS
//
//  The app half of the routine Live Activity (F-Routines-5): projects a `RoutineRun` into the
//  shared `RoutineActivityAttributes.ContentState`. The projection lives app-side because the
//  widget extension cannot see `RoutineRun`; the RESOLUTION it produces lives on the shared
//  payload so this target's tests can assert it (the `FocusActivityAttributes` precedent).
//

import Foundation

@available(iOS 16.1, *)
extension RoutineActivityAttributes.ContentState {
    init(run: RoutineRun) {
        self.init(
            placeName: run.displayName,
            doneCount: PlaceRoutineProgress.doneCount(run),
            totalCount: run.steps.count,
            nextStepLabel: PlaceRoutineProgress.nextPendingIndex(run)
                .map { PlaceActionRowLabel.title(for: run.steps[$0].action) },
            progress: PlaceRoutineProgress.resolvedFraction(run)
        )
    }
}
