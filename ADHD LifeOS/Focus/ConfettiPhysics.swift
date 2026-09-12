//
//  ConfettiPhysics.swift
//  ADHD LifeOS
//
//  F-ConfirmCelebration-1's engine: one piece of confetti, and where it is at any instant. Every
//  number is the prototype's that E chose from by video, recorded in
//  `handoff/SESSION-OPENER-confirm-celebration-design.md` ("The numbers").
//
//  **A pure function of time, never accumulated frame to frame.** A piece's whole flight is fixed
//  at launch, and its state at `t` is computed in closed form, so the same instant always draws the
//  same frame: tests hold the maths, render probes inject any `t`, and a dropped frame on a busy
//  phone costs nothing but that frame.
//

import CoreGraphics
import Foundation

/// One piece's whole flight, fixed at launch.
struct ConfettiPiece: Equatable {
    enum Shape: Equatable {
        case rectangle
        case circle
    }

    var origin: CGPoint
    /// Points per second at launch; y grows DOWNWARD, so a negative `dy` is thrown upward.
    var velocity: CGVector
    /// Seconds after the Confirm before the piece exists.
    var delay: TimeInterval
    /// Seconds the piece exists for, counted from its own launch.
    var lifetime: TimeInterval
    var size: CGSize
    var shape: Shape
    /// An asset-catalog token name (CLAUDE.md §4). Never a hue.
    var colorName: String
    var spinStart: Double
    /// Radians per second.
    var spinRate: Double
    var tumbleRate: Double
    var tumblePhase: Double
    /// Points of sideways sway at full strength.
    var flutterAmplitude: Double
    var flutterRate: Double
    var flutterPhase: Double
}

/// What one piece looks like at one instant.
struct ConfettiPieceState: Equatable {
    var position: CGPoint
    /// Radians.
    var rotation: Double
    /// The horizontal squash that reads as a piece turning over; floored, never zero.
    var tumbleScale: Double
    var opacity: Double
}

enum ConfettiPhysics {
    /// Points per second squared, downward.
    static let gravity: Double = 520
    /// Linear drag, per second: horizontal travel can never exceed `velocity.dx / drag`.
    static let drag: Double = 2.2
    /// A piece fades out over the last `fadeOut` seconds of its life, and is fully opaque before.
    static let fadeOut: TimeInterval = 0.7
    /// Sway eases in over the first `flutterRampIn` seconds, so a piece leaves its origin cleanly
    /// instead of jumping sideways on its first frame.
    static let flutterRampIn: TimeInterval = 0.6
    /// A piece edge-on would vanish mid-flight; the prototype floors the squash here.
    static let minimumTumbleScale: Double = 0.15

    /// Where `piece` is and how it looks `time` seconds after the Confirm, or `nil` before its
    /// delay has passed and after its life has ended.
    ///
    /// Drag-damped ballistic motion, in closed form (y grows downward):
    ///
    ///     x(t) = x₀ + vₓ/k · (1 − e^(−k·t)) + flutter(t)
    ///     y(t) = y₀ + (v_y − g/k)/k · (1 − e^(−k·t)) + (g/k)·t
    static func state(of piece: ConfettiPiece, at time: TimeInterval) -> ConfettiPieceState? {
        state(of: piece, at: time, gravity: gravity, drag: drag)
    }

    /// The same flight under another gravity and drag — a firework spark is lighter than paper
    /// (F-ConfirmCelebration-2: 150 / 2.4). The confetti's own `state(of:at:)` is this at the
    /// defaults above.
    static func state(
        of piece: ConfettiPiece, at time: TimeInterval, gravity: Double, drag: Double
    ) -> ConfettiPieceState? {
        let flight = time - piece.delay
        guard flight >= 0, flight <= piece.lifetime else { return nil }
        let damping = 1 - exp(-drag * flight)
        let terminal = gravity / drag
        let flutter = piece.flutterAmplitude
            * sin(piece.flutterRate * flight + piece.flutterPhase)
            * min(1, flight / flutterRampIn)
        let across = Double(piece.origin.x) + Double(piece.velocity.dx) / drag * damping + flutter
        let down = Double(piece.origin.y) + (Double(piece.velocity.dy) - terminal) / drag * damping + terminal * flight
        return ConfettiPieceState(
            position: CGPoint(x: across, y: down),
            rotation: piece.spinStart + piece.spinRate * flight,
            tumbleScale: max(minimumTumbleScale, abs(cos(piece.tumbleRate * flight + piece.tumblePhase))),
            opacity: min(1, max(0, (piece.lifetime - flight) / fadeOut))
        )
    }
}

/// SplitMix64: a small, fast, fully deterministic generator. Deterministic is the point — the same
/// confirmation must replay the same pieces (design record, R5), which no system generator allows.
struct ConfettiRandom {
    private(set) var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }

    /// Uniform in `0..<1`, from the top 53 bits.
    mutating func unit() -> Double {
        Double(next() >> 11) / Double(UInt64(1) << 53)
    }

    mutating func uniform(_ low: Double, _ high: Double) -> Double {
        low + (high - low) * unit()
    }
}
