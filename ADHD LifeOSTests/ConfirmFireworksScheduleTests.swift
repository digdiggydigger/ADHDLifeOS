//
//  ConfirmFireworksScheduleTests.swift
//  ADHD LifeOSTests
//
//  F-ConfirmCelebration-2: WHICH fireworks a stack-clearing Confirm fires, where and when. E chose
//  this exact schedule by video — "more fireworks … and OTHER COLOURED fireworks" (#7), then the
//  14-shell render at 85% dim (#8) — so these pin the table in
//  `handoff/SESSION-OPENER-confirm-celebration-design.md` ("Fireworks") row for row.
//

import UIKit
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class ConfirmFireworksScheduleTests: XCTestCase {

    private let shells = ConfirmFireworksSchedule.shells

    // MARK: - The table E chose from

    func testFourteenShellsLaunchOverTheRecordsTwoPointSixSeconds() {
        XCTAssertEqual(shells.count, 14, "E asked for MORE fireworks; the record settled on 14.")
        XCTAssertEqual(
            shells.map(\.launch),
            [0.05, 0.30, 0.55, 0.80, 0.95, 1.20, 1.40, 1.55, 1.75, 1.95, 2.20, 2.35, 2.55, 2.60],
            "The shells do not launch on the record's schedule."
        )
    }

    func testEveryShellBurstsWhereTheRecordPutsIt() {
        let expected: [(x: CGFloat, y: CGFloat)] = [
            (0.28, 0.30), (0.72, 0.22), (0.50, 0.40), (0.18, 0.18), (0.84, 0.36), (0.40, 0.16), (0.64, 0.46),
            (0.26, 0.50), (0.78, 0.14), (0.50, 0.28), (0.15, 0.34), (0.86, 0.26), (0.36, 0.22), (0.66, 0.24)
        ]
        XCTAssertEqual(shells.count, expected.count, "The schedule is not the record's 14 shells.")
        for (shell, apex) in zip(shells, expected) {
            XCTAssertEqual(shell.apex.x, apex.x, accuracy: 1e-9, "The shell at \(shell.launch) s bursts at the wrong x.")
            XCTAssertEqual(shell.apex.y, apex.y, accuracy: 1e-9, "The shell at \(shell.launch) s bursts at the wrong y.")
        }
    }

    func testTheBurstKindsAndSizesAreTheRecords() {
        typealias Burst = FireworkShell.Burst
        typealias Size = FireworkShell.SizeClass
        XCTAssertEqual(shells.map(\.burst), [
            Burst.single, .twoTone, .ringInRing, .single, .twoTone, .ringInRing, .single,
            .twoTone, .single, .twoTone, .ringInRing, .single, .twoTone, .ringInRing
        ], "The burst kinds are not the record's.")
        XCTAssertEqual(shells.map(\.size), [
            Size.big, .big, .big, .medium, .medium, .big, .small,
            .small, .big, .big, .medium, .medium, .big, .big
        ], "The finale (13 and 14) must be big, and the mix is 8 big, 4 medium, 2 small.")
    }

    func testEveryShellWearsTheRecordsColours() {
        XCTAssertEqual(shells.map(\.colorNames), [
            ["StateWarnVivid"],
            ["AreaGrowthVivid", "AreaHealthVivid"],
            ["AreaHobbyVivid", "AreaAdminVivid"],
            ["AreaWorkVivid"],
            ["StateGoVivid", "AreaAdminVivid"],
            ["AreaOrangeVivid", "AreaHealthVivid"],
            ["AreaGrowthVivid"],
            ["AreaRedVivid", "StateWarnVivid"],
            ["AreaHealthVivid"],
            ["AreaHobbyVivid", "AreaWorkVivid"],
            ["StateGoVivid", "AreaGrowthVivid"],
            ["AreaAdminVivid"],
            ["AreaOrangeVivid", "AreaGrowthVivid"],
            ["StateWarnVivid", "AreaHobbyVivid"]
        ], "The shells are not in the record's colours.")
    }

    /// A single shell carries one colour; two-tone and ring-in-ring carry two — the second is the
    /// alternate spark or the inner ring, so a shell missing it would draw half its sparks in
    /// nothing.
    func testTwoToneAndRingInRingShellsCarryTwoColoursAndSinglesOne() {
        XCTAssertEqual(shells.count, 14)
        for shell in shells {
            XCTAssertEqual(
                shell.colorNames.count, shell.burst == .single ? 1 : 2,
                "The \(shell.burst) shell at \(shell.launch) s has the wrong number of colours."
            )
        }
    }

    // MARK: - Nine tokens (#7, "OTHER COLOURED")

    /// `Color("Name")` draws nothing for a missing asset and raises no error, so a typo here would
    /// ship invisible fireworks. `UIColor(named:)` returns nil instead, and the test host is the app.
    func testTheShellsUseNineRealTokensAndNeverGreyOrRisk() {
        let used = Set(shells.flatMap(\.colorNames))
        XCTAssertEqual(used.count, 9, "E asked for other colours; the record adds two tokens to the confetti's seven.")
        XCTAssertEqual(used, Set(ConfirmFireworksSchedule.palette), "The palette does not list exactly the tokens the shells use.")
        XCTAssertEqual(
            Set(ConfirmFireworksSchedule.palette), Set(ConfettiRecipe.palette + ["AreaAdminVivid", "AreaRedVivid"]),
            "The nine are the confetti's seven plus `AreaAdminVivid` and `AreaRedVivid`."
        )
        XCTAssertFalse(used.contains("AreaSlateVivid"), "A grey firework.")
        XCTAssertFalse(used.contains("StateRisk"), "A firework in the colour that means risk.")
        for name in ConfirmFireworksSchedule.palette {
            XCTAssertNotNil(
                UIColor(named: name, in: .main, compatibleWith: nil),
                "`\(name)` is not a colour in the asset catalog, so its sparks draw nothing."
            )
        }
    }

    // MARK: - Size classes

    func testTheThreeSizeClassesAreTheRecords() {
        XCTAssertEqual(FireworkShell.SizeClass.big.sparkCount, 72)
        XCTAssertEqual(FireworkShell.SizeClass.big.sparkSpeed, 400, accuracy: 1e-9)
        XCTAssertEqual(FireworkShell.SizeClass.big.sparkLife, 1.45, accuracy: 1e-9)
        XCTAssertEqual(FireworkShell.SizeClass.medium.sparkCount, 56)
        XCTAssertEqual(FireworkShell.SizeClass.medium.sparkSpeed, 310, accuracy: 1e-9)
        XCTAssertEqual(FireworkShell.SizeClass.medium.sparkLife, 1.3, accuracy: 1e-9)
        XCTAssertEqual(FireworkShell.SizeClass.small.sparkCount, 40)
        XCTAssertEqual(FireworkShell.SizeClass.small.sparkSpeed, 220, accuracy: 1e-9)
        XCTAssertEqual(FireworkShell.SizeClass.small.sparkLife, 1.1, accuracy: 1e-9)
    }

    /// 8 × 72 + 4 × 56 + 2 × 40: the per-frame bound the record plans for.
    func testTheScheduleFiresEightHundredAndEightySparksInAll() {
        XCTAssertEqual(shells.map(\.size.sparkCount).reduce(0, +), 880)
    }

    // MARK: - The last spark

    /// The finale's second shell launches at 2.60 s, rises 0.74 s and its sparks live 1.45 s. The
    /// dim's hold is measured back from this instant.
    func testTheLastSparkDiesAtFourPointSevenNineSeconds() {
        XCTAssertEqual(ConfirmFireworksSchedule.lastSparkTime, 4.79, accuracy: 1e-6)
        let latest = shells.map { ConfirmFireworksPhysics.burstTime(of: $0) + $0.size.sparkLife }.max() ?? 0
        XCTAssertEqual(
            ConfirmFireworksSchedule.lastSparkTime, latest, accuracy: 1e-9,
            "The last spark is not derived from the schedule, so a changed shell would leave it stale."
        )
    }
}
