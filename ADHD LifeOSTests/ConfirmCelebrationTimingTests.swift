//
//  ConfirmCelebrationTimingTests.swift
//  ADHD LifeOSTests
//
//  F-ConfirmCelebration-1: how long a Confirm's celebration lasts, how its glow moves, and what
//  happens when Confirms come quickly — E's approved R1: they OVERLAP, at most three at once, the
//  oldest dropped. The removal matters as much as the cap: a burst left in the list after it ends
//  keeps the layer asking for a frame at display rate for as long as the app runs.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class ConfirmCelebrationTimingTests: XCTestCase {

    private let launch = Date(timeIntervalSince1970: 1_800_000_000)

    private func burst(_ ordinal: Int, after seconds: TimeInterval = 0) -> ConfirmCelebrationBurst {
        ConfirmCelebrationBurst(ordinal: ordinal, clearedStack: false, start: launch.addingTimeInterval(seconds))
    }

    // MARK: - The glow

    /// In over 0.3 s, held to 0.9 s, out by 2.4 s — the envelope of the glow E saw.
    func testTheGlowSwellsHoldsAndFadesOnTheRecordsEnvelope() {
        let glow = ConfirmCelebrationGlow.self
        XCTAssertEqual(glow.envelope(at: -0.1), 0, accuracy: 1e-9, "The glow shows before its Confirm.")
        XCTAssertEqual(glow.envelope(at: 0), 0, accuracy: 1e-9)
        XCTAssertEqual(glow.envelope(at: 0.15), 0.5, accuracy: 1e-9, "The glow does not swell over 0.3 s.")
        XCTAssertEqual(glow.envelope(at: 0.3), 1, accuracy: 1e-9)
        XCTAssertEqual(glow.envelope(at: 0.9), 1, accuracy: 1e-9, "The glow does not hold to 0.9 s.")
        XCTAssertEqual(glow.envelope(at: 1.65), 0.5, accuracy: 1e-9, "The glow does not fade out by 2.4 s.")
        XCTAssertEqual(glow.envelope(at: 2.4), 0, accuracy: 1e-9)
        XCTAssertEqual(glow.envelope(at: 3), 0, accuracy: 1e-9)
    }

    /// Two quick Confirms show one glow at whichever is stronger at that instant — here the OLDER
    /// one, still fading, over the newer one just swelling. Instants are given on the CHOREOGRAPHY
    /// clock (divided by the pace), so this also holds the glow to the stretched playback.
    func testOverlappingConfirmsShareOneGlowAtTheStrongest() {
        let pace = ConfirmCelebrationQueue.pace
        let older = burst(1)
        let newer = burst(2, after: 1.2 / pace)
        XCTAssertEqual(
            ConfirmCelebrationGlow.strongestEnvelope(of: [older, newer], at: launch.addingTimeInterval(1.25 / pace)),
            1 - 0.35 / 1.5, accuracy: 1e-6,
            "Overlapping glows are not one wash at the strongest envelope, on the stretched clock."
        )
        XCTAssertEqual(ConfirmCelebrationGlow.strongestEnvelope(of: [], at: launch), 0, accuracy: 1e-9)
    }

    // MARK: - Length

    /// **E, after watching block 1 (2026-09-11): "extend the animation length by 1.2 seconds".**
    /// The prototype's 4.2 s of choreography now plays evenly over 5.4 s: every piece, path and beat
    /// E approved is kept and simply takes longer, with no extra drawing. Stretching was Claude
    /// Code's reading, pending E's feel on the phone; the alternative (same speed, a longer tail)
    /// would have either drawn off-screen or thinned the confetti.
    func testTheCelebrationRunsTheExtraSecondsEAskedFor() {
        let queue = ConfirmCelebrationQueue.self
        let confirm = burst(1)
        XCTAssertEqual(queue.extraLength, 1.2, accuracy: 1e-9, "The celebration is not the 1.2 s longer E asked for.")
        XCTAssertEqual(queue.everyConfirmLength, 5.4, accuracy: 1e-9)
        XCTAssertEqual(
            queue.choreographyTime(of: confirm, at: launch.addingTimeInterval(5.4)), 4.2, accuracy: 1e-6,
            "The whole prototype choreography does not fit the longer celebration exactly."
        )
        XCTAssertEqual(
            queue.choreographyTime(of: confirm, at: launch.addingTimeInterval(2.7)), 2.1, accuracy: 1e-6,
            "The stretch is not even, so some beats speed up while others slow down."
        )
    }

    /// The burst must last until its last piece has landed, and not a noticeable moment longer.
    func testAConfirmBurstLastsUntilItsLastPieceHasLanded() {
        let pieces = ConfettiRecipe.everyConfirm(canvas: CGSize(width: 393, height: 852), ordinal: 1)
        let lastLanding = (pieces.map { $0.delay + $0.lifetime }.max() ?? 0) / ConfirmCelebrationQueue.pace
        XCTAssertEqual(ConfirmCelebrationQueue.everyConfirmLength, 5.4, accuracy: 1e-9)
        XCTAssertLessThanOrEqual(
            lastLanding, ConfirmCelebrationQueue.everyConfirmLength,
            "A burst is removed while its pieces are still falling, so they vanish mid-air."
        )
        XCTAssertGreaterThan(lastLanding, 5, "The premise: the stretched recipe really does fly for about 5.4 s.")
    }

    // MARK: - Quick Confirms (R1)

    /// Four Confirms inside a second: the first is dropped, the other three stay in the air.
    func testAFourthQuickConfirmDropsTheOldestBurst() {
        var bursts: [ConfirmCelebrationBurst] = []
        for ordinal in 1...4 {
            let next = burst(ordinal, after: 0.2 * Double(ordinal))
            bursts = ConfirmCelebrationQueue.adding(next, to: bursts, now: next.start)
        }
        XCTAssertEqual(
            bursts.map(\.ordinal), [2, 3, 4],
            "More than three celebrations are live, or the newest was dropped instead of the oldest."
        )
    }

    /// A burst is removed the moment its length has passed — and adding a new one clears any that
    /// already have — so nothing is left for the layer to keep drawing.
    func testABurstIsGoneOnceItsLengthHasPassed() {
        let first = burst(1)
        let queue = ConfirmCelebrationQueue.self
        XCTAssertEqual(queue.pruned([first], now: launch.addingTimeInterval(5.39)).map(\.ordinal), [1])
        XCTAssertEqual(
            queue.pruned([first], now: launch.addingTimeInterval(5.41)).count, 0,
            "A finished burst stays live, so the layer keeps redrawing an empty sky."
        )
        let later = burst(2, after: 6)
        XCTAssertEqual(
            queue.adding(later, to: [first], now: later.start).map(\.ordinal), [2],
            "Adding a burst keeps one that had already ended."
        )
        XCTAssertEqual(
            queue.nextExpiry(of: [first, burst(3, after: 1)])?.timeIntervalSince(launch) ?? 0, 5.4, accuracy: 1e-6,
            "The layer is not told when the soonest burst ends, so it cannot remove it on time."
        )
        XCTAssertNil(queue.nextExpiry(of: []))
    }

    // MARK: - The stack-clearing Confirm (block 2; E's decision 1: "Same stretch")

    /// The fireworks and the dim ride the SAME stretched clock as the confetti, so the 5.0 s
    /// choreography (the dim gone at 4.99 s) plays over 5.0 / pace ≈ 6.43 s. Every Confirm stays
    /// 5.4 s: the confetti is identical on both, and only the stack-clearing one runs longer.
    func testAStackClearingConfirmPlaysItsFireworksOnTheSameStretch() {
        let queue = ConfirmCelebrationQueue.self
        let cleared = ConfirmCelebrationBurst(ordinal: 1, clearedStack: true, start: launch)
        XCTAssertEqual(queue.stackClearingChoreographyLength, 5.0, accuracy: 1e-9)
        XCTAssertEqual(
            queue.length(of: cleared), 5.0 / queue.pace, accuracy: 1e-9,
            "The fireworks keep their own clock. E chose \"Same stretch\"."
        )
        XCTAssertEqual(queue.length(of: cleared), 6.43, accuracy: 0.005)
        XCTAssertEqual(queue.length(of: burst(1)), 5.4, accuracy: 1e-9, "An every-Confirm is now longer than E saw.")
        let end = launch.addingTimeInterval(queue.length(of: cleared))
        XCTAssertEqual(
            queue.choreographyTime(of: cleared, at: end), 5.0, accuracy: 1e-6,
            "The whole stack-clearing choreography does not fit its burst exactly."
        )
    }

    /// The burst lasts until the dim has lifted, and the last spark dies inside that; the layer is
    /// told the SOONEST expiry, which is the shorter every-Confirm's when both are live.
    func testAStackClearingBurstOutlivesItsLastSparkAndItsDim() {
        let queue = ConfirmCelebrationQueue.self
        XCTAssertLessThanOrEqual(ConfirmFireworksSchedule.lastSparkTime, queue.stackClearingChoreographyLength)
        XCTAssertLessThanOrEqual(
            ConfirmCelebrationDim.goneBy, queue.stackClearingChoreographyLength,
            "The burst ends with the dim still on the screen, so it snaps off."
        )
        XCTAssertGreaterThan(ConfirmCelebrationDim.goneBy, 4.9, "The premise: the dim really does lift at about 5.0 s.")
        let cleared = ConfirmCelebrationBurst(ordinal: 1, clearedStack: true, start: launch)
        XCTAssertEqual(
            queue.pruned([cleared], now: launch.addingTimeInterval(6.42)).count, 1,
            "A stack-clearing burst is removed while its dim is still lifting."
        )
        XCTAssertEqual(queue.pruned([cleared], now: launch.addingTimeInterval(6.44)).count, 0)
        XCTAssertEqual(
            queue.nextExpiry(of: [cleared, burst(2)])?.timeIntervalSince(launch) ?? 0, 5.4, accuracy: 1e-6,
            "The soonest expiry is the every-Confirm's, not the longer stack-clearing one's."
        )
    }
}
