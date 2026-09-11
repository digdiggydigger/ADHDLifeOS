//
//  FocusCompletionCelebration.swift
//  ADHD LifeOS
//

import SwiftUI

/// The moment a sprint finishes, drawn inside the completion card's ring (F-FocusCard-4), in the
/// motion this phone can show and this user asked for (F-ModernIOS-2-Celebration).
///
/// E's specification, verbatim: *"Full ring + name + time done + Confirm + a celebratory screen
/// animation to signify completion."* The first four are `FocusCompletionCard`; this is the fifth,
/// in the app's existing celebration grammar (`ClosureCelebrationCard`, `OfflineSprintSummaryCard`)
/// — two beats: a halo radiating from the completed ring's own edge while it fades, and the tick
/// arriving.
///
/// **It ends on the card E approved.** The settled pose is the tick at full size and no halo,
/// which is pixel-for-pixel the block-2 card; a card that does not play (one revealed by a
/// Confirm, one restored by a relaunch) opens in that pose from its first frame, in every mode. So
/// the celebration is something that happens TO the approved card, never a change to it.
///
/// **CLAUDE.md §7.1's second two-branch exemplar.** iOS 16.0 is a floor, not a ceiling, and this is
/// a DEGRADED site (feedback is never absent), so the tick always has an `else`. The three modes and
/// why there is no iOS 17 tier are `FocusCompletionCelebrationMotion`:
/// - **`.full`**, the 16 path: block 4's burst, unchanged.
/// - **`.reduced`**, Reduce Motion ON on any OS: the same two beats as a cross-fade. Geometry is
///   pinned at rest and only opacity travels (§7.2).
/// - **`.modern`**, iOS 26: the tick draws itself on (`FocusCompletionDrawOnTick`, below).
///
/// The halo stays on `withAnimation` in every mode. `PhaseAnimator(trigger:)` cycles back to its
/// first phase, which is wrong for a one-shot, and `keyframeAnimator` would add nothing visible. The
/// haptic is not here at all: it lives on `RootBottomOverlay`, keyed on `confirmableCompletionCount`,
/// because a listener on a view that is INSERTED with the trigger already changed never fires for the
/// first card. It fires under Reduce Motion, as haptics always have.
///
/// **Reduce Motion is resolved by the caller, and that is deliberate.** An `@Environment` value is
/// not readable in `init`, and the opening pose IS the initial `@State`; read here instead, the
/// floor's armed geometry would show for one frame before `onAppear` corrected it. The card passes
/// the value in, and `FocusCompletionCelebrationMotion.resolve` settles Reduce Motion BEFORE the
/// tier, because symbol effects do not honour it themselves.
struct FocusCompletionCelebration: View {
    /// Whether this card's sprint JUST finished — `true` only for the record the service stamped
    /// in `pushUnconfirmedCompletion`, so a card revealed by a Confirm does not re-celebrate.
    let plays: Bool
    let motion: FocusCompletionCelebrationMotion

    @State private var burstProgress: Double
    @State private var checkmarkLanded: Bool
    private let geometryPinned: Bool

    /// The card's door, with block 4's signature, so neither the card nor the call-site pin on
    /// `reduceMotion: reduceMotion` had to move.
    init(plays: Bool, reduceMotion: Bool) {
        self.init(
            plays: plays,
            motion: .resolve(
                reduceMotion: reduceMotion,
                drawOnAvailable: FocusCompletionCelebration.drawOnAvailable
            )
        )
    }

    /// Any mode on demand. This machine has one simulator runtime, iOS 26.5, so the floor and the
    /// reduced path are reachable in a render only by injection (§7.3).
    init(plays: Bool, motion: FocusCompletionCelebrationMotion) {
        self.plays = plays
        self.motion = motion
        let opening = FocusCompletionCelebrationPose.opening(plays: plays, motion: motion)
        _burstProgress = State(initialValue: opening.burstProgress)
        _checkmarkLanded = State(initialValue: opening.checkmarkLanded)
        geometryPinned = opening.geometryPinned
    }

    /// The `ToolsView.placesSupported` shape. It only feeds `resolve`: a `Bool` cannot narrow
    /// availability, so the tick site still carries its own `#available`.
    static var drawOnAvailable: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    private var pose: FocusCompletionCelebrationPose {
        FocusCompletionCelebrationPose(
            burstProgress: burstProgress, checkmarkLanded: checkmarkLanded, geometryPinned: geometryPinned
        )
    }

    var body: some View {
        ZStack {
            // The radiating halo: the completed ring's own stroke, at its own size, growing past
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
            tick
        }
        .accessibilityHidden(true)
        .onAppear {
            // Only an armed pose has anywhere to go, in place or not. A card that is not playing
            // opens settled and falls straight through.
            guard pose.isArmed else { return }
            withAnimation(FocusCompletionCelebrationMetrics.burstAnimation) {
                burstProgress = 1
            }
            withAnimation(FocusCompletionCelebrationMetrics.checkmarkAnimation(for: motion)) {
                checkmarkLanded = true
            }
        }
    }

    /// The tick, in the tier the resolved mode allows. `motion == .modern` sits in the SAME
    /// condition as the gate, so a Reduce Motion card never reaches the draw-on, even on iOS 26.
    @ViewBuilder
    private var tick: some View {
        if motion == .modern, #available(iOS 26.0, *) {
            FocusCompletionDrawOnTick(landed: checkmarkLanded)
        } else {
            FocusCompletionTickGlyph()
                .scaleEffect(pose.checkmarkScale)
                .opacity(pose.checkmarkOpacity)
        }
    }
}

/// The ring's bare `checkmark`, the tick the block-2 card was approved with. Both branches draw
/// this one glyph, so the draw-on comes to rest on exactly the floor's resting frame.
private struct FocusCompletionTickGlyph: View {
    var body: some View {
        Image(systemName: "checkmark")
            .font(.footnote.weight(.bold))
            .foregroundStyle(Color("StateGo"))
    }
}

/// iOS 26's tick: the glyph draws its own stroke on as it arrives.
///
/// - **An insertion transition, not `.symbolEffect(.drawOn, isActive:)`**, so the stroke is tied
///   to the tick's ARRIVAL: a card that opens settled, or is revealed by a Confirm, already has its
///   tick and draws nothing (checked in situ, `screenshots/focus-completion-celebration-modes/`).
/// - **The stroke does NOT wait for the landing transaction's 0.3s delay.** The plan expected it
///   to; rendered on the 26.5 simulator it starts drawing the moment the tick is inserted and is
///   complete in about 0.3s, before the halo begins. So on a phone the tick draws while the card is
///   still sliding up. It ships as rendered, for E's Reduce-Motion-off look (the approved plan's
///   "evidence it, don't fight it"); the lever is to land `.modern` after
///   `FocusCompletionCelebrationMetrics.delay` rather than inside it.
/// - **Insertion only.** Removal is `.identity`, so a Confirm, or `.id(celebrates)` rebuilding the
///   celebration, never draws the tick OFF.
/// - **`AsymmetricTransition`, not `.asymmetric(insertion:removal:)`.** The latter exists only on
///   `AnyTransition`, and the symbol-effect transition is a `Transition` type, so the approved
///   plan's form does not compile against the 26.5 SDK.
@available(iOS 26.0, *)
private struct FocusCompletionDrawOnTick: View {
    let landed: Bool

    var body: some View {
        ZStack {
            if landed {
                FocusCompletionTickGlyph()
                    .transition(AsymmetricTransition(insertion: .symbolEffect(.drawOn), removal: .identity))
            }
        }
    }
}

#if DEBUG
/// Every mode playing, then the settled card they all end on. The canvas runs iOS 26, so `.full`
/// and `.reduced` here are the injected floor and Reduce Motion paths (§7.3).
private struct FocusCompletionCelebrationModesPreview: View {
    var body: some View {
        HStack(spacing: 24) {
            ForEach(FocusCompletionCelebrationMotion.allCases, id: \.self) { motion in
                ring(FocusCompletionCelebration(plays: true, motion: motion))
            }
            ring(FocusCompletionCelebration(plays: false, motion: .full))
        }
        .padding(24)
    }

    private func ring(_ celebration: FocusCompletionCelebration) -> some View {
        ClosureRing(
            progress: 1, size: FocusCompletionCardMetrics.ringSize,
            lineWidth: FocusCompletionCardMetrics.ringLineWidth,
            arcStyle: AnyShapeStyle(Color("StateGo"))
        ) { celebration }
    }
}

#Preview("Light") {
    FocusCompletionCelebrationModesPreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    FocusCompletionCelebrationModesPreview()
        .preferredColorScheme(.dark)
}
#endif
