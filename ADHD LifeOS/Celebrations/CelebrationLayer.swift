//
//  CelebrationLayer.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-3`: where a celebration is DRAWN. **E chose one layer per presented surface**
//  over a passthrough `UIWindow` (the design record's ARCH question), so this view is mounted four
//  times — on the root, the routine cover, the Tasks search surface and the Create Task sheet — and
//  each mount draws only the bursts tagged with its own surface.
//
//  The shipped root overlay sits BELOW every sheet and cover; that is the whole reason the covers
//  need layers of their own. `CelebrationMountCallSiteTests` enumerates the four and counts them,
//  because a fifth presented surface that hosts a site and mounts nothing would simply draw nothing
//  and pass every other test in the suite.
//
//  **Reduce Motion is read HERE and passed down as a value.** The frame and the Confirm's own files
//  never mention it (§7.2's waiver pin), and `CelebrationMotion` resolves it before any rendering is
//  chosen.
//

import SwiftUI

/// The mount. Draws nothing at all without a centre in the environment, which is the right
/// behaviour for a preview or a snapshot test and is why the app's wiring is asserted separately.
struct CelebrationLayer: View {
    let surface: CelebrationSurface

    @Environment(\.celebrationCenter) private var center: CelebrationCenter?

    var body: some View {
        if let center {
            CelebrationSurfaceLayer(surface: surface, center: center)
        }
    }
}

/// One surface's live celebrations. Always present and drawing nothing while nothing is live: the
/// frame clock has to stop when the last burst ends, and the layer has to be mounted before the
/// first burst arrives.
struct CelebrationSurfaceLayer: View {
    let surface: CelebrationSurface
    @ObservedObject var center: CelebrationCenter

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let bursts = center.bursts(on: surface)
        GeometryReader { proxy in
            if !bursts.isEmpty {
                CelebrationStage(
                    bursts: bursts,
                    canvas: proxy.size,
                    layerOrigin: proxy.frame(in: .global).origin,
                    reduceMotion: reduceMotion
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        // The centre ignores `.root`, which is the base of its stack rather than a presentation, so
        // this can be unconditional. Dismissal is the presenter's job, not this view's: `PlaceRoutineScreen`
        // records `onDisappear` as unreliable for that cover.
        .onAppear { center.surfacePresented(surface) }
        // Removes each burst the moment it ends. Keyed on the whole live list, so every change
        // re-arms it for whichever burst ends next; with nothing live it returns at once.
        .task(id: center.bursts) {
            // ONE sweep for a list four layers share — four would race on the same array, and
            // three of them are mounted only while their surface is up.
            guard surface == .root else { return }
            guard let expiry = CelebrationQueue.nextExpiry(of: center.bursts) else { return }
            let wait = expiry.timeIntervalSinceNow
            if wait > 0 {
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            // Pruned at the expiry at the latest, so a sleep that wakes a hair early still removes
            // the burst it was waiting for rather than leaving the list — and the clock — unchanged.
            center.prune(now: max(Date(), expiry))
        }
    }
}

/// The live bursts on a frame clock. Built only while something is in the air, so
/// `TimelineView(.animation)` asks for frames only then.
///
/// Each burst's pieces are generated HERE, once per change to the live list, never inside the
/// per-frame closure — 220 of them for a full-screen celebration, plus 14 shells and 880 sparks for
/// a stack-clearing Confirm.
struct CelebrationStage: View {
    let bursts: [CelebrationBurst]
    let canvas: CGSize
    /// This layer's own position in the window. A pop's origin is recorded globally, because the
    /// control that was tapped and the layer that draws the paper are rarely in the same space.
    let layerOrigin: CGPoint
    let reduceMotion: Bool

    var body: some View {
        let scenes = bursts.map { burst in
            let rendering = CelebrationMotion.resolve(reduceMotion: reduceMotion, kind: burst.kind)
            return CelebrationScene(
                burst: burst,
                rendering: rendering,
                confetti: confetti(for: burst, rendering: rendering),
                fireworks: burst.clearedStack ? ConfirmFireworks(canvas: canvas) : nil
            )
        }
        TimelineView(.animation) { timeline in
            CelebrationFrame(scenes: scenes, date: timeline.date)
        }
    }

    private func confetti(for burst: CelebrationBurst, rendering: CelebrationRendering) -> [ConfettiPiece] {
        switch (burst.kind, rendering) {
        case (.pop, .full):
            return CelebrationRecipes.pop(at: local(burst.origin), ordinal: burst.ordinal)
        case (.pop, .still):
            return CelebrationRecipes.stillPop(at: local(burst.origin), ordinal: burst.ordinal)
        case (_, .full):
            // E's F8: the milestones are the every-Confirm size, so they share its recipe exactly.
            return ConfettiRecipe.everyConfirm(canvas: canvas, ordinal: burst.ordinal)
        case (_, .still):
            return CelebrationRecipes.stillField(canvas: canvas, ordinal: burst.ordinal)
        }
    }

    /// A global point in this layer's own space. A burst with no origin is centred, which only
    /// happens if a pop is ever requested without one.
    private func local(_ origin: CGPoint?) -> CGPoint {
        guard let origin else { return CGPoint(x: canvas.width / 2, y: canvas.height / 2) }
        return CGPoint(x: origin.x - layerOrigin.x, y: origin.y - layerOrigin.y)
    }
}
