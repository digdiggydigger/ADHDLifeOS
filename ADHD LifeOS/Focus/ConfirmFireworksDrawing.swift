//
//  ConfirmFireworksDrawing.swift
//  ADHD LifeOS
//
//  F-ConfirmCelebration-2: the light-appearance dim under a stack-clearing Confirm's fireworks,
//  and the Canvas operations that draw the fireworks themselves. The frame that hosts both is
//  `ConfirmCelebrationFrame` (`ConfirmCelebrationOverlay.swift`), drawn back to front: the dim,
//  the glow, the fireworks, the confetti.
//
//  Reduce Motion is not read here, on purpose: E's waiver of CLAUDE.md §7.2 covers the whole
//  Confirm celebration, and `testTheConfirmCelebrationIgnoresReduceMotionByDesign` lists this file.
//

import SwiftUI

/// E, by video (#7, #8): in LIGHT appearance the screen dims to 85% for the duration of the
/// fireworks, which "reads like a night sky"; 55% "goes flat grey". Dark appearance never dims.
enum ConfirmCelebrationDim {
    static let colorName = "Scrim"
    static let peakOpacity: Double = 0.85
    static let fadeIn: TimeInterval = 0.35
    /// Held until this long before the last spark dies, so the sky is dark for every ember.
    static let holdMargin: TimeInterval = 0.4
    static let fadeOut: TimeInterval = 0.6

    static var holdUntil: TimeInterval { ConfirmFireworksSchedule.lastSparkTime - holdMargin }
    static var goneBy: TimeInterval { holdUntil + fadeOut }

    /// How strongly the dim shows `time` seconds after its Confirm, 0…1.
    static func envelope(at time: TimeInterval) -> Double {
        if time <= 0 { return 0 }
        if time < fadeIn { return time / fadeIn }
        if time <= holdUntil { return 1 }
        return max(0, 1 - (time - holdUntil) / fadeOut)
    }

    /// Only stack-clearing bursts dim, and overlapping ones share ONE dim at the strongest
    /// envelope — the glow's rule — so the screen never goes darker than anything E saw.
    static func strongestEnvelope(of bursts: [ConfirmCelebrationBurst], at date: Date) -> Double {
        bursts.filter(\.clearedStack)
            .map { envelope(at: ConfirmCelebrationQueue.choreographyTime(of: $0, at: date)) }
            .max() ?? 0
    }
}

/// The fireworks' Canvas operations at one instant. Nothing here is a view; it draws into the
/// frame's context so the whole celebration stays on one frame clock.
enum ConfirmFireworksDrawing {
    static let shellHeadDiameter: CGFloat = 5
    static let shellTrailWidth: CGFloat = 2.5
    static let shellTrailOpacity: Double = 0.55
    static let sparkWidth: CGFloat = 2.4

    /// Draws every shell in flight, every flash and every live spark at `time` on the choreography
    /// clock. `shadings` are the palette's colours resolved once per frame by the caller. A copy
    /// of a `GraphicsContext` draws into the same canvas, so the context is taken by value.
    static func draw(
        _ fireworks: ConfirmFireworks, in context: GraphicsContext, at time: TimeInterval,
        shadings: [String: GraphicsContext.Shading]
    ) {
        for (index, shell) in fireworks.shells.enumerated() {
            let first = shell.colorNames[0]
            let shading = shadings[first] ?? .color(Color(first))
            drawShell(shell, in: context, at: time, canvas: fireworks.canvas, shading: shading)
            let sinceBurst = time - ConfirmFireworksPhysics.burstTime(of: shell)
            guard sinceBurst >= 0 else { continue }
            drawFlash(of: shell, in: context, sinceBurst: sinceBurst, canvas: fireworks.canvas)
            drawSparks(fireworks.sparks[index], in: context, at: time, shadings: shadings)
        }
    }

    /// The shell climbing: a 5 pt head in its first colour with a 2.5 pt round-capped trail over
    /// its last 0.08 s at 55%. Nothing before launch or after the burst.
    private static func drawShell(
        _ shell: FireworkShell, in context: GraphicsContext, at time: TimeInterval, canvas: CGSize,
        shading: GraphicsContext.Shading
    ) {
        let physics = ConfirmFireworksPhysics.self
        guard let head = physics.shellPosition(of: shell, at: time, canvas: canvas) else { return }
        let tailTime = max(shell.launch, time - physics.shellTrail)
        let tail = physics.shellPosition(of: shell, at: tailTime, canvas: canvas) ?? head
        var trail = Path()
        trail.move(to: tail)
        trail.addLine(to: head)
        var trailContext = context
        trailContext.opacity = shellTrailOpacity
        trailContext.stroke(trail, with: shading, style: StrokeStyle(lineWidth: shellTrailWidth, lineCap: .round))
        let headBounds = CGRect(
            x: head.x - shellHeadDiameter / 2, y: head.y - shellHeadDiameter / 2,
            width: shellHeadDiameter, height: shellHeadDiameter
        )
        context.fill(Path(ellipseIn: headBounds), with: shading)
    }

    /// The burst flash: a radial gradient in the first colour, 40 → 240 pt and 0.35 → 0 over 0.35 s.
    private static func drawFlash(
        of shell: FireworkShell, in context: GraphicsContext, sinceBurst: TimeInterval, canvas: CGSize
    ) {
        guard let flash = ConfirmFireworksPhysics.flash(sinceBurst: sinceBurst) else { return }
        let apex = ConfirmFireworksPhysics.apexPoint(of: shell, canvas: canvas)
        let bounds = CGRect(
            x: apex.x - flash.radius, y: apex.y - flash.radius, width: flash.radius * 2, height: flash.radius * 2
        )
        let color = Color(shell.colorNames[0])
        context.fill(
            Path(ellipseIn: bounds),
            with: .radialGradient(
                Gradient(colors: [color.opacity(flash.alpha), color.opacity(0)]),
                center: apex, startRadius: 0, endRadius: flash.radius
            )
        )
    }

    /// Each live spark as a 2.4 pt round-capped stroke from where it was 0.07 s earlier, fading on
    /// the power curve.
    private static func drawSparks(
        _ sparks: [ConfettiPiece], in context: GraphicsContext, at time: TimeInterval,
        shadings: [String: GraphicsContext.Shading]
    ) {
        let physics = ConfirmFireworksPhysics.self
        for spark in sparks {
            guard let head = ConfettiPhysics.state(
                of: spark, at: time, gravity: physics.sparkGravity, drag: physics.sparkDrag
            ) else { continue }
            let tailTime = max(spark.delay, time - physics.sparkTrail)
            let tail = ConfettiPhysics.state(
                of: spark, at: tailTime, gravity: physics.sparkGravity, drag: physics.sparkDrag
            )?.position ?? head.position
            var streak = Path()
            streak.move(to: tail)
            streak.addLine(to: head.position)
            var sparkContext = context
            sparkContext.opacity = physics.sparkOpacity(life: spark.lifetime, sinceBurst: time - spark.delay)
            sparkContext.stroke(
                streak, with: shadings[spark.colorName] ?? .color(Color(spark.colorName)),
                style: StrokeStyle(lineWidth: sparkWidth, lineCap: .round)
            )
        }
    }
}
