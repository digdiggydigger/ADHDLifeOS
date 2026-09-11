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

import XCTest
@testable import ADHD_LifeOS

final class FocusCompletionCelebrationTests: XCTestCase {

    // MARK: - The opening pose — where Reduce Motion is decided

    func testACardThatPlaysOpensArmed() {
        XCTAssertEqual(
            FocusCompletionCelebrationPose.opening(plays: true, reduceMotion: false),
            .armed,
            "A fresh completion opens on the FINAL state, so there is nothing to animate from and"
                + " the burst never happens."
        )
    }

    /// **The trap the design record names.** Under Reduce Motion the celebration must open on the
    /// final state — checkmark present, no ring — never on the pre-animation one, which is what
    /// makes reduce-motion paths look broken: a checkmark stuck at 0.6 scale and a ring frozen at
    /// 0.8 opacity, for ever.
    func testReduceMotionOpensOnTheFinalState() {
        XCTAssertEqual(
            FocusCompletionCelebrationPose.opening(plays: true, reduceMotion: true),
            .settled,
            "Reduce Motion is showing the pre-animation pose. With no animation to carry it to"
                + " the final state, the card is stuck mid-burst."
        )
    }

    /// A card revealed by a Confirm, or restored by a relaunch, did not just finish. It opens
    /// settled — the same view, already at rest.
    func testACardThatDoesNotPlayOpensSettled() {
        XCTAssertEqual(
            FocusCompletionCelebrationPose.opening(plays: false, reduceMotion: false),
            .settled
        )
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
}
