//
//  ConfirmFireworksPhysics.swift
//  ADHD LifeOS
//
//  F-ConfirmCelebration-2's model: where a shell and its sparks are at any instant.
//

import CoreGraphics
import Foundation

struct FireworkFlash: Equatable {
    var radius: CGFloat
    var alpha: Double
}

struct ConfirmFireworks {
    let shells: [FireworkShell]
    let sparks: [[ConfettiPiece]]

    init(canvas: CGSize) {
        shells = []
        sparks = []
    }
}

enum ConfirmFireworksPhysics {
    static func riseDuration(of shell: FireworkShell) -> TimeInterval { 0 }
    static func burstTime(of shell: FireworkShell) -> TimeInterval { 0 }
    static func launchPoint(of shell: FireworkShell, canvas: CGSize) -> CGPoint { .zero }
    static func apexPoint(of shell: FireworkShell, canvas: CGSize) -> CGPoint { .zero }
    static func shellPosition(of shell: FireworkShell, at time: TimeInterval, canvas: CGSize) -> CGPoint? { nil }
    static func sparks(of shell: FireworkShell, index: Int, canvas: CGSize) -> [ConfettiPiece] { [] }
    static func sparkOpacity(life: TimeInterval, sinceBurst: TimeInterval) -> Double { 0 }
    static func flash(sinceBurst: TimeInterval) -> FireworkFlash? { nil }
}
