//
//  ConfirmCelebrationRecipe.swift
//  ADHD LifeOS
//
//  F-ConfirmCelebration-1: WHAT a Confirm launches and for how long — every Confirm's confetti, the
//  done-green glow, and the live bursts when Confirms come quickly. All pure; the numbers are the
//  prototype's E chose from, recorded in `handoff/SESSION-OPENER-confirm-celebration-design.md`.
//

import CoreGraphics
import Foundation

/// Every Confirm's confetti (E's decision 5, "B but also C"): rain from the top AND both bottom
/// corners' cannons, together, in the seven token colours. The stack-clearing Confirm's extra is
/// fireworks (block 2), not more confetti — the confetti is identical on both.
enum ConfettiRecipe {
    /// The record's seven tokens, cycled in this order. `AreaSlateVivid` is left out as grey, and
    /// `StateRisk` because it means risk.
    static let palette = [
        "AreaWorkVivid", "AreaHealthVivid", "AreaGrowthVivid", "AreaHobbyVivid",
        "AreaOrangeVivid", "StateGoVivid", "StateWarnVivid"
    ]
    static let rainCount = 120
    static let cannonCount = 100

    /// Every Confirm's 220 pieces for a canvas, rain first. Seeded from the confirmation's ordinal
    /// (R5), so the same Confirm replays identically and the next one is different.
    static func everyConfirm(canvas: CGSize, ordinal: Int) -> [ConfettiPiece] {
        // Odd seeds for the rain and even for the cannons, so ordinal 1 draws exactly the
        // prototype E chose from (which seeded them 1 and 2).
        let base = UInt64(truncatingIfNeeded: ordinal) &* 2
        return rain(count: rainCount, canvas: canvas, seed: base &- 1)
            + cannons(count: cannonCount, canvas: canvas, seed: base)
    }

    /// Drifts down across the whole width from just above the top edge.
    static func rain(count: Int, canvas: CGSize, seed: UInt64) -> [ConfettiPiece] {
        var random = ConfettiRandom(seed: seed)
        return (0..<count).map { index in
            let look = ConfettiLook(index: index, using: &random)
            let origin = CGPoint(
                x: random.uniform(-10, Double(canvas.width) + 10), y: random.uniform(-80, -10)
            )
            let velocity = CGVector(dx: random.uniform(-60, 60), dy: random.uniform(420, 720))
            let delay = random.uniform(0, 0.6)
            return look.piece(origin: origin, velocity: velocity, delay: delay, lifetime: 3.0...3.6, using: &random)
        }
    }

    /// Fired up and inward from both bottom corners, alternating left and right.
    static func cannons(count: Int, canvas: CGSize, seed: UInt64) -> [ConfettiPiece] {
        var random = ConfettiRandom(seed: seed)
        return (0..<count).map { index in
            let look = ConfettiLook(index: index, using: &random)
            let fromLeft = index.isMultiple(of: 2)
            let origin = CGPoint(x: fromLeft ? -4 : canvas.width + 4, y: canvas.height * 0.86)
            // 52°–78° above the horizontal, mirrored for the right corner so both aim inward.
            let elevation = random.uniform(-78, -52)
            let radians = (fromLeft ? elevation : -180 - elevation) * .pi / 180
            let speed = random.uniform(1100, 1900)
            let velocity = CGVector(dx: cos(radians) * speed, dy: sin(radians) * speed)
            let delay = random.uniform(0, 0.12)
            return look.piece(origin: origin, velocity: velocity, delay: delay, lifetime: 2.8...3.5, using: &random)
        }
    }
}

/// A piece's colour, shape and size, before it is given a flight.
///
/// **Every value is drawn from the generator in a fixed order** — shape, size, then (in the
/// source) origin, velocity and delay, then spin, tumble, flutter and life — which is the
/// prototype's order, so a seed always means the same pieces and ordinal 1 is what E saw.
private struct ConfettiLook {
    let shape: ConfettiPiece.Shape
    let size: CGSize
    let colorName: String

    /// Colour cycles by index; three rectangles to every circle.
    init(index: Int, using random: inout ConfettiRandom) {
        colorName = ConfettiRecipe.palette[index % ConfettiRecipe.palette.count]
        if random.unit() < 0.75 {
            shape = .rectangle
            let width = random.uniform(7, 10)
            size = CGSize(width: width, height: random.uniform(4, 6))
        } else {
            shape = .circle
            size = CGSize(width: 6, height: 6)
        }
    }

    /// The spin, tumble, flutter and life every source shares, drawn last.
    func piece(
        origin: CGPoint,
        velocity: CGVector,
        delay: TimeInterval,
        lifetime: ClosedRange<TimeInterval>,
        using random: inout ConfettiRandom
    ) -> ConfettiPiece {
        let spinStart = random.uniform(0, .pi * 2)
        let spinRate = random.uniform(-9, 9)
        let tumbleRate = random.uniform(4, 11)
        let tumblePhase = random.uniform(0, .pi * 2)
        let flutterAmplitude = random.uniform(6, 18)
        let flutterRate = random.uniform(3, 6)
        let flutterPhase = random.uniform(0, .pi * 2)
        let life = random.uniform(lifetime.lowerBound, lifetime.upperBound)
        return ConfettiPiece(
            origin: origin, velocity: velocity, delay: delay, lifetime: life,
            size: size, shape: shape, colorName: colorName,
            spinStart: spinStart, spinRate: spinRate, tumbleRate: tumbleRate, tumblePhase: tumblePhase,
            flutterAmplitude: flutterAmplitude, flutterRate: flutterRate, flutterPhase: flutterPhase
        )
    }
}

/// The done-green wash that swells from the bottom edge on every Confirm, in both appearances (R6).
enum ConfirmCelebrationGlow {
    static let colorName = "StateGo"
    static let peakOpacity: Double = 0.32
    static let radius: CGFloat = 760
    static let fadeIn: TimeInterval = 0.3
    static let holdUntil: TimeInterval = 0.9
    static let goneBy: TimeInterval = 2.4

    /// How strongly the glow shows `time` seconds after its Confirm, 0…1.
    static func envelope(at time: TimeInterval) -> Double {
        if time <= 0 { return 0 }
        if time < fadeIn { return time / fadeIn }
        if time <= holdUntil { return 1 }
        return max(0, 1 - (time - holdUntil) / (goneBy - holdUntil))
    }

    /// Overlapping Confirms share ONE glow at the strongest envelope, rather than stacking three
    /// washes of 0.32 into something much heavier than anything E saw.
    static func strongestEnvelope(of bursts: [ConfirmCelebrationBurst], at date: Date) -> Double {
        bursts.map { envelope(at: ConfirmCelebrationQueue.choreographyTime(of: $0, at: date)) }.max() ?? 0
    }
}

/// One Confirm's celebration on screen.
struct ConfirmCelebrationBurst: Equatable, Identifiable {
    let ordinal: Int
    let clearedStack: Bool
    let start: Date

    var id: Int { ordinal }

    init(ordinal: Int, clearedStack: Bool, start: Date) {
        self.ordinal = ordinal
        self.clearedStack = clearedStack
        self.start = start
    }

    init(confirmation: FocusConfirmation, start: Date) {
        self.init(ordinal: confirmation.ordinal, clearedStack: confirmation.clearedStack, start: start)
    }
}

/// The live bursts (E's approved R1): quick Confirms OVERLAP rather than restart, at most
/// `liveCap` at once with the oldest dropped, and every burst is removed the moment it ends — so
/// the layer stops drawing, and stops asking for frames, when nothing is left in the air.
enum ConfirmCelebrationQueue {
    static let liveCap = 3
    /// The prototype's choreography E chose from: the last rain piece can launch at 0.6 s and live
    /// 3.6 s. Every number in the physics, the recipe and the glow is on THIS clock.
    static let choreographyLength: TimeInterval = 4.2
    /// **E, after watching block 1 (2026-09-11): "extend the animation length by 1.2 seconds".**
    /// Added by STRETCHING the choreography evenly rather than by tacking on a tail, so every piece,
    /// path and beat E approved is kept, with no extra drawing. It simply plays at `pace` (~78%).
    /// A tail at the same speed would have either drawn off-screen or thinned the confetti.
    static let extraLength: TimeInterval = 1.2
    /// How long a celebration is on screen.
    static var everyConfirmLength: TimeInterval { choreographyLength + extraLength }
    /// How fast the choreography plays against the wall clock.
    static var pace: Double { choreographyLength / everyConfirmLength }

    /// Where `burst` is in its choreography at `date`: wall-clock seconds since the Confirm, at `pace`.
    static func choreographyTime(of burst: ConfirmCelebrationBurst, at date: Date) -> TimeInterval {
        date.timeIntervalSince(burst.start) * pace
    }

    /// How long a burst stays in the air.
    static func length(of burst: ConfirmCelebrationBurst) -> TimeInterval {
        everyConfirmLength
    }

    static func adding(
        _ burst: ConfirmCelebrationBurst, to bursts: [ConfirmCelebrationBurst], now: Date
    ) -> [ConfirmCelebrationBurst] {
        Array((pruned(bursts, now: now) + [burst]).suffix(liveCap))
    }

    /// Only the bursts still in the air at `now`. A burst ends exactly at its length.
    static func pruned(_ bursts: [ConfirmCelebrationBurst], now: Date) -> [ConfirmCelebrationBurst] {
        bursts.filter { now < end(of: $0) }
    }

    /// When the soonest-ending live burst ends, or `nil` with nothing live.
    static func nextExpiry(of bursts: [ConfirmCelebrationBurst]) -> Date? {
        bursts.map { end(of: $0) }.min()
    }

    private static func end(of burst: ConfirmCelebrationBurst) -> Date {
        burst.start.addingTimeInterval(length(of: burst))
    }
}
