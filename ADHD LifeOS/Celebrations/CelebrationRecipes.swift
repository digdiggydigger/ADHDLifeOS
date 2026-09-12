//
//  CelebrationRecipes.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-3`: what the two NEW families launch — the mini confetti pop E chose at F6
//  ("12 to 20 pieces from the tap point, the Confirm engine at a tenth of the size") and the still
//  scatter that replaces motion under Reduce Motion (#7).
//
//  Every colour is one of the Confirm celebration's seven asset tokens (CLAUDE.md §4), and every
//  piece is seeded from the burst's ordinal, so a burst replays identically and the next one is
//  different paper — the Confirm's rule, unchanged.
//
//  **Nothing requests these yet.** The nine pop sites are `F-CTACelebrations-4`, where E picks the
//  look by LOOKING at a render on a real `TaskRow` first; the four milestones are `-5`. The maths
//  is settled here so that render has something to show.
//

import CoreGraphics
import Foundation

enum CelebrationRecipes {
    /// E's F6, verbatim: "12 to 20 pieces".
    static let popCount = 12...20
    /// A still pop cannot travel, so it arrives already scattered — within this far of the tap.
    static let stillPopSpread: CGFloat = 48
    /// E's #7 for a reduced milestone: 120 pieces at rest across the canvas, the rain's count.
    static let stillFieldCount = 120

    /// The in-place pop: pieces thrown radially from the point that was tapped, gone within a
    /// second. The Confirm's physics at a tenth of the scale — same engine, same tokens.
    static func pop(at origin: CGPoint, ordinal: Int) -> [ConfettiPiece] {
        var random = ConfettiRandom(seed: seed(for: ordinal))
        let count = popCount.lowerBound
            + Int(random.uniform(0, Double(popCount.count)).rounded(.down))
        return (0..<min(count, popCount.upperBound)).map { index in
            // Radial, with each piece's own angle rather than an even fan: a fan reads as a
            // mechanism, a scatter reads as a pop.
            let radians = random.uniform(0, .pi * 2)
            let speed = random.uniform(250, 450)
            return piece(
                index: index,
                origin: origin,
                velocity: CGVector(dx: cos(radians) * speed, dy: sin(radians) * speed),
                lifetime: random.uniform(0.7, 1.0),
                using: &random
            )
        }
    }

    /// The reduced pop (#7): the same count, already scattered, at rest. §7.2's opening-pose rule —
    /// the first frame has the final geometry and only opacity travels.
    static func stillPop(at origin: CGPoint, ordinal: Int) -> [ConfettiPiece] {
        var random = ConfettiRandom(seed: seed(for: ordinal))
        let count = pop(at: origin, ordinal: ordinal).count
        return (0..<count).map { index in
            let radians = random.uniform(0, .pi * 2)
            let distance = stillPopSpread * CGFloat(random.unit().squareRoot())
            return piece(
                index: index,
                origin: CGPoint(
                    x: origin.x + cos(radians) * distance, y: origin.y + sin(radians) * distance
                ),
                velocity: .zero,
                lifetime: 0,
                using: &random
            )
        }
    }

    /// The reduced milestone (#7): a still confetti field across the whole canvas, which fades in
    /// and out over the celebration's own length rather than falling.
    static func stillField(canvas: CGSize, ordinal: Int) -> [ConfettiPiece] {
        var random = ConfettiRandom(seed: seed(for: ordinal) &+ 1)
        return (0..<stillFieldCount).map { index in
            piece(
                index: index,
                origin: CGPoint(
                    x: random.uniform(0, Double(canvas.width)),
                    y: random.uniform(0, Double(canvas.height))
                ),
                velocity: .zero,
                lifetime: 0,
                using: &random
            )
        }
    }

    /// The Confirm's look, drawn in the Confirm's order so a seed always means the same paper.
    private static func piece(
        index: Int,
        origin: CGPoint,
        velocity: CGVector,
        lifetime: TimeInterval,
        using random: inout ConfettiRandom
    ) -> ConfettiPiece {
        let colorName = ConfettiRecipe.palette[index % ConfettiRecipe.palette.count]
        let shape: ConfettiPiece.Shape
        let size: CGSize
        if random.unit() < 0.75 {
            shape = .rectangle
            size = CGSize(width: random.uniform(7, 10), height: random.uniform(4, 6))
        } else {
            shape = .circle
            size = CGSize(width: 6, height: 6)
        }
        return ConfettiPiece(
            origin: origin,
            velocity: velocity,
            delay: 0,
            lifetime: lifetime,
            size: size,
            shape: shape,
            colorName: colorName,
            spinStart: random.uniform(0, .pi * 2),
            spinRate: random.uniform(-9, 9),
            tumbleRate: random.uniform(4, 11),
            tumblePhase: random.uniform(0, .pi * 2),
            flutterAmplitude: random.uniform(6, 18),
            flutterRate: random.uniform(3, 6),
            flutterPhase: random.uniform(0, .pi * 2)
        )
    }

    /// Odd seeds, so a pop and the Confirm rain of the same ordinal never draw the same paper.
    private static func seed(for ordinal: Int) -> UInt64 {
        UInt64(truncatingIfNeeded: ordinal) &* 2_654_435_761
    }
}

/// The still model: a piece that never moves, and an envelope that is the only thing that does.
///
/// **§7.2's opening-pose rule lives here.** Under Reduce Motion the FIRST frame already has its
/// final geometry — position, angle, scale — and only opacity travels. A reduced path that opens
/// on the pre-animation pose and then snaps is the bug, not the fix.
enum CelebrationStillField {
    static let fadeIn: TimeInterval = 0.3
    static let fadeOut: TimeInterval = 0.7

    /// Where `piece` is and how it looks `time` into a celebration `length` seconds long, or `nil`
    /// outside it. §5's ban on plain easing does not reach here: a Reduce Motion opacity fade is
    /// the exception the section itself carries.
    static func state(
        of piece: ConfettiPiece, at time: TimeInterval, length: TimeInterval
    ) -> ConfettiPieceState? {
        guard time >= 0, time <= length else { return nil }
        return ConfettiPieceState(
            position: piece.origin,
            rotation: piece.spinStart,
            tumbleScale: 1,
            opacity: envelope(at: time, length: length)
        )
    }

    /// In over `fadeIn`, hold, out over the last `fadeOut`.
    static func envelope(at time: TimeInterval, length: TimeInterval) -> Double {
        guard time >= 0, time <= length else { return 0 }
        if time < fadeIn { return time / fadeIn }
        let leaving = length - fadeOut
        if time <= leaving { return 1 }
        return max(0, (length - time) / fadeOut)
    }
}
