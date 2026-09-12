//
//  CelebrationPolicyTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-3`: the one place that decides what a request GETS. E's #6 (a cooldown on
//  milestones), #3 (the Celebrations switch covers full-screen celebrations only), R-c (Confirm
//  counts toward the cooldown but is never itself cooled down) and R-h (a cooled-down or
//  switched-off milestone still gets its in-place celebration, so the moment is never unmarked).
//
//  Pure, and tested with an injected `now`: the rule is what this block has to get right, and it is
//  the half of the feature nothing on screen can show.
//

import XCTest
@testable import ADHD_LifeOS

final class CelebrationPolicyTests: XCTestCase {

    private let launch = Date(timeIntervalSince1970: 1_800_000_000)

    // MARK: - The in-place celebration always plays (E's #3)

    /// "haptics and in-place feedback stay" — verbatim. The switch is over the full-screen
    /// celebrations alone, so a pop is never refused, whatever else is true.
    func testAPopAlwaysPlaysInPlaceEvenWithTheCelebrationsSwitchOff() {
        XCTAssertEqual(CelebrationPolicy.outcome(for: .pop, celebrationsEnabled: false), .inPlace)
        XCTAssertEqual(CelebrationPolicy.outcome(for: .pop, celebrationsEnabled: true), .inPlace)
    }

    // MARK: - Confirm

    func testAConfirmIsFullScreenWithTheSwitchOnAndNothingAtAllWithItOff() {
        XCTAssertEqual(
            CelebrationPolicy.outcome(for: .confirm(clearedStack: false), celebrationsEnabled: true),
            .fullScreen
        )
        XCTAssertEqual(
            CelebrationPolicy.outcome(for: .confirm(clearedStack: true), celebrationsEnabled: false),
            .nothing,
            "A Confirm with the switch off falls back to an in-place celebration. E's #3 turns the"
                + " full-screen celebration OFF; it does not swap it for a smaller one, and the site"
                + " already has its haptic."
        )
    }

    // MARK: - Milestones: never downgraded by anything but E's switch

    /// **E removed the cooldown entirely on 2026-09-12**, having shipped it at 5 s to try it:
    /// *"Remove the cooldown entirely."* So a milestone's outcome depends on ONE thing — whether
    /// E's Celebrations switch is on — and nothing about what played before it can change that.
    ///
    /// **This is the test that would have to change to bring a cooldown back**, and it is the
    /// whole rule in one assertion: every milestone, asked for any number of times in a row,
    /// plays in full.
    func testAMilestoneIsNeverDowngradedByAnythingThatPlayedBeforeIt() {
        for milestone in CelebrationMilestone.allCases {
            for _ in 0..<3 {
                XCTAssertEqual(
                    CelebrationPolicy.outcome(
                        for: .milestone(milestone), celebrationsEnabled: true
                    ),
                    .fullScreen,
                    "\(milestone) was downgraded. E removed the cooldown; a milestone now plays in"
                        + " full every time the switch is on."
                )
            }
        }
    }

    /// R-h: with the switch off a milestone still gets its fallback pop, because several milestone
    /// sites (the ring, the Completed button) have no pop of their own. **R-h survives the
    /// cooldown's removal** — it was never about the cooldown, it is about the switch.
    func testAMilestoneWithTheSwitchOffFallsBackToTheInPlaceCelebration() {
        for milestone in CelebrationMilestone.allCases {
            XCTAssertEqual(
                CelebrationPolicy.outcome(for: .milestone(milestone), celebrationsEnabled: false),
                .inPlace,
                "\(milestone) is silenced entirely with the switch off. E's switch covers the"
                    + " full-screen celebration; R-h keeps the in-place one."
            )
        }
    }

    // MARK: - The rule is now the WHOLE of the policy

    /// A guard against the cooldown creeping back in as a constant nobody reads. `outcome` takes
    /// two arguments and neither is a clock; if a future block needs frequency control it has to
    /// be a deliberate decision with E, not a revived private constant.
    func testThePolicyHasNoClockAndNoCooldownConstant() throws {
        let source = try String(
            contentsOf: URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("ADHD LifeOS/Celebrations/CelebrationPolicy.swift"),
            encoding: .utf8
        )
        let code = source
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
        XCTAssertFalse(
            code.contains("milestoneCooldown"),
            "The cooldown constant is back in CelebrationPolicy. E removed it deliberately."
        )
        XCTAssertFalse(
            code.contains("Date"),
            "CelebrationPolicy reads a clock again; its answer no longer depends on time."
        )
    }
}
