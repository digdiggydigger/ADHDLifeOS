//
//  RoutineActivityKitPresenter.swift
//  ADHD LifeOS
//
//  The live `RoutineActivityPresenting` — the `FocusActivityKitMirror` shape, minus everything
//  a countdown needs. A routine has no clock: the Activity changes only when a step does, so
//  there is nothing to schedule and no staleness to declare.
//

import ActivityKit
import Foundation

@available(iOS 16.1, *)
@MainActor
final class RoutineActivityKitPresenter: RoutineActivityPresenting {
    /// ONE instance, app-wide — the `PlaceActionNotificationRouter.shared` shape.
    ///
    /// It has to outlive SwiftUI body re-evaluation: the presenter is handed to the routine
    /// screen from a `@ViewBuilder`, so a fresh instance would be constructed on every
    /// re-render, and the handle to the running Activity (`activity` below) would be dropped
    /// with the instance that owned it. Updates and the end would then quietly no-op, leaving
    /// a card on the Lock Screen that nothing could move or dismiss.
    static let shared = RoutineActivityKitPresenter()

    private var activity: Activity<RoutineActivityAttributes>?

    private init() {}

    func started(_ run: RoutineRun) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, activity == nil else { return }
        let state = RoutineActivityAttributes.ContentState(run: run)
        do {
            if #available(iOS 16.2, *) {
                activity = try Activity.request(
                    attributes: RoutineActivityAttributes(),
                    content: ActivityContent(state: state, staleDate: nil)
                )
            } else {
                activity = try Activity.request(
                    attributes: RoutineActivityAttributes(), contentState: state
                )
            }
        } catch {
            // The request can fail (Live Activities disabled, per-app budget exhausted). The
            // routine itself is unaffected — the screen and Today's card remain the truth.
            activity = nil
        }
    }

    func updated(_ run: RoutineRun) {
        guard let activity else { return }
        let state = RoutineActivityAttributes.ContentState(run: run)
        Task {
            if #available(iOS 16.2, *) {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            } else {
                await activity.update(using: state)
            }
        }
    }

    /// Immediate, like the sprint's: a routine that is over must not leave a card implying it
    /// is still running. Ends the one we started AND sweeps any orphan from a killed process.
    func ended() {
        activity = nil
        Task {
            for live in Activity<RoutineActivityAttributes>.activities {
                if #available(iOS 16.2, *) {
                    await live.end(nil, dismissalPolicy: .immediate)
                } else {
                    await live.end(using: nil, dismissalPolicy: .immediate)
                }
            }
        }
    }
}
