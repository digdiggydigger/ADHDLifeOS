//
//  FocusCompletionCelebrationTests.swift
//  ADHD LifeOSTests
//
//  F-FocusCard-4's pure half. The burst is a SwiftUI animation and out of a unit test's reach by
//  construction — the design record says so, and the evidence for it is
//  `screenshots/focus-completion-celebration/`. What IS reachable is the pose the view opens in
//  and the curve it travels, and both are decisions: the opening pose is where the Reduce Motion
//  trap lives, and the curve's endpoints are what make the resting card identical to the one E
//  approved in block 2.
//
//  F-ModernIOS-2-Celebration added the motion modes; which mode a card resolves to, and the
//  reduced path's timing, are `FocusCompletionCelebrationMotionTests`.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class FocusCompletionCelebrationTests: XCTestCase {

    // MARK: - The opening pose — where Reduce Motion is decided

    /// The floor and iOS 26 both open on the floor's armed pose: the draw-on changes how the tick
    /// ARRIVES, not where the halo starts.
    func testACardThatPlaysOpensArmed() {
        for motion in [FocusCompletionCelebrationMotion.full, .modern] {
            XCTAssertEqual(
                FocusCompletionCelebrationPose.opening(plays: true, motion: motion),
                .armed,
                "A fresh completion (\(motion)) opens on the FINAL state, so there is nothing to"
                    + " animate from and the burst never happens."
            )
        }
    }

    /// **Flipped by F-ModernIOS-2-Celebration (E, 2026-09-11).** This was
    /// `testReduceMotionOpensOnTheFinalState`, and it held exactly what the design record asked
    /// for: under Reduce Motion, open SETTLED. That was the hard cut E lived with. E's phone runs
    /// Reduce Motion ON, so the block-4 celebration never once played for its author — E saw a
    /// finished tick and felt the haptic. CLAUDE.md §7.2 now says Reduce Motion replaces motion
    /// with a fade and never removes the feedback.
    ///
    /// The record's trap still stands, restated for a fade: the opening must never show the
    /// pre-animation GEOMETRY (a tick at 0.6, a halo on the ring). So the reduced opening has every
    /// scale at its final value and only opacity left to travel — tick clear, halo visible.
    /// Resolved for E's own configuration, iOS 26 with Reduce Motion ON, where the draw-on tier is
    /// available and must still lose.
    func testReduceMotionOpensWithGeometryAtRestAndOnlyOpacityToTravel() {
        let motion = FocusCompletionCelebrationMotion.resolve(reduceMotion: true, drawOnAvailable: true)
        let opening = FocusCompletionCelebrationPose.opening(plays: true, motion: motion)
        let metrics = FocusCompletionCelebrationMetrics.self
        XCTAssertEqual(
            opening, .armedInPlace,
            "A Reduce Motion card does not open armed in place, so it either cuts or moves."
        )
        XCTAssertEqual(
            opening.burstScale, metrics.burstScaleEnd,
            "The halo opens on the ring and would GROW under Reduce Motion."
        )
        XCTAssertEqual(
            opening.checkmarkScale, 1,
            "The tick opens small and would SPRING under Reduce Motion — the record's trap."
        )
        XCTAssertEqual(
            opening.checkmarkOpacity, 0,
            "The tick is already visible, so there is nothing to fade in: the old hard cut."
        )
        XCTAssertEqual(
            opening.burstOpacity, metrics.burstOpacityStart,
            "The halo is already gone, so there is nothing to fade out."
        )
    }

    /// A card revealed by a Confirm, or restored by a relaunch, did not just finish. It opens
    /// settled — the same view, already at rest — in every mode.
    func testACardThatDoesNotPlayOpensSettled() {
        for motion in FocusCompletionCelebrationMotion.allCases {
            XCTAssertEqual(
                FocusCompletionCelebrationPose.opening(plays: false, motion: motion),
                .settled,
                "A card that did not just finish replays its celebration (\(motion))."
            )
        }
    }

    // MARK: - The resting card is the card E approved

    /// The whole animation ends on a pose that is INVISIBLE apart from the checkmark: no ring, the
    /// checkmark at full size. That is what keeps the block-2 card E approved unchanged once the
    /// burst has passed — and it is the state every non-playing card sits in from its first frame.
    func testTheSettledPoseDrawsOnlyTheCheckmark() {
        let settled = FocusCompletionCelebrationPose.settled
        XCTAssertEqual(settled.burstOpacity, 0, "A ring is still visible on the card at rest.")
        XCTAssertEqual(settled.checkmarkScale, 1)
        XCTAssertEqual(settled.checkmarkOpacity, 1)
    }

    func testTheArmedPoseHoldsTheRingAtTheRingAndTheCheckmarkSmall() {
        let armed = FocusCompletionCelebrationPose.armed
        XCTAssertEqual(
            armed.burstScale, 1,
            "The burst must START at the ring's own edge — that is what makes it read as the ring"
                + " radiating rather than a second shape appearing."
        )
        XCTAssertEqual(armed.burstOpacity, FocusCompletionCelebrationMetrics.burstOpacityStart)
        XCTAssertEqual(armed.checkmarkScale, FocusCompletionCelebrationMetrics.checkmarkScaleStart)
        XCTAssertEqual(armed.checkmarkOpacity, 0)
    }

    // MARK: - The curve

    /// The record's numbers: 1 → 1.6 while fading 0.8 → 0. Held as ENDPOINTS rather than as a
    /// table, because the easing between them is the animation's, not the metric's.
    func testTheBurstGrowsWhileItFades() {
        XCTAssertEqual(FocusCompletionCelebrationMetrics.burstScale(progress: 0), 1)
        XCTAssertEqual(FocusCompletionCelebrationMetrics.burstScale(progress: 1), 1.6, accuracy: 0.0001)
        XCTAssertEqual(FocusCompletionCelebrationMetrics.burstOpacity(progress: 0), 0.8, accuracy: 0.0001)
        XCTAssertEqual(FocusCompletionCelebrationMetrics.burstOpacity(progress: 1), 0)
    }

    /// Strict, because a constant stub passes the endpoints' non-strict neighbours: halfway along,
    /// the ring must be strictly larger than at the start and strictly fainter.
    func testTheBurstIsMonotonicBetweenItsEndpoints() {
        let scale = FocusCompletionCelebrationMetrics.burstScale
        let opacity = FocusCompletionCelebrationMetrics.burstOpacity
        XCTAssertGreaterThan(scale(0.5), scale(0))
        XCTAssertGreaterThan(scale(1), scale(0.5))
        XCTAssertLessThan(opacity(0.5), opacity(0))
        XCTAssertLessThan(opacity(1), opacity(0.5))
    }

    /// The pose is a mid-flight frame of the curve, not a second copy of it: what the metrics say
    /// at a progress is what the pose draws.
    func testAPoseReadsItsRingOffTheCurve() {
        let pose = FocusCompletionCelebrationPose(burstProgress: 0.25, checkmarkLanded: true)
        XCTAssertEqual(pose.burstScale, FocusCompletionCelebrationMetrics.burstScale(progress: 0.25))
        XCTAssertEqual(pose.burstOpacity, FocusCompletionCelebrationMetrics.burstOpacity(progress: 0.25))
    }

    // MARK: - Timing

    /// The burst waits for the card to LAND. The card arrives on the overlay's 0.35s spring; a
    /// burst starting at frame one plays mostly while the card is still sliding up, and the
    /// checkmark's pop is lost in the slide. The delay is on the §2 timing idiom for the spring.
    func testTheBurstWaitsForTheCardToLand() {
        XCTAssertGreaterThanOrEqual(
            FocusCompletionCelebrationMetrics.delay, 0.3,
            "The burst starts before the card has landed, so the checkmark pops while the card is"
                + " still moving."
        )
        XCTAssertLessThan(
            FocusCompletionCelebrationMetrics.delay, 0.6,
            "The burst waits so long the completion and its celebration read as two events."
        )
    }

    /// "A long `.easeOut`" — long relative to the app's 0.35s spring, so the ring is seen to
    /// radiate rather than blink.
    func testTheBurstIsLongerThanTheHouseSpring() {
        XCTAssertGreaterThan(FocusCompletionCelebrationMetrics.burstDuration, 0.35)
    }

    /// **E asked for the animations to be longer** (2026-09-11, on device with Reduce Motion ON,
    /// once F-ModernIOS-2-Celebration had landed). Both fades were doubled from block 4's lengths —
    /// the halo 0.9s → 1.8s in every mode, the reduced tick 0.4s → 0.8s. The factor was Claude
    /// Code's pick, pending E's verdict on the phone. The 0.3s landing delay is a wait, not an
    /// animation, and did not move. Pinned so a tidy-up cannot quietly undo a length judged by eye;
    /// if E tunes it again, change it here with the reason.
    func testTheFadesRunAtTheLengthEAskedFor() {
        XCTAssertEqual(
            FocusCompletionCelebrationMetrics.burstDuration, 1.8, accuracy: 0.0001,
            "The halo's fade is not the length E asked for."
        )
        XCTAssertEqual(
            FocusCompletionCelebrationMetrics.checkmarkFadeDuration, 0.8, accuracy: 0.0001,
            "The Reduce Motion tick's fade is not the length E asked for."
        )
    }
}
