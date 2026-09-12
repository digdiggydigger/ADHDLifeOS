//
//  CelebrationFrame.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-3`: one frame of every live celebration at an explicit instant — what the
//  stage draws on each tick, and what previews and render probes draw at any `date` they choose.
//
//  Moved here from `ConfirmCelebrationOverlay.swift` (deleted) and generalised from the Confirm to
//  every kind. **The drawing order is unchanged and is the Confirm record's**: back to front, the
//  dim (light appearance, stack-clearing bursts only), the glow, the fireworks, then the confetti —
//  so the green wash reads over the night sky and the paper stays in front of the sparks.
//
//  **This file reads Reduce Motion NOWHERE, and that is load-bearing** (CLAUDE.md §7.2, E's waiver
//  of it for Confirm). The rendering arrives already resolved, per scene, from
//  `CelebrationMotion.resolve` — §7.2's rule that a leaf which must be testable in both modes takes
//  the resolved value as a PARAMETER. `ConfirmCelebrationCallSiteTests` sweeps this file for the
//  setting's name.
//
//  **A single implementation, no `#available` (§7.1).** `Canvas` and `TimelineView` are iOS 15,
//  below the floor, and no later tier adds anything a particle field can use: `MeshGradient` (18)
//  would draw the glow the radial gradient already draws, and `.visualEffect` (17) or
//  `.glassEffect` (26) have nothing to act on.
//

import SwiftUI

/// One burst with the pieces it launched and how they are to be drawn.
struct CelebrationScene {
    let burst: CelebrationBurst
    /// `.full` or `.still`, resolved once by `CelebrationMotion` — never read from the environment
    /// here.
    let rendering: CelebrationRendering
    let confetti: [ConfettiPiece]
    /// Set only for a stack-clearing Confirm (E's decision 2: the fireworks ARE the bigger burst;
    /// the confetti is identical on both).
    var fireworks: ConfirmFireworks?

    init(
        burst: CelebrationBurst,
        rendering: CelebrationRendering,
        confetti: [ConfettiPiece],
        fireworks: ConfirmFireworks? = nil
    ) {
        self.burst = burst
        self.rendering = rendering
        self.confetti = confetti
        self.fireworks = fireworks
    }
}

struct CelebrationFrame: View {
    let scenes: [CelebrationScene]
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
                    let elapsed = CelebrationQueue.choreographyTime(of: scene.burst, at: date)
                    if let fireworks = scene.fireworks {
                        ConfirmFireworksDrawing.draw(fireworks, in: context, at: elapsed, shadings: shadings)
                    }
                    for piece in scene.confetti {
                        guard let state = Self.state(of: piece, in: scene, at: date, elapsed: elapsed) else {
                            continue
                        }
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

    /// A flying piece is placed by the physics on the stretched choreography clock; a still one
    /// never leaves its opening pose and is placed by its fade alone, over the burst's real
    /// on-screen length (§7.2 — replace motion with a fade, never remove the feedback).
    private static func state(
        of piece: ConfettiPiece, in scene: CelebrationScene, at date: Date, elapsed: TimeInterval
    ) -> ConfettiPieceState? {
        switch scene.rendering {
        case .full:
            return ConfettiPhysics.state(of: piece, at: elapsed)
        case .still:
            return CelebrationStillField.state(
                of: piece,
                at: date.timeIntervalSince(scene.burst.start),
                length: CelebrationQueue.length(of: scene.burst)
            )
        }
    }
}

// MARK: - Previews

/// A Confirm 1.2 s of choreography in — glow at full strength, rain halfway down, the cannons'
/// pieces at their peak — over the page background, in both appearances. With `clearedStack` the
/// first four shells are up (two burst, one bursting, one climbing) and, in light, the dim is on.
private struct CelebrationFramePreview: View {
    private static let start = Date(timeIntervalSince1970: 1_800_000_000)
    var clearedStack = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.pageBackground
                CelebrationFrame(
                    scenes: [
                        CelebrationScene(
                            burst: CelebrationBurst(
                                ordinal: 1, kind: .confirm(clearedStack: clearedStack),
                                surface: .root, start: Self.start, origin: nil
                            ),
                            rendering: .full,
                            confetti: ConfettiRecipe.everyConfirm(canvas: proxy.size, ordinal: 1),
                            fireworks: clearedStack ? ConfirmFireworks(canvas: proxy.size) : nil
                        )
                    ],
                    date: Self.start.addingTimeInterval(1.2 / ConfirmCelebrationClock.pace)
                )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Light") {
    CelebrationFramePreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CelebrationFramePreview()
        .preferredColorScheme(.dark)
}

#Preview("Stack cleared · Light") {
    CelebrationFramePreview(clearedStack: true)
        .preferredColorScheme(.light)
}

#Preview("Stack cleared · Dark") {
    CelebrationFramePreview(clearedStack: true)
        .preferredColorScheme(.dark)
}
