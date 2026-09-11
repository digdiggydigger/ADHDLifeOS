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
        []
    }

    /// Drifts down across the whole width from just above the top edge.
    static func rain(count: Int, canvas: CGSize, seed: UInt64) -> [ConfettiPiece] {
        []
    }

    /// Fired up and inward from both bottom corners, alternating left and right.
    static func cannons(count: Int, canvas: CGSize, seed: UInt64) -> [ConfettiPiece] {
        []
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
        0
    }

    /// Overlapping Confirms share ONE glow at the strongest envelope, rather than stacking three
    /// washes of 0.32 into something much heavier than anything E saw.
    static func strongestEnvelope(of bursts: [ConfirmCelebrationBurst], at date: Date) -> Double {
        0
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
    /// The last rain piece can launch at 0.6 s and live 3.6 s.
    static let everyConfirmLength: TimeInterval = 4.2

    static func adding(
        _ burst: ConfirmCelebrationBurst, to bursts: [ConfirmCelebrationBurst], now: Date
    ) -> [ConfirmCelebrationBurst] {
        bursts
    }

    static func pruned(_ bursts: [ConfirmCelebrationBurst], now: Date) -> [ConfirmCelebrationBurst] {
        bursts
    }

    /// When the soonest-ending live burst ends, or `nil` with nothing live.
    static func nextExpiry(of bursts: [ConfirmCelebrationBurst]) -> Date? {
        nil
    }
}
