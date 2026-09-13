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

    /// How often the hold watch asks whether the way is clear. Fast enough that a celebration
    /// released by closing a sheet still feels like a consequence of closing it, and it runs ONLY
    /// while something is held — a few dozen property reads, rarely.
    static let holdPollInterval: TimeInterval = 0.25

    /// What is on screen, across every surface. Each layer draws only its own.
    @Published private(set) var bursts: [CelebrationBurst] = []
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
    /// **R-d's exception to the single-owner rule.** Injected rather than called directly so a test
    /// can watch it without a `UIFeedbackGenerator`; the default is the house helper, which reads
    /// E's Haptics switch at fire time.
    private let feel: (HapticFeel) -> Void
    /// `F-CTACelebrations-Surfaces`: how the centre learns that a sheet it was never told about is
    /// up. E chose asking UIKit over tagging all 26 presenters (`CelebrationPresentationProbe`).
    private let probe: PresentationProbing
    /// The hold watch's wait, injected so the loop itself is tested rather than only one tick of it.
    private let sleep: (TimeInterval) async -> Void

    /// The running hold watch, or `nil` with nothing held. Exposed for the same reason `held` is:
    /// a test awaits it rather than sleeping for real seconds.
    private(set) var holdWatch: Task<Void, Never>?

    init(
        now: @escaping () -> Date = Date.init,
        celebrationsGate: @escaping () -> Bool = { AppFeedback.celebrationsEnabled() },
        chime: @escaping (CelebrationKind) -> Void = { _ in },
        feel: @escaping (HapticFeel) -> Void = { Haptics.play($0) },
        probe: PresentationProbing = KeyWindowPresentationProbe(),
        sleep: @escaping (TimeInterval) async -> Void = { seconds in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
    ) {
        self.now = now
        self.celebrationsGate = celebrationsGate
        self.chime = chime
        self.feel = feel
        self.probe = probe
        self.sleep = sleep
    }

    /// Whichever surface is in front of the user right now.
    var frontmost: CelebrationSurface { presented.last ?? .root }

    /// **Whether a full-screen celebration asked for right now would be drawn where nobody can see
    /// it.** The one predicate behind both the hold and the release, so the two can never disagree
    /// about what "in the way" means.
    ///
    /// Two ways it happens, and the app is told about only one of them:
    ///
    /// - A tracked surface that closes ITSELF (the Create Task sheet). A 5.4 s celebration on its
    ///   layer is cut off a fraction of a second in.
    /// - Anything the centre was never told about at all. Four surfaces call `surfacePresented`;
    ///   the tree holds 26 `.sheet` / `.fullScreenCover` call sites, so `frontmost` reads `.root`
    ///   under Quick Capture, Settings, the Journal composer and twenty more — and iOS hands the
    ///   app no signal for any of them. `F-CTACelebrations-Surfaces` asks UIKit instead (E's call,
    ///   2026-09-13; `CelebrationPresentationProbe` carries the why).
    ///
    /// **The probe is read only from `.root`, which is the simple form E chose** over reconciling
    /// the probe's DEPTH against `presented.count`. Every other tracked surface IS a presented
    /// controller, so an unconditional read would hold exactly the celebrations those surfaces
    /// mount their own layers to draw. It is sound while none of them presents a sheet of its own,
    /// which `CelebrationProbeCallSiteTests` is what keeps true — and the depth form is the way
    /// out on the day one of them does.
    private var isBlocked: Bool {
        if frontmost.dismissesItself { return true }
        guard frontmost == .root else { return false }
        return probe.isAnythingPresented
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
        let outcome = CelebrationPolicy.outcome(for: kind, celebrationsEnabled: celebrationsGate())
        guard outcome != .nothing else { return .nothing }

        // **R-d, and it fires HERE rather than when the burst starts, unlike the chime.** The
        // chime accompanies the confetti (E's F5 is about sound over a celebration); this
        // accompanies the ACHIEVEMENT, which is the daily goal being reached — a moment with no
        // other feedback anywhere in the app, because it has no site. So a downgraded one keeps
        // it (R-h's argument exactly) and a held one buzzes at once rather than half a second
        // after the sheet closes. Every other milestone rides a site that already buzzed.
        if case .milestone(.dailyGoal) = kind { feel(.success) }

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

        if outcome == .fullScreen, isBlocked {
            // Drawn where it cannot be seen — cut off after a fraction of a second by a sheet
            // that closes itself, or simply underneath one. Held, and released over whatever is
            // in front once the way is clear — and it stamps NOTHING until then, because it has
            // not played.
            held.append(burst)
            beginHoldWatch()
            return outcome
        }
        start(burst, at: moment)
        return outcome
    }

    /// **The one place a burst begins**, so a held release and a direct enqueue cannot disagree
    /// about when the cooldown starts or when the chime sounds.
    ///
    /// Both used to disagree, and it was a LATENT defect until `F-CTACelebrations-5` (register
    /// §B.00b): `request` chimed before the held branch and `releaseHeld` did not chime at all, so
    /// a burst waiting behind the Create Task sheet sounded with nothing on screen to explain it,
    /// and one dropped at R-g's sixty seconds had already sounded for a celebration that never
    /// appeared. (It also stamped a cooldown, which mattered until E removed the cooldown
    /// entirely on 2026-09-12.) Unreachable while the only full-screen request was the Confirm
    /// bridge, which sits below every sheet; inbox zero through the promote sheet is the held
    /// path.
    private func start(_ burst: CelebrationBurst, at moment: Date) {
        if burst.isFullScreen {
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
        releaseHeldIfClear()
    }

    /// **One tick of the hold watch**, and the whole of the release rule: R-g first, then play if
    /// the way is clear. Exposed rather than private so the rule can be tested without the loop
    /// around it — the loop has a test of its own.
    func pollHeldBursts() {
        releaseHeldIfClear()
    }

    /// Removes every burst that has finished. Driven by the root layer's expiry sweep, which is the
    /// one that is always mounted.
    func prune(now moment: Date) {
        let remaining = CelebrationQueue.pruned(bursts, now: moment)
        if remaining.count != bursts.count { bursts = remaining }
    }

    /// A held burst plays over whatever is in front NOW, starting NOW — not from the instant it was
    /// requested, which would have half of it elapsed before anything was drawn.
    ///
    /// **Two things changed here in `F-CTACelebrations-Surfaces`, and both are consequences of the
    /// same fact: an untracked sheet says nothing when it closes.**
    ///
    /// - It no longer releases unconditionally. A tracked surface closing while an untracked one
    ///   is still up would otherwise put the burst under THAT — the same invisibility, one layer
    ///   along. When the way is not clear it leaves the burst held and the watch picks it up.
    /// - **R-g is enforced by TIME now rather than by the next dismissal.** It used to drop a
    ///   stale burst only when something called this; behind a sheet nobody tracks, nothing ever
    ///   would, and the burst waited indefinitely for a release that could not come.
    private func releaseHeldIfClear() {
        guard !held.isEmpty else { return }
        let moment = now()
        held = held.filter { moment.timeIntervalSince($0.start) <= Self.heldLifetime }
        guard !held.isEmpty else { return stopHoldWatch() }
        guard !isBlocked else { return }
        let releasing = held
        held = []
        stopHoldWatch()
        for burst in releasing {
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

    // MARK: - The hold watch

    /// **The release side of E's answer, and the price of it.** Tagging every presenter would have
    /// given an exact dismissal callback; asking UIKit gives none, so the centre has to look.
    ///
    /// It runs ONLY while something is held, ticks four times a second and cannot outlive R-g's
    /// sixty — a few dozen property reads, on the rare occasion a milestone lands behind a sheet.
    /// Pinned to the main actor because everything it touches is SwiftUI's.
    private func beginHoldWatch() {
        guard holdWatch == nil else { return }
        holdWatch = Task { @MainActor [weak self] in
            while let self, !self.held.isEmpty {
                await self.sleep(Self.holdPollInterval)
                guard !Task.isCancelled else { return }
                self.releaseHeldIfClear()
            }
        }
    }

    /// Called from inside the tick as well as from outside it: cancelling the task one is running
    /// in only sets the flag, and the `while` above has already seen `held` empty by then.
    private func stopHoldWatch() {
        holdWatch?.cancel()
        holdWatch = nil
    }

    deinit {
        holdWatch?.cancel()
    }
}
