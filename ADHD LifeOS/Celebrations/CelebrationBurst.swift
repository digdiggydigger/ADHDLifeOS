//
//  CelebrationBurst.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-3`: one celebration on screen, and the live list of them.
//
//  Generalised from `ConfirmCelebrationQueue`, which became `ConfirmCelebrationClock` and now holds
//  only the Confirm's numbers. Everything E approved about the Confirm's queue is unchanged here:
//  quick celebrations OVERLAP rather than restart, at most `fullScreenCap` at once with the oldest
//  dropped (the Confirm record's R1), and every burst is removed the moment it ends so the frame
//  clock stops.
//
//  **The two families do not share a cap.** Eight pops in the air is ordinary — E's F6 puts one on
//  every task close — while a fourth full-screen celebration must still drop the oldest. One shared
//  cap of 3 would let three quick task closes evict a Confirm; one shared cap of 8 would stack
//  eight done-green washes.
//

import CoreGraphics
import Foundation

/// One celebration on screen, with everything needed to draw it and nothing else.
struct CelebrationBurst: Equatable, Identifiable {
    /// The centre's counter. Two jobs, both drawing: SwiftUI's identity for the burst, and the seed
    /// its paper is generated from. **Never a haptic trigger** — that stayed on the focus service's
    /// own ordinal, so a pop can never buzz like a Confirm.
    let ordinal: Int
    let kind: CelebrationKind
    /// Which layer draws it. A burst is tagged when it is requested, so a celebration started
    /// behind a cover never appears over it.
    let surface: CelebrationSurface
    let start: Date
    /// Where a pop was tapped, in GLOBAL coordinates; `nil` for a full-screen celebration, which
    /// has no origin but the screen.
    let origin: CGPoint?

    var id: Int { ordinal }

    /// The one Confirm that earns the fireworks and the light-mode dim.
    var clearedStack: Bool {
        if case .confirm(let cleared) = kind { return cleared }
        return false
    }

    /// Full-screen celebrations and pops are capped, timed and cooled down differently.
    var isFullScreen: Bool {
        if case .pop = kind { return false }
        return true
    }
}

/// The live bursts: what is on screen, for how long, and on which clock.
enum CelebrationQueue {
    /// The Confirm record's R1, which E approved and which is unchanged.
    static let fullScreenCap = 3
    /// E's F6 puts a pop on every task close, and a swipe down a list of them is the normal case.
    static let popCap = 8
    /// E's F6: "lives 0.7–1.0 s". The layer draws a pop for one second and drops it.
    static let popLength: TimeInterval = 1.0

    /// How long a burst stays on screen.
    static func length(of burst: CelebrationBurst) -> TimeInterval {
        switch burst.kind {
        case .pop:
            return popLength
        case .confirm(let clearedStack):
            return clearedStack ? ConfirmCelebrationClock.stackClearingLength
                                : ConfirmCelebrationClock.everyConfirmLength
        case .milestone:
            // E's F8: "the every-Confirm size" — the same celebration, not a length of its own.
            return ConfirmCelebrationClock.everyConfirmLength
        }
    }

    /// Where `burst` is in its choreography at `date`.
    ///
    /// **Two clocks, on purpose.** E's extra 1.2 s is a STRETCH of the full-screen choreography, so
    /// a Confirm or a milestone is drawn at `pace` (~78% of wall-clock). A pop has no stretch to
    /// inherit — it is a one-second flourish, and running it at 78% would leave it hanging.
    static func choreographyTime(of burst: CelebrationBurst, at date: Date) -> TimeInterval {
        let elapsed = date.timeIntervalSince(burst.start)
        return burst.isFullScreen ? elapsed * ConfirmCelebrationClock.pace : elapsed
    }

    /// Adds `burst`, having first dropped whatever has already ended, and caps its own family.
    static func adding(
        _ burst: CelebrationBurst, to bursts: [CelebrationBurst], now: Date
    ) -> [CelebrationBurst] {
        capped(pruned(bursts, now: now) + [burst])
    }

    /// Only the bursts still in the air at `now`. A burst ends exactly at its length.
    static func pruned(_ bursts: [CelebrationBurst], now: Date) -> [CelebrationBurst] {
        bursts.filter { now < end(of: $0) }
    }

    /// When the soonest-ending live burst ends, or `nil` with nothing live. The sweep re-arms on
    /// every change, so waiting for the soonest is what removes each burst the moment it finishes.
    static func nextExpiry(of bursts: [CelebrationBurst]) -> Date? {
        bursts.map { end(of: $0) }.min()
    }

    /// Each family capped separately, and the original order kept, so a pop can never evict a
    /// full-screen celebration and the ids stay in the order they were issued.
    private static func capped(_ bursts: [CelebrationBurst]) -> [CelebrationBurst] {
        let keep = Set(
            bursts.filter(\.isFullScreen).suffix(fullScreenCap).map(\.ordinal)
                + bursts.filter { !$0.isFullScreen }.suffix(popCap).map(\.ordinal)
        )
        return bursts.filter { keep.contains($0.ordinal) }
    }

    private static func end(of burst: CelebrationBurst) -> Date {
        burst.start.addingTimeInterval(length(of: burst))
    }
}
