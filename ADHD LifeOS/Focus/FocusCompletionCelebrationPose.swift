//
//  FocusCompletionCelebrationPose.swift
//  ADHD LifeOS
//

import SwiftUI

/// Which celebration a completion card plays: CLAUDE.md §7.1's ladder for this one site, with
/// §7.2's Reduce Motion rule applied to it (F-ModernIOS-2-Celebration, E's 2026-09-11 decisions).
///
/// - **`.full`: Reduce Motion off, below iOS 26. This is the 16 path: block 4's burst, at the
///   longer length E asked for.**
///   The tick springs in from 0.6 while the halo radiates 1 → 1.6 and fades 0.8 → 0.
/// - **`.reduced`: Reduce Motion ON, on any OS.** The same two beats as a cross-fade. The tick
///   fades in at full size and the halo fades out at its end scale; nothing grows or moves.
/// - **`.modern`: Reduce Motion off, iOS 26+.** The tick draws itself on (`.drawOn`); the halo is
///   `.full`'s.
///
/// **There is no iOS 17 tier, and that is §7.1's filter, not an oversight.** Of the 17 symbol
/// effects, `.appear` is a scale-in without the spring's overshoot, which shows less than the floor
/// already does, and `.bounce` fires on the state change itself, ignoring the 0.3s landing delay.
/// Neither shows the user anything the 16 spring cannot, so iOS 17–25 get the floor. (The iOS 26
/// draw-on turned out to ignore the delay too, and still passes the filter: a stroke drawing
/// itself is something no 16 animation can show.)
enum FocusCompletionCelebrationMotion: CaseIterable, Equatable {
    case full, reduced, modern

    /// **Reduce Motion first, the tier second, and the order is the point** (§7.2). Symbol effects
    /// do not honour Reduce Motion themselves (`SymbolEffectOptions` has no such option in the 26.5
    /// SDK), so choosing the tier first would hand the draw-on to E's own phone: iOS 26, Reduce
    /// Motion ON. `drawOnAvailable` is injected so both answers are testable on a machine with one
    /// simulator runtime (§7.3, §7.4).
    static func resolve(reduceMotion: Bool, drawOnAvailable: Bool) -> Self {
        if reduceMotion { return .reduced }
        return drawOnAvailable ? .modern : .full
    }
}

/// One frame of the celebration: how far the halo has travelled, whether the tick has arrived, and
/// whether the geometry is pinned at rest. Pure, so the poses that matter (the ones a playing card
/// opens in and the one everything ends in) can be asserted rather than looked for.
struct FocusCompletionCelebrationPose: Equatable {
    /// 0 at the ring's edge and fully visible, 1 grown and gone — see the metrics for the ends.
    var burstProgress: Double
    var checkmarkLanded: Bool
    /// Reduce Motion's half of the pose: every SCALE already at its final value, so only opacity
    /// travels (§7.2's opening-pose rule). `false` is block 4's pose exactly.
    var geometryPinned = false

    /// The floor's and iOS 26's opening: the halo on the ring, the tick small and clear. **Only a
    /// playing card ever shows this, and only for the instant before `onAppear`.**
    static let armed = FocusCompletionCelebrationPose(burstProgress: 0, checkmarkLanded: false)

    /// Reduce Motion's opening: the halo visible but already at its end scale, the tick clear but
    /// already full size. Nothing on it can move, so the fade is all that is left to happen.
    static let armedInPlace = FocusCompletionCelebrationPose(
        burstProgress: 0, checkmarkLanded: false, geometryPinned: true
    )

    /// Where every celebration ends and every non-playing card begins: the tick at full size and no
    /// halo — the block-2 card exactly.
    static let settled = FocusCompletionCelebrationPose(burstProgress: 1, checkmarkLanded: true)

    /// **The opening decision, in one place.** A card that does not play opens settled in every
    /// mode. A playing card opens armed, and under Reduce Motion armed IN PLACE, so its first frame
    /// already has the final geometry and the pre-animation shape (a tick at 0.6) never shows.
    ///
    /// Until F-ModernIOS-2-Celebration a Reduce Motion card opened SETTLED, as the design record
    /// asked. That was a hard cut, and E, who runs Reduce Motion ON, saw nothing else.
    static func opening(plays: Bool, motion: FocusCompletionCelebrationMotion) -> Self {
        guard plays else { return .settled }
        return motion == .reduced ? .armedInPlace : .armed
    }

    /// Whether `onAppear` has anything to animate. Both armed poses do; `settled` does not.
    var isArmed: Bool { self == .armed || self == .armedInPlace }

    /// Pinned at the END scale, 1.6, never the start: at 1 the halo is coincident with the completed
    /// ring and fading it shows nothing (block 4's frame `00`). **E's lever** if the reduced halo
    /// reads too large on device.
    var burstScale: CGFloat {
        geometryPinned
            ? FocusCompletionCelebrationMetrics.burstScaleEnd
            : FocusCompletionCelebrationMetrics.burstScale(progress: burstProgress)
    }

    var burstOpacity: Double { FocusCompletionCelebrationMetrics.burstOpacity(progress: burstProgress) }

    var checkmarkScale: CGFloat {
        geometryPinned || checkmarkLanded ? 1 : FocusCompletionCelebrationMetrics.checkmarkScaleStart
    }

    var checkmarkOpacity: Double { checkmarkLanded ? 1 : 0 }
}

/// The burst's numbers, from the design record: the ring scales 1 → 1.6 while fading 0.8 → 0 on a
/// long `.easeOut`; the checkmark springs in from 0.6.
///
/// These are motion values, not spacing, so §2's grid does not govern them; they live in a named
/// enum (the `CaptureDiscMetrics` house rule) so a test can hold the endpoints and the renders in
/// `screenshots/focus-completion-celebration/` and `…-modes/` can be read against them.
enum FocusCompletionCelebrationMetrics {
    /// The ring starts exactly on the completed ring — 1 — and grows to 1.6, which is as far as
    /// the card's 76pt height allows: 44 × 1.6 = 70.4, inside the card with under 3pt to spare
    /// above and below.
    static let burstScaleStart: CGFloat = 1
    static let burstScaleEnd: CGFloat = 1.6
    static let burstOpacityStart: Double = 0.8
    static let burstOpacityEnd: Double = 0
    /// "Long" relative to the app's 0.35s spring: the ring is seen to radiate rather than blink.
    /// **E's number (2026-09-11):** block 4's 0.9s, doubled to 1.8s when E asked for the animations
    /// to be longer, then set to 2.1s when E named it. `testTheFadesRunAtTheLengthEAskedFor` holds it.
    static let burstDuration: TimeInterval = 2.1
    static let checkmarkScaleStart: CGFloat = 0.6
    /// The reduced tick's fade. Shorter than the halo's: the tick is the news and should read at
    /// once, while the halo fading out behind it is the afterglow. **E's number too:** 0.4s, then
    /// 0.8s, then 1.1s.
    static let checkmarkFadeDuration: TimeInterval = 1.1
    /// The card arrives on `RootBottomOverlay`'s 0.35s spring. Started at frame one the burst
    /// plays mostly while the card is still sliding up and the checkmark's pop is lost in the
    /// slide, so both beats wait for the card to land. The halo waits in every mode, and so do the
    /// floor's and the reduced tick; the iOS 26 draw-on does not (`FocusCompletionDrawOnTick`).
    static let delay: TimeInterval = 0.3

    static func burstScale(progress: Double) -> CGFloat {
        burstScaleStart + (burstScaleEnd - burstScaleStart) * CGFloat(progress)
    }

    static func burstOpacity(progress: Double) -> Double {
        burstOpacityStart + (burstOpacityEnd - burstOpacityStart) * progress
    }

    /// The halo's animation, in every mode. Under Reduce Motion the halo's scale is pinned, so the
    /// same curve moves only its opacity.
    static var burstAnimation: Animation {
        .easeOut(duration: burstDuration).delay(delay)
    }

    /// The tick's animation for a mode. The floor and iOS 26 share block 4's spring, looser than the
    /// house 0.8 damping on purpose (0.6 lets the tick overshoot once, the "pop" that makes it a
    /// celebration). iOS 26 inserts its draw-on in this same transaction, though the stroke runs on
    /// the symbol effect's own clock from insertion rather than on this delay. Under Reduce Motion
    /// it is a plain ease, §5's carve-out for a Reduce Motion fade: nothing springs.
    static func checkmarkAnimation(for motion: FocusCompletionCelebrationMotion) -> Animation {
        switch motion {
        case .reduced:
            return .easeOut(duration: checkmarkFadeDuration).delay(delay)
        case .full, .modern:
            return .spring(response: 0.4, dampingFraction: 0.6).delay(delay)
        }
    }
}
