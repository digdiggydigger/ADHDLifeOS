//
//  ConfirmFireworksDrawing.swift
//  ADHD LifeOS
//
//  F-ConfirmCelebration-2: the Canvas operations for the fireworks, and the light-appearance dim.
//

import SwiftUI

enum ConfirmCelebrationDim {
    static let colorName = ""
    static let peakOpacity: Double = 0
    static var holdUntil: TimeInterval { 0 }
    static var goneBy: TimeInterval { 0 }

    static func envelope(at time: TimeInterval) -> Double { 0 }

    static func strongestEnvelope(of bursts: [ConfirmCelebrationBurst], at date: Date) -> Double { 0 }
}

enum ConfirmFireworksDrawing {
    static func draw(
        _ fireworks: ConfirmFireworks, in context: inout GraphicsContext, at time: TimeInterval,
        shadings: [String: GraphicsContext.Shading]
    ) {}
}
