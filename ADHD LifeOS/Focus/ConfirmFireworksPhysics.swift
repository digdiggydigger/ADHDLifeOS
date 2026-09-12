//
//  ConfirmFireworksPhysics.swift
//  ADHD LifeOS
//
//  F-ConfirmCelebration-2's model: where a shell and its sparks are at any instant. Like the
//  confetti, a pure function of time — nothing is accumulated frame to frame — so tests hold the
//  maths and render probes inject any `t`. The numbers are the prototype's E chose from,
//  recorded in `handoff/SESSION-OPENER-confirm-celebration-design.md` ("Fireworks").
//

import CoreGraphics
import Foundation

/// The burst flash at one instant: a radial gradient of this radius and peak alpha at the apex.
struct FireworkFlash: Equatable {
    var radius: CGFloat
    var alpha: Double
}

/// A stack-clearing Confirm's whole display for one canvas: the schedule and every shell's sparks,
/// built once per change to the live list, never per frame.
struct ConfirmFireworks {
    let canvas: CGSize
    let shells: [FireworkShell]
    /// One list per shell, in schedule order.
    let sparks: [[ConfettiPiece]]

    init(canvas: CGSize, schedule: [FireworkShell] = ConfirmFireworksSchedule.shells) {
        self.canvas = canvas
        shells = schedule
        sparks = schedule.enumerated().map { index, shell in
            ConfirmFireworksPhysics.sparks(of: shell, index: index, canvas: canvas)
        }
    }
}

enum ConfirmFireworksPhysics {
    /// Sparks are lighter than paper: the confetti model at these instead of 520 / 2.2.
    static let sparkGravity: Double = 150
    static let sparkDrag: Double = 2.4
    /// A shell launches from just right of its apex, near the bottom edge (fractions of the canvas).
    static let launchLead: CGFloat = 0.02
    static let launchHeight: CGFloat = 0.96
    /// The rise: 0.55 s plus a quarter-second for the full height of the screen.
    static let baseRise: TimeInterval = 0.55
    static let riseForFullHeight: TimeInterval = 0.25
    /// Ring-in-ring: the inner ring's speed against the outer's.
    static let innerRingSpeed: Double = 0.55
    static let sparkSize = CGSize(width: 2.4, height: 2.4)
    /// Opacity `(1 − τ/life)^sparkFadePower`.
    static let sparkFadePower: Double = 1.4
    static let flashDuration: TimeInterval = 0.35
    static let flashStartRadius: CGFloat = 40
    static let flashEndRadius: CGFloat = 240
    static let flashPeakAlpha: Double = 0.35
    /// A spark is drawn as a stroke from where it was this long ago; a shell, from this long ago.
    static let sparkTrail: TimeInterval = 0.07
    static let shellTrail: TimeInterval = 0.08

    // MARK: - The shell

    static func riseDuration(of shell: FireworkShell) -> TimeInterval {
        baseRise + riseForFullHeight * (1 - Double(shell.apex.y))
    }

    static func burstTime(of shell: FireworkShell) -> TimeInterval {
        shell.launch + riseDuration(of: shell)
    }

    static func launchPoint(of shell: FireworkShell, canvas: CGSize) -> CGPoint {
        CGPoint(x: (shell.apex.x + launchLead) * canvas.width, y: launchHeight * canvas.height)
    }

    static func apexPoint(of shell: FireworkShell, canvas: CGSize) -> CGPoint {
        CGPoint(x: shell.apex.x * canvas.width, y: shell.apex.y * canvas.height)
    }

    /// Where the shell is `time` seconds after the Confirm, or `nil` before it launches and after
    /// it bursts. Eased `1 − (1 − u)²`: fast off the ground, slowing to a hang at the apex.
    static func shellPosition(of shell: FireworkShell, at time: TimeInterval, canvas: CGSize) -> CGPoint? {
        let rise = riseDuration(of: shell)
        let flight = time - shell.launch
        guard flight >= 0, flight <= rise else { return nil }
        let progress = flight / rise
        let eased = 1 - (1 - progress) * (1 - progress)
        let start = launchPoint(of: shell, canvas: canvas)
        let apex = apexPoint(of: shell, canvas: canvas)
        return CGPoint(x: start.x + (apex.x - start.x) * eased, y: start.y + (apex.y - start.y) * eased)
    }

    // MARK: - The sparks

    /// The shell's sparks, each a 2.4 pt dot the confetti model flies from the apex at the burst:
    /// evenly stepped around the circle at the class speed × (0.8 + 0.2 × a per-spark hash); a
    /// two-tone shell alternates its colours; a ring-in-ring shell puts half its sparks in a
    /// slower inner ring in the second colour, offset by half a step.
    static func sparks(of shell: FireworkShell, index: Int, canvas: CGSize) -> [ConfettiPiece] {
        let count = shell.size.sparkCount
        let launch = SparkLaunch(
            origin: apexPoint(of: shell, canvas: canvas), delay: burstTime(of: shell), life: shell.size.sparkLife
        )
        let first = shell.colorNames[0]
        let second = shell.colorNames.count > 1 ? shell.colorNames[1] : first
        switch shell.burst {
        case .single, .twoTone:
            return (0..<count).map { spark in
                let color = shell.burst == .twoTone && !spark.isMultiple(of: 2) ? second : first
                return piece(
                    angle: 2 * .pi * Double(spark) / Double(count),
                    speed: shell.size.sparkSpeed * variation(shell: index, spark: spark),
                    colorName: color, launch: launch
                )
            }
        case .ringInRing:
            let half = count / 2
            let outer = (0..<half).map { spark in
                piece(
                    angle: 2 * .pi * Double(spark) / Double(half),
                    speed: shell.size.sparkSpeed * variation(shell: index, spark: spark),
                    colorName: first, launch: launch
                )
            }
            let inner = (0..<half).map { spark in
                piece(
                    angle: 2 * .pi * (Double(spark) + 0.5) / Double(half),
                    speed: shell.size.sparkSpeed * innerRingSpeed * variation(shell: index, spark: half + spark),
                    colorName: second, launch: launch
                )
            }
            return outer + inner
        }
    }

    /// `(1 − τ/life)^1.4` from the burst; nothing before it or after the life.
    static func sparkOpacity(life: TimeInterval, sinceBurst: TimeInterval) -> Double {
        guard sinceBurst >= 0, sinceBurst < life else { return 0 }
        return pow(1 - sinceBurst / life, sparkFadePower)
    }

    /// The flash at `sinceBurst` seconds after the burst, or `nil` outside its 0.35 s.
    static func flash(sinceBurst: TimeInterval) -> FireworkFlash? {
        guard sinceBurst >= 0, sinceBurst < flashDuration else { return nil }
        let progress = sinceBurst / flashDuration
        return FireworkFlash(
            radius: flashStartRadius + (flashEndRadius - flashStartRadius) * progress,
            alpha: flashPeakAlpha * (1 - progress)
        )
    }

    // MARK: - Helpers

    /// 0.8…1.0, deterministic per (shell, spark), so a display replays identically.
    private static func variation(shell: Int, spark: Int) -> Double {
        var random = ConfettiRandom(seed: UInt64(shell) &* 1_000_003 &+ UInt64(spark) &+ 1)
        return 0.8 + 0.2 * random.unit()
    }

    /// What every spark of one shell shares: the apex, the burst instant and the class life.
    private struct SparkLaunch {
        var origin: CGPoint
        var delay: TimeInterval
        var life: TimeInterval
    }

    private static func piece(angle: Double, speed: Double, colorName: String, launch: SparkLaunch) -> ConfettiPiece {
        ConfettiPiece(
            origin: launch.origin, velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
            delay: launch.delay, lifetime: launch.life, size: sparkSize, shape: .circle, colorName: colorName,
            spinStart: 0, spinRate: 0, tumbleRate: 0, tumblePhase: 0,
            flutterAmplitude: 0, flutterRate: 0, flutterPhase: 0
        )
    }
}
