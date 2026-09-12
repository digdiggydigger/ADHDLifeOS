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
    /// **How much bigger the pop is than the paper E first approved — E's call, 2026-09-12, made
    /// by LOOKING**, the way the pop's family was chosen in `F-CTACelebrations-4`.
    ///
    /// E saw the shipped pop on their own phone: *"I think that the scaling of the 'pop' needs to
    /// be increased slightly"*, then *"bigger spread too, not just bigger pieces"* and *"maybe
    /// slightly increase the amount of confetti pieces"*. All three ride this ONE constant, and E
    /// picked variant C (1.6×) from A (as shipped) / B (1.3×) / C / D (2.0×) rendered in situ on a
    /// real `TaskRow`. Measured at the pop's most legible instant: 18 → 29 pieces, 2,087 → 6,100
    /// painted pixels, and a furthest piece at 400 ms of 140 → 208 pt.
    ///
    /// **Do not "tune" it back down** — it is not a guess at what reads well, it is the value E
    /// approved by sight. `testThePopScaleIsTheValueEChoseByLooking` pins it and says why, the
    /// `FocusCompletionStackLayout.peekStep` precedent.
    ///
    /// **It governs the POP alone.** The milestone's 120-piece still field is a different moment at
    /// a different size and keeps the Confirm's own paper — the shared `piece(...)` builder would
    /// otherwise have carried this into it silently, which is why a test asserts it does not.
    static let popScale: CGFloat = 1.6

    /// E's F6 was "12 to 20 pieces"; scaled by `popScale` at E's device pass.
    static let popCount = 19...32
    /// A still pop cannot travel, so it arrives already scattered — within this far of the tap.
    /// Scales with the pop, so E's bigger pop and its Reduce Motion counterpart cannot drift apart.
    static let stillPopSpread: CGFloat = 48 * popScale
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
            // E's "bigger spread too": the throw scales with the paper. `ConfettiPhysics` gives
            // a piece linear drag of 2.2/s, so its travel can never exceed `velocity / drag` —
            // scaling the speed scales that ceiling with it.
            let speed = random.uniform(250, 450) * Double(popScale)
            return piece(
                index: index,
                origin: origin,
                velocity: CGVector(dx: cos(radians) * speed, dy: sin(radians) * speed),
                lifetime: random.uniform(0.7, 1.0),
                sizeScale: popScale,
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
                sizeScale: popScale,
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
    /// `sizeScale` defaults to 1 so the MILESTONE's still field keeps the Confirm's own paper —
    /// only the two pop paths pass `popScale`. A shared builder that scaled everything would have
    /// changed a celebration E never asked to change.
    private static func piece(
        index: Int,
        origin: CGPoint,
        velocity: CGVector,
        lifetime: TimeInterval,
        sizeScale: CGFloat = 1,
        using random: inout ConfettiRandom
    ) -> ConfettiPiece {
        let colorName = ConfettiRecipe.palette[index % ConfettiRecipe.palette.count]
        let shape: ConfettiPiece.Shape
        let size: CGSize
        if random.unit() < 0.75 {
            shape = .rectangle
            size = CGSize(
                width: random.uniform(7, 10) * Double(sizeScale),
                height: random.uniform(4, 6) * Double(sizeScale)
            )
        } else {
            shape = .circle
            size = CGSize(width: 6 * sizeScale, height: 6 * sizeScale)
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
