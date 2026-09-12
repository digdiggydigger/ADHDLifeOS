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
        XCTAssertEqual(
            CelebrationPolicy.outcome(
                for: .pop, lastFullScreenAt: launch, now: launch, celebrationsEnabled: false
            ),
            .inPlace
        )
        XCTAssertEqual(
            CelebrationPolicy.outcome(
                for: .pop, lastFullScreenAt: nil, now: launch, celebrationsEnabled: true
            ),
            .inPlace
        )
    }

    // MARK: - Confirm (R-c)

    func testAConfirmIsFullScreenWithTheSwitchOnAndNothingAtAllWithItOff() {
        XCTAssertEqual(
            CelebrationPolicy.outcome(
                for: .confirm(clearedStack: false), lastFullScreenAt: nil, now: launch,
                celebrationsEnabled: true
            ),
            .fullScreen
        )
        XCTAssertEqual(
            CelebrationPolicy.outcome(
                for: .confirm(clearedStack: true), lastFullScreenAt: nil, now: launch,
                celebrationsEnabled: false
            ),
            .nothing,
            "A Confirm with the switch off falls back to an in-place celebration. E's #3 turns the"
                + " full-screen celebration OFF; it does not swap it for a smaller one, and the site"
                + " already has its haptic."
        )
    }

    /// R-c: Confirm keeps "every time" (E's #6). A Confirm one instant after another full-screen
    /// celebration still plays in full — it is the one kind the cooldown never touches.
    func testAConfirmIsNeverCooledDownHoweverRecentlyAnythingElsePlayed() {
        XCTAssertEqual(
            CelebrationPolicy.outcome(
                for: .confirm(clearedStack: false), lastFullScreenAt: launch,
                now: launch.addingTimeInterval(0.01), celebrationsEnabled: true
            ),
            .fullScreen
        )
    }

    // MARK: - Milestones (E's #6, R-h)

    func testTheFirstMilestoneOfTheLaunchIsNeverCooledDown() {
        XCTAssertEqual(
            CelebrationPolicy.outcome(
                for: .milestone(.inboxZero), lastFullScreenAt: nil, now: launch,
                celebrationsEnabled: true
            ),
            .fullScreen
        )
    }

    func testAMilestoneInsideTheCooldownGetsTheInPlaceCelebrationInstead() {
        XCTAssertEqual(
            CelebrationPolicy.outcome(
                for: .milestone(.streakSeven), lastFullScreenAt: launch,
                now: launch.addingTimeInterval(CelebrationPolicy.milestoneCooldown - 0.01),
                celebrationsEnabled: true
            ),
            .inPlace,
            "A milestone inside the cooldown is silenced rather than downgraded. E's #6 says it"
                + " 'gets the in-place celebration', so the moment is never unmarked."
        )
    }

    /// The boundary is the moment the cooldown has EXPIRED, not the last instant inside it.
    func testAMilestoneExactlyAtTheCooldownPlaysInFull() {
        XCTAssertEqual(
            CelebrationPolicy.outcome(
                for: .milestone(.dailyGoal), lastFullScreenAt: launch,
                now: launch.addingTimeInterval(CelebrationPolicy.milestoneCooldown),
                celebrationsEnabled: true
            ),
            .fullScreen
        )
    }

    /// R-h: with the switch off a milestone still gets its fallback pop, because several milestone
    /// sites (the ring, the Completed button) have no pop of their own.
    func testAMilestoneWithTheSwitchOffFallsBackToTheInPlaceCelebration() {
        for milestone in CelebrationMilestone.allCases {
            XCTAssertEqual(
                CelebrationPolicy.outcome(
                    for: .milestone(milestone), lastFullScreenAt: nil, now: launch,
                    celebrationsEnabled: false
                ),
                .inPlace,
                "\(milestone) is silenced entirely with the switch off. E's switch covers the"
                    + " full-screen celebration; R-h keeps the in-place one."
            )
        }
    }

    // MARK: - The constant

    /// **E, verbatim (F9): "please reduce that '30-minute cooldown' to 5 seconds for now so i can
    /// test it properly. i am undecided about the cooldown at the moment anyway."**
    ///
    /// It is a TESTING value, and it is E's to change after `F-CTACelebrations-5` — including to
    /// zero, or away entirely. Do not "restore" it to the 30 minutes the design proposed: that
    /// number was never E's.
    func testTheCooldownIsTheFiveSecondsEChoseForTesting() {
        XCTAssertEqual(CelebrationPolicy.milestoneCooldown, 5)
    }
}
