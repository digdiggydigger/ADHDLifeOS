//
//  FocusCompletionCelebration.swift
//  ADHD LifeOS
//

import SwiftUI

/// The moment a sprint finishes, drawn inside the completion card's ring (F-FocusCard-4).
///
/// E's specification, verbatim: *"Full ring + name + time done + Confirm + a celebratory screen
/// animation to signify completion."* The first four are `FocusCompletionCard`; this is the fifth,
/// in the app's existing celebration grammar (`ClosureCelebrationCard`, `OfflineSprintSummaryCard`)
/// — a two-part burst: a ring radiating outward from the completed ring's own edge while it fades,
/// and the checkmark springing in from small.
///
/// **It ends on the card E approved.** The settled pose is the checkmark at full size and no ring
/// at all, which is pixel-for-pixel the block-2 card; a card that does not play (one revealed by a
/// Confirm, one restored by a relaunch) opens in that pose from its first frame. So the burst is
/// something that happens TO the approved card, never a change to it.
///
/// **iOS 16 is the floor.** No `PhaseAnimator`, `.symbolEffect`, `.keyframeAnimator` or
/// `.sensoryFeedback` — two `withAnimation` calls from `onAppear`, which is all a two-beat burst
/// needs. The haptic is not here at all: it lives on `RootBottomOverlay`, keyed on
/// `confirmableCompletionCount`, because a listener on a view that is INSERTED with the trigger
/// already changed never fires for the first card.
///
/// **Reduce Motion is resolved by the caller, and that is deliberate.** An `@Environment` value is
/// not readable in `init`, and the opening pose IS the initial `@State`; read it here instead, the
/// armed pose (ring at 0.8, checkmark at 0.6) would show for one frame before `onAppear` corrected
/// it. `FocusCompletionCelebrationPose.opening(plays:reduceMotion:)` makes the decision pure, and
/// `testReduceMotionOpensOnTheFinalState` holds the trap the design record names.
struct FocusCompletionCelebration: View {
    /// Whether this card's sprint JUST finished — `true` only for the record the service stamped
    /// in `pushUnconfirmedCompletion`, so a card revealed by a Confirm does not re-celebrate.
    let plays: Bool

    @State private var burstProgress: Double
    @State private var checkmarkLanded: Bool

    init(plays: Bool, reduceMotion: Bool) {
        self.plays = plays
        let opening = FocusCompletionCelebrationPose.opening(plays: plays, reduceMotion: reduceMotion)
        _burstProgress = State(initialValue: opening.burstProgress)
        _checkmarkLanded = State(initialValue: opening.checkmarkLanded)
    }

    private var pose: FocusCompletionCelebrationPose {
        FocusCompletionCelebrationPose(burstProgress: burstProgress, checkmarkLanded: checkmarkLanded)
    }

    var body: some View {
        ZStack {
            // The radiating ring: the completed ring's own stroke, at its own size, growing past
            // it and fading — so it reads as the ring radiating rather than a second shape.
            // `ClosureRing` frames its `ZStack` without clipping, which is what lets this grow
            // beyond the 44pt the ring occupies.
            Circle()
                .stroke(Color("StateGo"), lineWidth: FocusCompletionCardMetrics.ringLineWidth)
                .frame(
                    width: FocusCompletionCardMetrics.ringSize,
                    height: FocusCompletionCardMetrics.ringSize
                )
                .scaleEffect(pose.burstScale)
                .opacity(pose.burstOpacity)
            Image(systemName: "checkmark")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color("StateGo"))
                .scaleEffect(pose.checkmarkScale)
                .opacity(pose.checkmarkOpacity)
        }
        .accessibilityHidden(true)
        .onAppear {
            // Only an ARMED pose has anywhere to go. Settled cards — not playing, or Reduce Motion
            // — fall straight through and never animate.
            guard pose == .armed else { return }
            withAnimation(FocusCompletionCelebrationMetrics.burstAnimation) {
                burstProgress = 1
            }
            withAnimation(FocusCompletionCelebrationMetrics.checkmarkAnimation) {
                checkmarkLanded = true
            }
        }
    }
}

/// One frame of the celebration: how far the ring has travelled and whether the checkmark has
/// arrived. Pure, so the two poses that matter — the one a playing card opens in and the one
/// everything ends in — can be asserted rather than looked for.
struct FocusCompletionCelebrationPose: Equatable {
    /// 0 at the ring's edge and fully visible, 1 grown and gone — see the metrics for the ends.
    var burstProgress: Double
    var checkmarkLanded: Bool

    /// The pre-animation pose: ring at the ring, checkmark small and clear. **Only a playing card
    /// ever shows this, and only for the instant before `onAppear`.**
    static let armed = FocusCompletionCelebrationPose(burstProgress: 0, checkmarkLanded: false)

    /// Where every celebration ends and every non-playing card begins: the checkmark at full size
    /// and no ring — the block-2 card exactly.
    static let settled = FocusCompletionCelebrationPose(burstProgress: 1, checkmarkLanded: true)

    /// **The Reduce Motion decision, in one place.** A card that plays opens armed so the burst
    /// has somewhere to travel from; under Reduce Motion it opens SETTLED — the final state, never
    /// the pre-animation one, which is the trap that makes reduce-motion paths look broken.
    static func opening(plays: Bool, reduceMotion: Bool) -> FocusCompletionCelebrationPose {
        plays && !reduceMotion ? .armed : .settled
    }

    var burstScale: CGFloat { FocusCompletionCelebrationMetrics.burstScale(progress: burstProgress) }
    var burstOpacity: Double { FocusCompletionCelebrationMetrics.burstOpacity(progress: burstProgress) }
    var checkmarkScale: CGFloat { checkmarkLanded ? 1 : FocusCompletionCelebrationMetrics.checkmarkScaleStart }
    var checkmarkOpacity: Double { checkmarkLanded ? 1 : 0 }
}

/// The burst's numbers, from the design record: the ring scales 1 → 1.6 while fading 0.8 → 0 on a
/// long `.easeOut`; the checkmark springs in from 0.6.
///
/// These are motion values, not spacing, so §2's grid does not govern them; they live in a named
/// enum (the `CaptureDiscMetrics` house rule) so a test can hold the endpoints and the render in
/// `screenshots/focus-completion-celebration/` can be read against them.
enum FocusCompletionCelebrationMetrics {
    /// The ring starts exactly on the completed ring — 1 — and grows to 1.6, which is as far as
    /// the card's 76pt height allows: 44 × 1.6 = 70.4, inside the card with under 3pt to spare
    /// above and below.
    static let burstScaleStart: CGFloat = 1
    static let burstScaleEnd: CGFloat = 1.6
    static let burstOpacityStart: Double = 0.8
    static let burstOpacityEnd: Double = 0
    /// "Long" relative to the app's 0.35s spring: the ring is seen to radiate rather than blink.
    static let burstDuration: TimeInterval = 0.9
    static let checkmarkScaleStart: CGFloat = 0.6
    /// The card arrives on `RootBottomOverlay`'s 0.35s spring. Started at frame one the burst
    /// plays mostly while the card is still sliding up and the checkmark's pop is lost in the
    /// slide, so both beats wait for the card to land.
    static let delay: TimeInterval = 0.3

    static func burstScale(progress: Double) -> CGFloat {
        burstScaleStart + (burstScaleEnd - burstScaleStart) * CGFloat(progress)
    }

    static func burstOpacity(progress: Double) -> Double {
        burstOpacityStart + (burstOpacityEnd - burstOpacityStart) * progress
    }

    static var burstAnimation: Animation {
        .easeOut(duration: burstDuration).delay(delay)
    }

    /// Looser than the house 0.8 damping on purpose — 0.6 lets the checkmark overshoot once, which
    /// is the "pop" that makes it a celebration rather than a fade.
    static var checkmarkAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.6).delay(delay)
    }
}

#if DEBUG
#Preview("Light") {
    HStack(spacing: 24) {
        ClosureRing(
            progress: 1, size: FocusCompletionCardMetrics.ringSize,
            lineWidth: FocusCompletionCardMetrics.ringLineWidth,
            arcStyle: AnyShapeStyle(Color("StateGo"))
        ) { FocusCompletionCelebration(plays: true, reduceMotion: false) }
        ClosureRing(
            progress: 1, size: FocusCompletionCardMetrics.ringSize,
            lineWidth: FocusCompletionCardMetrics.ringLineWidth,
            arcStyle: AnyShapeStyle(Color("StateGo"))
        ) { FocusCompletionCelebration(plays: false, reduceMotion: false) }
    }
    .padding(24)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    HStack(spacing: 24) {
        ClosureRing(
            progress: 1, size: FocusCompletionCardMetrics.ringSize,
            lineWidth: FocusCompletionCardMetrics.ringLineWidth,
            arcStyle: AnyShapeStyle(Color("StateGo"))
        ) { FocusCompletionCelebration(plays: true, reduceMotion: false) }
        ClosureRing(
            progress: 1, size: FocusCompletionCardMetrics.ringSize,
            lineWidth: FocusCompletionCardMetrics.ringLineWidth,
            arcStyle: AnyShapeStyle(Color("StateGo"))
        ) { FocusCompletionCelebration(plays: true, reduceMotion: true) }
    }
    .padding(24)
    .preferredColorScheme(.dark)
}
#endif
