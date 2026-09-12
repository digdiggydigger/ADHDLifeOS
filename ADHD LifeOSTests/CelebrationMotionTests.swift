//
//  CelebrationMotionTests.swift
//  ADHD LifeOSTests
//
//  `F-CTACelebrations-3`: which rendering a celebration gets, resolved ONCE and before any tier is
//  chosen (CLAUDE.md §7.2 — symbol effects, `PhaseAnimator` and `keyframeAnimator` do not honour
//  Reduce Motion themselves, so a site that picks a tier first can reach a motion tier from a
//  reduced path).
//
//  This is the behavioural half of the §7.2 waiver pin. The other half — that the Confirm files
//  read Reduce Motion nowhere, and that this resolver answers for Confirm BEFORE it looks at the
//  setting — is `ConfirmCelebrationCallSiteTests.testTheConfirmCelebrationIgnoresReduceMotionByDesign`.
//

import XCTest
@testable import ADHD_LifeOS

final class CelebrationMotionTests: XCTestCase {

    /// **E's waiver of §7.2, 2026-09-11, verbatim: "B AND C"** — with Reduce Motion ON, Confirm
    /// shows the glow AND real falling confetti. It is the ONE waiver, it covers this site alone,
    /// and it is not extended by analogy.
    func testAConfirmPlaysInFullWithReduceMotionOnBecauseEWaivedSevenTwoForIt() {
        XCTAssertEqual(CelebrationMotion.resolve(reduceMotion: true, kind: .confirm(clearedStack: false)), .full)
        XCTAssertEqual(CelebrationMotion.resolve(reduceMotion: true, kind: .confirm(clearedStack: true)), .full)
    }

    /// E's #7: "Fade everywhere new". Every site this arc adds fades under Reduce Motion; E accepted
    /// that the new milestones will not rain on their own phone.
    func testEveryNewKindFadesUnderReduceMotion() {
        for milestone in CelebrationMilestone.allCases {
            XCTAssertEqual(
                CelebrationMotion.resolve(reduceMotion: true, kind: .milestone(milestone)), .still,
                "\(milestone) keeps its falling confetti under Reduce Motion. Only Confirm is waived."
            )
        }
        XCTAssertEqual(CelebrationMotion.resolve(reduceMotion: true, kind: .pop), .still)
    }

    func testNothingIsReducedWhenTheSettingIsOff() {
        XCTAssertEqual(CelebrationMotion.resolve(reduceMotion: false, kind: .pop), .full)
        XCTAssertEqual(CelebrationMotion.resolve(reduceMotion: false, kind: .milestone(.inboxZero)), .full)
        XCTAssertEqual(CelebrationMotion.resolve(reduceMotion: false, kind: .confirm(clearedStack: false)), .full)
    }
}
