//
//  CelebrationCenter.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-3`: the app's one celebration owner. Every site asks it; it applies
//  `CelebrationPolicy`, tags the burst with whichever surface is in front, and publishes the live
//  list the layers draw.
//
//  **Owned by the App, not by `RootView`** (design §1, the `authService` arrangement). Owned in
//  `RootView` it would be rebuilt on every auth-state swap, dropping whatever was in the air — and
//  a `@StateObject` cannot live in an extension file, which `RootView` needs for its 400-line bar.
//
//  **Everything is on an injected clock.** The cooldown, the held bursts' 60 s and the expiry sweep
//  all read `now()`, so the rules are testable without waiting for real seconds.
//

import Combine
import CoreGraphics
import Foundation

final class CelebrationCenter: ObservableObject, CelebrationRequesting {
    /// R-g: a search surface left open for minutes must not release a stale daily-goal burst when
    /// it finally closes.
    static let heldLifetime: TimeInterval = 60

    /// What is on screen, across every surface. Each layer draws only its own.
    @Published private(set) var bursts: [CelebrationBurst] = []
    /// When the last FULL-SCREEN celebration started — the cooldown's input. R-c: a Confirm stamps
    /// this even though a Confirm is never cooled down itself.
    private(set) var lastFullScreenAt: Date?
    /// Full-screens requested while a self-dismissing surface was frontmost, waiting for it to go.
    private(set) var held: [CelebrationBurst] = []

    /// Presented surfaces, innermost last. The root is the base and is never on it.
    private var presented: [CelebrationSurface] = []
    /// One counter for every burst, whatever kind: SwiftUI ids and confetti seeds can then never
    /// collide between a pop and a Confirm.
    private var ordinal = 0
    private let now: () -> Date
    /// E's Settings switch (#3), read at FIRE time — `Haptics.play(gate:)`'s arrangement — so
    /// flipping it takes effect on the very next celebration with no relaunch.
    private let celebrationsGate: () -> Bool
    /// F5's seam. `F-CTACelebrations-7` supplies the player; until then the hook is a no-op, and
    /// the Celebration sounds switch it will read is already live in Settings.
    private let chime: (CelebrationKind) -> Void

    init(
        now: @escaping () -> Date = Date.init,
        celebrationsGate: @escaping () -> Bool = { AppFeedback.celebrationsEnabled() },
        chime: @escaping (CelebrationKind) -> Void = { _ in }
    ) {
        self.now = now
        self.celebrationsGate = celebrationsGate
        self.chime = chime
    }

    /// Whichever surface is in front of the user right now.
    var frontmost: CelebrationSurface { presented.last ?? .root }

    /// What the cooldown is measured from: the last full-screen celebration to have STARTED, or
    /// one that is still waiting to.
    ///
    /// **The held half is not bookkeeping — it is the rule.** A waiting burst has stamped nothing,
    /// because it has not played; but if a second milestone arriving while it waits were promised a
    /// full screen too, the sheet's dismissal would release both at one instant and stack two 5.4 s
    /// washes, which is the exact thing E's #6 cooldown exists to prevent. So a pending burst
    /// counts against the cooldown without having started it, and the second moment gets the pop.
    private var cooldownAnchor: Date? {
        [lastFullScreenAt, held.map(\.start).max()].compactMap { $0 }.max()
    }

    /// The bursts one layer should draw.
    func bursts(on surface: CelebrationSurface) -> [CelebrationBurst] {
        bursts.filter { $0.surface == surface }
    }

    // MARK: - Asking

    @discardableResult
    func request(_ kind: CelebrationKind, at origin: CGPoint?) -> CelebrationOutcome {
        let moment = now()
        // The gate is read BEFORE anything is enqueued, never after: on the list the celebration
        // is already drawing and the frame clock is already running.
        let outcome = CelebrationPolicy.outcome(
            for: kind,
            lastFullScreenAt: cooldownAnchor,
            now: moment,
            celebrationsEnabled: celebrationsGate()
        )
        guard outcome != .nothing else { return .nothing }

        ordinal += 1
        let burst = CelebrationBurst(
            ordinal: ordinal,
            // A downgraded milestone plays as a pop, which is what E's #6 means by "it gets the
            // in-place celebration" — the same paper every other in-place moment gets.
            kind: outcome == .fullScreen ? kind : .pop,
            surface: frontmost,
            start: moment,
            origin: origin
        )

        if outcome == .fullScreen, frontmost.dismissesItself {
            // Drawn on a sheet that is about to close itself, it would be cut off after a
            // fraction of a second. Held, and released over whatever is behind it — and it
            // stamps NOTHING until then, because it has not played.
            held.append(burst)
            return outcome
        }
        start(burst, at: moment)
        return outcome
    }

    /// **The one place a burst begins**, so a held release and a direct enqueue cannot disagree
    /// about when the cooldown starts or when the chime sounds.
    ///
    /// Both used to disagree, and it was a LATENT defect until `F-CTACelebrations-5` (register
    /// §B.00b): `request` stamped `lastFullScreenAt` and chimed before the held branch, and
    /// `releaseHeld` did neither. So a burst waiting behind the Create Task sheet chimed with
    /// nothing on screen to explain it, cooled down the milestone that followed it before anyone
    /// had seen it, and — dropped at R-g's sixty seconds — left a cooldown behind for a
    /// celebration that never appeared. Unreachable while the only full-screen request was the
    /// Confirm bridge, which sits below every sheet; inbox zero through the promote sheet is
    /// exactly the held path.
    private func start(_ burst: CelebrationBurst, at moment: Date) {
        if burst.isFullScreen {
            // R-c: Confirm counts toward the cooldown. A pop never does.
            lastFullScreenAt = moment
            chime(burst.kind)
        }
        bursts = CelebrationQueue.adding(burst, to: bursts, now: moment)
    }

    // MARK: - Surfaces

    /// The root is the base of the stack rather than a presentation, so its layer can call this
    /// unconditionally on appear without seating it above a live cover.
    func surfacePresented(_ surface: CelebrationSurface) {
        guard surface != .root else { return }
        presented.removeAll { $0 == surface }
        presented.append(surface)
    }

    /// Called from each presenter's `onDismiss` — never from the layer's `onDisappear`, which
    /// `PlaceRoutineScreen` records as unreliable for that cover.
    func surfaceDismissed(_ surface: CelebrationSurface) {
        presented.removeAll { $0 == surface }
        releaseHeld()
    }

    /// Removes every burst that has finished. Driven by the root layer's expiry sweep, which is the
    /// one that is always mounted.
    func prune(now moment: Date) {
        let remaining = CelebrationQueue.pruned(bursts, now: moment)
        if remaining.count != bursts.count { bursts = remaining }
    }

    /// A held burst plays over whatever is in front NOW, starting NOW — not from the instant it was
    /// requested, which would have half of it elapsed before anything was drawn. R-g drops one that
    /// has waited more than a minute rather than releasing it stale.
    private func releaseHeld() {
        guard !held.isEmpty else { return }
        let moment = now()
        let fresh = held.filter { moment.timeIntervalSince($0.start) <= Self.heldLifetime }
        held = []
        for burst in fresh {
            start(
                CelebrationBurst(
                    ordinal: burst.ordinal,
                    kind: burst.kind,
                    surface: frontmost,
                    start: moment,
                    origin: burst.origin
                ),
                at: moment
            )
        }
    }
}
