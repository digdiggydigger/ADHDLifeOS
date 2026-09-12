//
//  CelebrationDefaultsTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-3`: the paths the app itself takes and no other test does.
//
//  **Found by reading the coverage report, not by guessing** — the lesson CLAUDE.md records from
//  `F-AdapterDrift`: a default argument that every test overrides is a live, shipped, unexercised
//  path, and the report is where it shows. `CelebrationCenterTests` injects all three of the
//  centre's dependencies, so the three the APP uses were never once evaluated; and
//  `InertCelebrationRequester` is what every site sees outside `RootView`'s environment — previews,
//  snapshots, and any future screen someone forgets to wire — so it ships on every launch and was
//  called by nothing.
//

import CoreGraphics
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class CelebrationDefaultsTests: XCTestCase {

    // MARK: - The centre's production defaults

    /// A pop is never gated and never cooled down, so this exercises the real `now:` and the real
    /// `chime:` without depending on what the Settings switch happens to say.
    func testTheCentreTheAppBuildsRunsOnTheRealClock() {
        let center = CelebrationCenter()
        let before = Date()
        XCTAssertEqual(center.request(.pop, at: CGPoint(x: 5, y: 6)), .inPlace)
        let after = Date()
        let burst = center.bursts.first
        XCTAssertEqual(burst?.origin, CGPoint(x: 5, y: 6))
        let start = try? XCTUnwrap(burst?.start)
        XCTAssertNotNil(start)
        if let start {
            XCTAssertGreaterThanOrEqual(start, before)
            XCTAssertLessThanOrEqual(start, after, "The centre the App builds is not on the real clock.")
        }
    }

    /// The gate's default is `AppFeedback.celebrationsEnabled()` — E's Settings switch. Asserted
    /// against what the policy says for the store's CURRENT value rather than against a fixed
    /// answer, so the test reads the switch without writing it and passes either way round.
    func testTheCentreTheAppBuildsReadsESCelebrationsSwitch() {
        let center = CelebrationCenter()
        let expected = CelebrationPolicy.outcome(
            for: .confirm(clearedStack: false),
            lastFullScreenAt: nil,
            now: Date(),
            celebrationsEnabled: AppFeedback.celebrationsEnabled()
        )
        XCTAssertEqual(
            center.request(.confirm(clearedStack: false), at: nil), expected,
            "The centre the App builds does not consult E's Celebrations switch, so the Settings row"
                + " governs nothing in production however well the injected gate behaves in tests."
        )
    }

    // MARK: - The burst's kinds

    /// Only a Confirm can clear the stack. A milestone or a pop that answered `true` would be handed
    /// fireworks and the light-mode dim, neither of which E gave them (F8: the fireworks stay the
    /// stack-clearing Confirm's alone).
    func testOnlyAConfirmEverReportsThatItClearedTheStack() {
        let moment = Date()
        for kind in [CelebrationKind.pop, .milestone(.inboxZero), .milestone(.routineFinished)] {
            let burst = CelebrationBurst(
                ordinal: 1, kind: kind, surface: .root, start: moment, origin: nil
            )
            XCTAssertFalse(burst.clearedStack, "\(kind) claims to have cleared the sprint stack.")
        }
        XCTAssertTrue(
            CelebrationBurst(
                ordinal: 1, kind: .confirm(clearedStack: true), surface: .root, start: moment, origin: nil
            ).clearedStack
        )
        XCTAssertFalse(
            CelebrationBurst(
                ordinal: 1, kind: .confirm(clearedStack: false), surface: .root, start: moment, origin: nil
            ).clearedStack
        )
    }

    // MARK: - The environment's inert default

    /// What a site sees when nothing wired it: every request refused, every surface call a no-op.
    /// This is the shipped default of `\.celebrate`, so it runs in every preview and in any screen
    /// presented outside `RootView`'s environment — and it must never trap or pretend to celebrate.
    func testTheInertRequesterRefusesEverythingAndNeverTraps() {
        let inert = InertCelebrationRequester()
        XCTAssertEqual(inert.request(.pop, at: CGPoint(x: 1, y: 2)), .nothing)
        XCTAssertEqual(inert.request(.confirm(clearedStack: true), at: nil), .nothing)
        for milestone in CelebrationMilestone.allCases {
            XCTAssertEqual(inert.request(.milestone(milestone), at: nil), .nothing)
        }
        for surface in CelebrationSurface.allCases {
            inert.surfacePresented(surface)
            inert.surfaceDismissed(surface)
        }
    }
}
