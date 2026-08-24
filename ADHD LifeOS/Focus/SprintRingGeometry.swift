//
//  SprintRingGeometry.swift
//  ADHD LifeOS
//
//  The polar placement maths behind S4's sprint ring (Concept C): where a checkpoint dot sits on
//  the ring's stroke centreline. This is the linear track's `dotOffset` arithmetic bent around a
//  dial — split out, like `FocusCheckpointDotState` beside it, so the placement is unit-tested
//  rather than re-derived inline in the view.
//

import CoreGraphics
import Foundation

enum SprintRingGeometry {
    /// The checkpoint's share of the sprint, clamped into 0...1. A zero-duration sprint has no
    /// meaningful positions, so everything parks at the start rather than trapping — the same
    /// guard the linear track's `dotOffset` carried.
    static func fraction(checkpoint: Int, durationSeconds: Int) -> Double {
        guard durationSeconds > 0 else { return 0 }
        return min(1, max(0, Double(checkpoint) / Double(durationSeconds)))
    }

    /// Centre of a checkpoint dot in the ring's own size×size coordinate space, on the stroke
    /// centreline (radius size/2). Twelve o'clock is fraction 0 and the dial runs clockwise —
    /// matching `ClosureRing`'s −90° rotation of SwiftUI's three-o'clock trim start.
    static func dotCenter(checkpoint: Int, durationSeconds: Int, size: CGFloat) -> CGPoint {
        let radius = size / 2
        let angle = fraction(checkpoint: checkpoint, durationSeconds: durationSeconds) * 2 * .pi - .pi / 2
        return CGPoint(
            x: radius + radius * CGFloat(cos(angle)),
            y: radius + radius * CGFloat(sin(angle))
        )
    }
}
