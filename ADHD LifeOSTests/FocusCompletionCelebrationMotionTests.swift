//
//  FocusCompletionCelebrationMotionTests.swift
//  ADHD LifeOSTests
//
//  F-ModernIOS-2-Celebration's pure half — the pilot of CLAUDE.md §7. Which of the three motion
//  modes a celebration plays, and the poses and timing each one travels, are pure functions of
//  (Reduce Motion, availability), so they are tested once, here, with the availability flag
//  INJECTED (§7.4): this machine has one simulator runtime, and it is iOS 26.5. What the modes look
//  like is `screenshots/focus-completion-celebration-modes/`.
//
//  **Reduce Motion is decided before the tier, and that order is the correctness property.**
//  `SymbolEffectOptions` has no Reduce Motion option in the 26.5 SDK, so the iOS 26 draw-on does
//  not gate itself: chosen tier-first, E's own phone — iOS 26, Reduce Motion ON — would get a
//  stroke drawing itself on.
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class FocusCompletionCelebrationMotionTests: XCTestCase {

    // MARK: - Which mode

    /// E's phone is the case this exists for: iOS 26, where the draw-on is available, with Reduce
    /// Motion ON. It must get the cross-fade, never the stroke.
    func testReduceMotionWinsOverEveryTier() {
        for drawOnAvailable in [false, true] {
            XCTAssertEqual(
                FocusCompletionCelebrationMotion.resolve(reduceMotion: true, drawOnAvailable: drawOnAvailable),
                .reduced,
                "Reduce Motion lost to the tier (drawOnAvailable: \(drawOnAvailable)). Symbol effects do"
                    + " not honour Reduce Motion themselves, so a user who asked for less motion gets the"
                    + " motion anyway."
            )
        }
    }

    /// The floor's celebration is block 4's two-beat burst, unchanged: iOS 16 through 25 with
    /// Reduce Motion off. It was green before this block by design — the 16 path is today's code.
    func testTheFloorGetsTheBurst() {
        XCTAssertEqual(
            FocusCompletionCelebrationMotion.resolve(reduceMotion: false, drawOnAvailable: false),
            .full,
            "A phone below iOS 26 with Reduce Motion off no longer plays the burst. That is the floor"
                + " path §7.1 says must be complete."
        )
    }

    func testIOS26GetsTheDrawOnTick() {
        XCTAssertEqual(
            FocusCompletionCelebrationMotion.resolve(reduceMotion: false, drawOnAvailable: true),
            .modern,
            "iOS 26 with Reduce Motion off plays the floor's spring. The draw-on is the tier's whole"
                + " reason to exist, and most users are on current iOS."
        )
    }

    // MARK: - The reduced path: geometry at rest, only opacity travels

    /// The cross-fade starts and ends with the SAME geometry, and ends on the frame the burst ends
    /// on — so under Reduce Motion nothing scales, and the resting card is still the block-2 card
    /// E approved. The halo is pinned at its END scale, 1.6, not at 1: at 1 it sits exactly on the
    /// completed ring and a fade of it shows nothing (block 4's frame `00`).
    func testTheReducedFadeEndsOnTheSameFrameAsTheBurst() {
        let start = FocusCompletionCelebrationPose.armedInPlace
        let end = FocusCompletionCelebrationPose(burstProgress: 1, checkmarkLanded: true, geometryPinned: true)
        let settled = FocusCompletionCelebrationPose.settled
        XCTAssertEqual(end.burstScale, settled.burstScale, accuracy: 0.0001)
        XCTAssertEqual(end.burstOpacity, settled.burstOpacity, accuracy: 0.0001)
        XCTAssertEqual(end.checkmarkScale, settled.checkmarkScale, accuracy: 0.0001)
        XCTAssertEqual(end.checkmarkOpacity, settled.checkmarkOpacity, accuracy: 0.0001)
        XCTAssertEqual(
            start.burstScale, end.burstScale, accuracy: 0.0001,
            "The halo SCALES under Reduce Motion. Only its opacity may travel."
        )
        XCTAssertEqual(
            start.checkmarkScale, end.checkmarkScale, accuracy: 0.0001,
            "The tick SCALES under Reduce Motion. Only its opacity may travel."
        )
    }

    /// A plain ease is §5's carve-out for a Reduce Motion fade (§7.2): the point of the reduced path
    /// is that nothing springs. It waits the same 0.3s, so the fade still lands on a card that has
    /// arrived. The floor keeps block 4's spring, and iOS 26 inserts its draw-on in that same
    /// transaction (the stroke itself runs on the symbol effect's own clock; see
    /// `FocusCompletionDrawOnTick`).
    func testTheReducedTickFadesOnAPlainEaseAfterTheSameDelay() {
        let metrics = FocusCompletionCelebrationMetrics.self
        XCTAssertEqual(
            metrics.checkmarkAnimation(for: .reduced),
            .easeOut(duration: metrics.checkmarkFadeDuration).delay(metrics.delay),
            "The reduced tick springs. An overshoot is motion, which is what the user turned off."
        )
        XCTAssertEqual(metrics.checkmarkFadeDuration, 0.4)
        XCTAssertEqual(
            metrics.checkmarkAnimation(for: .full),
            .spring(response: 0.4, dampingFraction: 0.6).delay(metrics.delay),
            "The floor's spring changed. The 16 path is block 4's, untouched."
        )
        XCTAssertEqual(
            metrics.checkmarkAnimation(for: .modern), metrics.checkmarkAnimation(for: .full),
            "iOS 26 lands its tick on a different animation from the floor's, so the tier changes the"
                + " timing as well as the glyph."
        )
    }

    // MARK: - Which poses animate

    /// `onAppear` animates only an ARMED pose, and the reduced opening is armed too — it has a tick
    /// to fade in and a halo to fade out. A check that recognised only `.armed` would leave a
    /// Reduce Motion card frozen on its opening frame, halo up and no tick, for ever: worse than
    /// the cut this block replaces.
    func testBothArmedPosesHaveSomewhereToGoAndSettledDoesNot() {
        XCTAssertTrue(FocusCompletionCelebrationPose.armed.isArmed)
        XCTAssertTrue(
            FocusCompletionCelebrationPose.armedInPlace.isArmed,
            "The Reduce Motion opening does not count as armed, so `onAppear` never fades it in."
        )
        XCTAssertFalse(FocusCompletionCelebrationPose.settled.isArmed)
    }
}
