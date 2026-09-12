//
//  ConfirmFireworksSchedule.swift
//  ADHD LifeOS
//
//  F-ConfirmCelebration-2: WHICH fireworks a stack-clearing Confirm fires, where and when. E asked
//  for fireworks on the stack-clearing burst (#6), then "more fireworks … and OTHER COLOURED
//  fireworks" (#7), and chose this 14-shell schedule by video at 85% dim (#8). Every row is the
//  prototype's, recorded in `handoff/SESSION-OPENER-confirm-celebration-design.md` ("Fireworks").
//
//  The schedule is FIXED, unlike the confetti: E chose these bursts in these places, so every
//  stack-clearing Confirm fires them. The confetti around them is still seeded per ordinal (R5),
//  so no two celebrations are identical.
//

import CoreGraphics
import Foundation

/// One shell on the schedule: when it launches, where it bursts, and what it bursts into.
struct FireworkShell: Equatable {
    enum Burst: Equatable {
        /// One ring in one colour.
        case single
        /// One ring, sparks alternating the two colours.
        case twoTone
        /// An outer ring in the first colour with a slower inner ring in the second.
        case ringInRing
    }

    /// How many sparks, how fast, and for how long. Every number is the record's.
    enum SizeClass: Equatable {
        case big
        case medium
        case small

        var sparkCount: Int {
            switch self {
            case .big: return 72
            case .medium: return 56
            case .small: return 40
            }
        }

        /// Points per second at the burst, before the per-spark variation.
        var sparkSpeed: Double {
            switch self {
            case .big: return 400
            case .medium: return 310
            case .small: return 220
            }
        }

        /// Seconds a spark lives after the burst.
        var sparkLife: TimeInterval {
            switch self {
            case .big: return 1.45
            case .medium: return 1.3
            case .small: return 1.1
            }
        }
    }

    /// Seconds after the Confirm, on the choreography clock.
    var launch: TimeInterval
    /// Where it bursts, as fractions of the canvas width and height.
    var apex: CGPoint
    var burst: Burst
    /// Asset-catalog token names (CLAUDE.md §4): one for a single shell, two otherwise.
    var colorNames: [String]
    var size: SizeClass
}

enum ConfirmFireworksSchedule {
    /// The confetti's seven tokens plus two more for "OTHER COLOURED" (#7). `AreaSlateVivid` is
    /// left out as grey, and `StateRisk` because it means risk.
    static let palette = ConfettiRecipe.palette + ["AreaAdminVivid", "AreaRedVivid"]

    /// 14 shells over 2.6 s; the last two are the finale.
    static let shells: [FireworkShell] = [
        FireworkShell(
            launch: 0.05, apex: CGPoint(x: 0.28, y: 0.30), burst: .single,
            colorNames: ["StateWarnVivid"], size: .big
        ),
        FireworkShell(
            launch: 0.30, apex: CGPoint(x: 0.72, y: 0.22), burst: .twoTone,
            colorNames: ["AreaGrowthVivid", "AreaHealthVivid"], size: .big
        ),
        FireworkShell(
            launch: 0.55, apex: CGPoint(x: 0.50, y: 0.40), burst: .ringInRing,
            colorNames: ["AreaHobbyVivid", "AreaAdminVivid"], size: .big
        ),
        FireworkShell(
            launch: 0.80, apex: CGPoint(x: 0.18, y: 0.18), burst: .single,
            colorNames: ["AreaWorkVivid"], size: .medium
        ),
        FireworkShell(
            launch: 0.95, apex: CGPoint(x: 0.84, y: 0.36), burst: .twoTone,
            colorNames: ["StateGoVivid", "AreaAdminVivid"], size: .medium
        ),
        FireworkShell(
            launch: 1.20, apex: CGPoint(x: 0.40, y: 0.16), burst: .ringInRing,
            colorNames: ["AreaOrangeVivid", "AreaHealthVivid"], size: .big
        ),
        FireworkShell(
            launch: 1.40, apex: CGPoint(x: 0.64, y: 0.46), burst: .single,
            colorNames: ["AreaGrowthVivid"], size: .small
        ),
        FireworkShell(
            launch: 1.55, apex: CGPoint(x: 0.26, y: 0.50), burst: .twoTone,
            colorNames: ["AreaRedVivid", "StateWarnVivid"], size: .small
        ),
        FireworkShell(
            launch: 1.75, apex: CGPoint(x: 0.78, y: 0.14), burst: .single,
            colorNames: ["AreaHealthVivid"], size: .big
        ),
        FireworkShell(
            launch: 1.95, apex: CGPoint(x: 0.50, y: 0.28), burst: .twoTone,
            colorNames: ["AreaHobbyVivid", "AreaWorkVivid"], size: .big
        ),
        FireworkShell(
            launch: 2.20, apex: CGPoint(x: 0.15, y: 0.34), burst: .ringInRing,
            colorNames: ["StateGoVivid", "AreaGrowthVivid"], size: .medium
        ),
        FireworkShell(
            launch: 2.35, apex: CGPoint(x: 0.86, y: 0.26), burst: .single,
            colorNames: ["AreaAdminVivid"], size: .medium
        ),
        FireworkShell(
            launch: 2.55, apex: CGPoint(x: 0.36, y: 0.22), burst: .twoTone,
            colorNames: ["AreaOrangeVivid", "AreaGrowthVivid"], size: .big
        ),
        FireworkShell(
            launch: 2.60, apex: CGPoint(x: 0.66, y: 0.24), burst: .ringInRing,
            colorNames: ["StateWarnVivid", "AreaHobbyVivid"], size: .big
        )
    ]

    /// When the last spark dies, on the choreography clock: 4.79 s. Derived from the schedule
    /// rather than written down, so a changed shell cannot leave it stale. The dim's hold is
    /// measured back from here.
    static var lastSparkTime: TimeInterval {
        shells.map { ConfirmFireworksPhysics.burstTime(of: $0) + $0.size.sparkLife }.max() ?? 0
    }
}
