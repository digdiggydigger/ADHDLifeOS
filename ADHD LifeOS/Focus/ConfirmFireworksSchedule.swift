//
//  ConfirmFireworksSchedule.swift
//  ADHD LifeOS
//
//  F-ConfirmCelebration-2: WHICH fireworks a stack-clearing Confirm fires, where and when.
//

import CoreGraphics
import Foundation

/// One shell on the schedule: when it launches, where it bursts, what it bursts into.
struct FireworkShell: Equatable {
    enum Burst: Equatable {
        case single
        case twoTone
        case ringInRing
    }

    enum SizeClass: Equatable {
        case big
        case medium
        case small

        var sparkCount: Int { 0 }
        var sparkSpeed: Double { 0 }
        var sparkLife: TimeInterval { 0 }
    }

    var launch: TimeInterval
    var apex: CGPoint
    var burst: Burst
    var colorNames: [String]
    var size: SizeClass
}

enum ConfirmFireworksSchedule {
    static let palette: [String] = []
    static let shells: [FireworkShell] = []
    static var lastSparkTime: TimeInterval { 0 }
}
