//
//  RoutineActivityAttributes.swift
//  FocusTimerWidget
//
//  Compiled into BOTH the app and the widget extension (ActivityKit matches the Activity across
//  the two processes by this type), so it must stay free of app-module dependencies — which is
//  why the run is projected into plain scalars at the boundary rather than crossing it whole.
//  `nonisolated` because the app module compiles with default-MainActor isolation and the OS
//  encodes/decodes this state off the main actor.
//
//  A DISPLAY Activity (F-Routines-5): progress, the next step, and a tap that returns to the
//  screen. Deliberately NO buttons — interactive App Intents are the settled fast-follow, and
//  they are a different capability (iOS 17+) against this target's 16.1 floor.
//

import ActivityKit
import Foundation

@available(iOS 16.1, *)
nonisolated struct RoutineActivityAttributes: ActivityAttributes {
    /// Everything routine-specific lives in the content state — a replacement routine is just a
    /// fresh Activity with fresh state — so the fixed attributes carry nothing.
    nonisolated struct ContentState: Codable, Hashable {
        /// The place moment as the screen and the notification say it, emoji included.
        var placeName: String
        /// Auto-done plus tapped-done. A SKIPPED step is resolved but never "done" — the same
        /// split the screen's own label makes, so the two can never disagree in front of E.
        var doneCount: Int
        var totalCount: Int
        /// `nil` once nothing is pending.
        var nextStepLabel: String?
        /// 0–1 RESOLVED fraction — skipped counts here, matching the screen's bar exactly.
        var progress: Double

        /// The Lock Screen banner's form — it has a full row to itself.
        var statusLine: String {
            "\(doneCount) of \(totalCount) done"
        }

        /// The Dynamic Island's form. The expanded trailing region is narrow and truncated
        /// "1 of 2 done" to "1 of 2…" on device (E's field walk, 2026-09-03) — the same slot
        /// that once ate a leading digit off the sprint's countdown. Glanceable, not chatty.
        var shortStatusLine: String {
            "\(doneCount)/\(totalCount)"
        }

        var nextLine: String {
            guard let nextStepLabel else { return "All steps done" }
            return "Next: \(nextStepLabel)"
        }
    }

    /// Tapping the Activity returns to the routine, riding the widget-link door every other
    /// widget already uses (`AppDeepLink.route`).
    static let deepLink = "adhdlifeos://widget/routine"
}
