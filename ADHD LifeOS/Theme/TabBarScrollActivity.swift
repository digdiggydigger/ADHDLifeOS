//
//  TabBarScrollActivity.swift
//  ADHD LifeOS
//

import Combine
import Foundation

/// F-Tools-2-Morph's state: is the page actually moving right now?
///
/// E's chosen tab bar is a **two-state morph** — Design F at rest, Design B while scrolling — and
/// the trigger is **momentary**: B holds only while the page is in motion. That is a different
/// question from the one `CaptureDiscScrollActivity` answers, which is why this is a second model
/// rather than a flag on that one.
///
/// **`CaptureDiscScrollActivity` could not be reused, and must not be edited.** It is directional
/// and STICKY by construction — E's 2026-08-31 verdict was *"stay in pill form until the page is
/// scrolled upwards again"*, and its own comment says nothing in it runs on a timer. Sticky is
/// exactly what momentary is not. The two are deliberately no longer in lockstep; that is the
/// trade E accepted in choosing momentary for the bar.
///
/// **The problem this type exists to solve is momentum.** `CaptureDiscPanObserver` is a pan
/// recogniser, so it tracks the FINGER, not the page — and it deliberately does not forward
/// `.ended`/`.cancelled`, because the disc's stickiness depends on not hearing them. After the
/// lift, the scroll view keeps gliding while **nothing reports movement at all**. A signal that
/// simply followed the drag would therefore snap the bar back to its resting shape *while the
/// page is still visibly scrolling* — the one moment it must not.
///
/// The fix is a **settle timer restarted on every movement**: the bar stays in B through the lift
/// and most of the deceleration, and returns to F once the finger has genuinely stopped feeding
/// it. Cheaper than the alternatives, and it touches no shared component — forwarding terminal
/// states would edit the observer the disc depends on, and reading real scroll offsets per screen
/// is the per-screen drift the clearance work spent a block stamping out.
@MainActor
final class TabBarScrollActivity: ObservableObject {
    @Published private(set) var isMoving = false

    /// **Tunable, and expected to be tuned.** E has not seen this on device, so the number is a
    /// judgement rather than a verdict: long enough to carry the bar through a flick's
    /// deceleration, short enough that the bar does not hang in its scrolled shape after the page
    /// has stopped. `TabBarScrollActivityTests` pins the band the design allows (0.25–0.35).
    nonisolated static let settleInterval: TimeInterval = 0.3

    /// Injected so the tests can run the settle without waiting for it. Defaults to the main
    /// queue, which is where every caller already is.
    private let scheduleSettle: (TimeInterval, @escaping () -> Void) -> Void

    /// Which settle is the live one. Restarting is expressed by bumping this rather than by
    /// cancelling: a stale block still fires, looks at the counter, and does nothing. No
    /// cancellation token to leak, and "did a later movement restart it?" becomes a plain
    /// integer comparison the tests can drive.
    private var generation = 0

    init(
        scheduleSettle: @escaping (TimeInterval, @escaping () -> Void) -> Void = { delay, work in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }
    ) {
        self.scheduleSettle = scheduleSettle
    }

    /// A scroll moved. Called from `RootView`'s single `CaptureDiscPanObserver` install, which
    /// feeds this model and the disc's alongside each other — the observer is idempotent
    /// (`guard shared == nil`), so a second install would silently no-op and this would never
    /// hear anything.
    func dragMoved() {
        if !isMoving { isMoving = true }
        restartSettle()
    }

    /// The one stop that isn't a settle: a tab change. Same reasoning as the disc's `reset()` —
    /// a bar left mid-morph on a screen the user never scrolled reads as a bug.
    func reset() {
        generation &+= 1
        if isMoving { isMoving = false }
    }

    private func restartSettle() {
        generation &+= 1
        let scheduled = generation
        scheduleSettle(Self.settleInterval) { [weak self] in
            guard let self, self.generation == scheduled else { return }
            self.isMoving = false
        }
    }
}
