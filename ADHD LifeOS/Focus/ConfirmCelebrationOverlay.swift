//
//  ConfirmCelebrationOverlay.swift
//  ADHD LifeOS
//
//  F-ConfirmCelebration-1: the full-screen celebration a Confirm sets off — the done-green glow,
//  then confetti raining from the top and fired from both bottom corners. F-ConfirmCelebration-2
//  adds what the STACK-CLEARING Confirm gets on top: 14 fireworks, and in light appearance a dim
//  beneath everything for their duration. E's design, every number and the why:
//  `handoff/SESSION-OPENER-confirm-celebration-design.md`.
//
//  `F-CTACelebrations-2` adds the one gate: E's Settings "Celebrations" switch, read at FIRE time,
//  so the row is never a lie about the only full-screen celebration that exists yet.
//
//  **Reduce Motion is not read anywhere in here, on purpose.** E waived CLAUDE.md §7.2 for this one
//  moment ("B AND C": with Reduce Motion ON, the glow AND real falling confetti), so it plays the
//  same either way. `testTheConfirmCelebrationIgnoresReduceMotionByDesign` pins that.
//
//  **A single implementation, with no `#available` (§7.1).** `Canvas` and `TimelineView` are iOS
//  15, below the floor, and no later tier adds anything a particle field can use: `MeshGradient`
//  (18) would draw the glow the radial gradient already draws, and `.visualEffect` (17) or
//  `.glassEffect` (26) have nothing to act on.
//

import SwiftUI

/// Mounted once by `RootView` above the bottom furniture and below the covers (R3).
///
/// Always present and drawing nothing while nothing is live: the `.onChange` has to be listening
/// before the first Confirm lands (the trap `testTheHapticListenerOutlivesTheStack` records), and
/// the frame clock has to stop when the last burst ends.
struct ConfirmCelebrationOverlay: View {
    @ObservedObject var focusService: FocusSessionService
    /// E's Celebrations switch (#3), consulted as each Confirm lands rather than read once —
    /// `Haptics.play(gate:)`'s arrangement, so flipping it in Settings takes effect on the very next
    /// Confirm with no relaunch. Injected so a render probe can show the switched-off state without
    /// writing the simulator's own `UserDefaults`.
    var celebrationsGate: () -> Bool = { AppFeedback.celebrationsEnabled() }
    @State private var bursts: [ConfirmCelebrationBurst] = []

    var body: some View {
        GeometryReader { proxy in
            if !bursts.isEmpty {
                ConfirmCelebrationStage(bursts: bursts, canvas: proxy.size)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: focusService.latestConfirmation) { confirmation in
            guard let confirmation else { return }
            // Before the burst is appended, never after: on the list it is already drawing and the
            // frame clock is already running. The haptic is NOT gated — it fires from
            // `RootBottomOverlay`, because E's switch covers the full-screen celebration alone.
            guard celebrationsGate() else { return }
            let now = Date()
            bursts = ConfirmCelebrationQueue.adding(
                ConfirmCelebrationBurst(confirmation: confirmation, start: now), to: bursts, now: now
            )
        }
        // Removes each burst the moment it ends. Keyed on the list, so every change re-arms it for
        // whichever burst ends next; with nothing live it returns at once and nothing is scheduled.
        .task(id: bursts) {
            guard let expiry = ConfirmCelebrationQueue.nextExpiry(of: bursts) else { return }
            let wait = expiry.timeIntervalSinceNow
            if wait > 0 {
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            // Pruned at the expiry at the latest, so a sleep that wakes a hair early still removes
            // the burst it was waiting for rather than leaving the list — and the clock — unchanged.
            bursts = ConfirmCelebrationQueue.pruned(bursts, now: max(Date(), expiry))
        }
    }
}

/// The live bursts on a frame clock. Built only while something is in the air, so
/// `TimelineView(.animation)` asks for frames only then.
///
/// Each burst's 220 pieces — and, for a stack-clearing Confirm, its 14 shells and 880 sparks —
/// are generated here, once per change to the live list, never inside the per-frame closure.
struct ConfirmCelebrationStage: View {
    let bursts: [ConfirmCelebrationBurst]
    let canvas: CGSize

    var body: some View {
        let scenes = bursts.map { burst in
            ConfirmCelebrationScene(
                burst: burst,
                confetti: ConfettiRecipe.everyConfirm(canvas: canvas, ordinal: burst.ordinal),
                fireworks: burst.clearedStack ? ConfirmFireworks(canvas: canvas) : nil
            )
        }
        TimelineView(.animation) { timeline in
            ConfirmCelebrationFrame(scenes: scenes, date: timeline.date)
        }
    }
}

/// One burst with the pieces it launched. `fireworks` is set only for a stack-clearing Confirm
/// (E's decision 2: the fireworks ARE the bigger burst; the confetti is identical on both).
struct ConfirmCelebrationScene {
    let burst: ConfirmCelebrationBurst
    let confetti: [ConfettiPiece]
    var fireworks: ConfirmFireworks?

    init(burst: ConfirmCelebrationBurst, confetti: [ConfettiPiece], fireworks: ConfirmFireworks? = nil) {
        self.burst = burst
        self.confetti = confetti
        self.fireworks = fireworks
    }
}

/// One frame of the celebration at an explicit instant — what the stage draws on each tick, and
/// what previews and render probes draw at any `date` they choose.
///
/// Back to front, the record's order: the dim (light appearance, stack-clearing bursts only), the
/// glow, the fireworks, then the confetti — so the green wash reads over the night sky and the
/// paper stays in front of the sparks.
struct ConfirmCelebrationFrame: View {
    let scenes: [ConfirmCelebrationScene]
    let date: Date

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let dim = ConfirmCelebrationDim.strongestEnvelope(of: scenes.map(\.burst), at: date)
        ZStack {
            // Light only (E, #7: "for light-mode display views"); dark does not dim (R6). Gated on
            // the envelope too, so an every-Confirm frame carries no extra layer at all.
            if colorScheme == .light, dim > 0 {
                Color(ConfirmCelebrationDim.colorName).opacity(ConfirmCelebrationDim.peakOpacity * dim)
            }

            RadialGradient(
                colors: [
                    Color(ConfirmCelebrationGlow.colorName).opacity(ConfirmCelebrationGlow.peakOpacity),
                    Color(ConfirmCelebrationGlow.colorName).opacity(0)
                ],
                center: .bottom,
                startRadius: 0,
                endRadius: ConfirmCelebrationGlow.radius
            )
            .opacity(ConfirmCelebrationGlow.strongestEnvelope(of: scenes.map(\.burst), at: date))

            Canvas { context, _ in
                // The nine token shadings (the confetti's seven plus the fireworks' two), resolved
                // once per frame rather than once per piece.
                var shadings: [String: GraphicsContext.Shading] = [:]
                for name in ConfirmFireworksSchedule.palette {
                    shadings[name] = context.resolve(.color(Color(name)))
                }
                for scene in scenes {
                    let elapsed = ConfirmCelebrationQueue.choreographyTime(of: scene.burst, at: date)
                    if let fireworks = scene.fireworks {
                        ConfirmFireworksDrawing.draw(fireworks, in: context, at: elapsed, shadings: shadings)
                    }
                    for piece in scene.confetti {
                        guard let state = ConfettiPhysics.state(of: piece, at: elapsed) else { continue }
                        var pieceContext = context
                        pieceContext.opacity = state.opacity
                        pieceContext.translateBy(x: state.position.x, y: state.position.y)
                        pieceContext.rotate(by: .radians(state.rotation))
                        pieceContext.scaleBy(x: state.tumbleScale, y: 1)
                        let bounds = CGRect(
                            x: -piece.size.width / 2, y: -piece.size.height / 2,
                            width: piece.size.width, height: piece.size.height
                        )
                        let path = piece.shape == .circle ? Path(ellipseIn: bounds) : Path(bounds)
                        pieceContext.fill(path, with: shadings[piece.colorName] ?? .color(Color(piece.colorName)))
                    }
                }
            }
        }
    }
}

// MARK: - Previews

/// A Confirm 1.2 s of choreography in — glow at full strength, rain halfway down, the cannons'
/// pieces at their peak — over the page background, in both appearances. With `clearedStack` the
/// first four shells are up (two burst, one bursting, one climbing) and, in light, the dim is on.
private struct ConfirmCelebrationFramePreview: View {
    private static let start = Date(timeIntervalSince1970: 1_800_000_000)
    var clearedStack = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.pageBackground
                ConfirmCelebrationFrame(
                    scenes: [
                        ConfirmCelebrationScene(
                            burst: ConfirmCelebrationBurst(ordinal: 1, clearedStack: clearedStack, start: Self.start),
                            confetti: ConfettiRecipe.everyConfirm(canvas: proxy.size, ordinal: 1),
                            fireworks: clearedStack ? ConfirmFireworks(canvas: proxy.size) : nil
                        )
                    ],
                    date: Self.start.addingTimeInterval(1.2 / ConfirmCelebrationQueue.pace)
                )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Light") {
    ConfirmCelebrationFramePreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ConfirmCelebrationFramePreview()
        .preferredColorScheme(.dark)
}

#Preview("Stack cleared · Light") {
    ConfirmCelebrationFramePreview(clearedStack: true)
        .preferredColorScheme(.light)
}

#Preview("Stack cleared · Dark") {
    ConfirmCelebrationFramePreview(clearedStack: true)
        .preferredColorScheme(.dark)
}
