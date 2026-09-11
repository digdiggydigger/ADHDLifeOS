//
//  ConfirmCelebrationDimTests.swift
//  ADHD LifeOSTests
//
//  F-ConfirmCelebration-2: the light-appearance dim under a stack-clearing Confirm's fireworks.
//  E, by video (#7, #8): "for light-mode display views, a background dim for the duration of the
//  fireworks" — at 85%, which "reads like a night sky", over 55%, which "goes flat grey".
//

import UIKit
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class ConfirmCelebrationDimTests: XCTestCase {

    private let launch = Date(timeIntervalSince1970: 1_800_000_000)

    func testTheDimIsTheScrimTokenAtEightyFivePercent() {
        XCTAssertEqual(ConfirmCelebrationDim.colorName, "Scrim")
        XCTAssertEqual(ConfirmCelebrationDim.peakOpacity, 0.85, accuracy: 1e-9, "E chose A: 85%, not 55%.")
        XCTAssertNotNil(
            UIColor(named: ConfirmCelebrationDim.colorName, in: .main, compatibleWith: nil),
            "`\(ConfirmCelebrationDim.colorName)` is not a colour in the asset catalog."
        )
    }

    /// In over 0.35 s, held until 0.4 s before the last spark dies, out over 0.6 s — so the sky is
    /// dark for every firework and lifts as the last embers fade.
    func testTheDimComesInHoldsForTheFireworksAndLiftsAsTheLastSparkDies() {
        let dim = ConfirmCelebrationDim.self
        XCTAssertEqual(dim.envelope(at: -0.1), 0, accuracy: 1e-9, "The dim shows before its Confirm.")
        XCTAssertEqual(dim.envelope(at: 0), 0, accuracy: 1e-9)
        XCTAssertEqual(dim.envelope(at: 0.175), 0.5, accuracy: 1e-9, "The dim does not come in over 0.35 s.")
        XCTAssertEqual(dim.envelope(at: 0.35), 1, accuracy: 1e-9)
        XCTAssertEqual(dim.envelope(at: 2.6), 1, accuracy: 1e-9, "The dim lifts while shells are still launching.")
        XCTAssertEqual(dim.envelope(at: 4.39), 1, accuracy: 1e-9, "The dim lifts earlier than 0.4 s before the last spark.")
        XCTAssertEqual(dim.envelope(at: 4.69), 0.5, accuracy: 1e-9, "The dim does not lift over 0.6 s.")
        XCTAssertEqual(dim.envelope(at: 4.99), 0, accuracy: 1e-9)
        XCTAssertEqual(dim.envelope(at: 5.5), 0, accuracy: 1e-9)
    }

    /// The hold is measured back from the schedule's last spark, so a longer schedule keeps the
    /// sky dark for it without a second number to update.
    func testTheDimsHoldIsTiedToTheLastSpark() {
        XCTAssertEqual(
            ConfirmCelebrationDim.holdUntil, ConfirmFireworksSchedule.lastSparkTime - 0.4, accuracy: 1e-9,
            "The dim's hold is not measured from the last spark."
        )
        XCTAssertEqual(ConfirmCelebrationDim.holdUntil, 4.39, accuracy: 1e-6)
        XCTAssertEqual(ConfirmCelebrationDim.goneBy, 4.99, accuracy: 1e-6)
    }

    /// Only a stack-clearing Confirm dims; overlapping ones share one dim at the strongest, on the
    /// stretched clock — the glow's rule, so the screen never goes darker than anything E saw.
    func testOnlyStackClearingConfirmsDimAndOverlappingOnesShareTheStrongest() {
        let pace = ConfirmCelebrationQueue.pace
        let dim = ConfirmCelebrationDim.self
        let every = ConfirmCelebrationBurst(ordinal: 1, clearedStack: false, start: launch)
        let cleared = ConfirmCelebrationBurst(ordinal: 2, clearedStack: true, start: launch.addingTimeInterval(1))
        XCTAssertEqual(
            dim.strongestEnvelope(of: [every], at: launch.addingTimeInterval(1)), 0, accuracy: 1e-9,
            "An every-Confirm dims the screen. Only the stack-clearing one does."
        )
        XCTAssertEqual(
            dim.strongestEnvelope(of: [every, cleared], at: launch.addingTimeInterval(1 + 0.175 / pace)), 0.5, accuracy: 1e-6,
            "The dim is not on the stretched choreography clock."
        )
        let older = ConfirmCelebrationBurst(ordinal: 3, clearedStack: true, start: launch)
        let newer = ConfirmCelebrationBurst(ordinal: 4, clearedStack: true, start: launch.addingTimeInterval(4.69 / pace))
        XCTAssertEqual(dim.strongestEnvelope(of: [older, newer], at: launch.addingTimeInterval(4.69 / pace)), 0.5, accuracy: 1e-6)
        XCTAssertEqual(
            dim.strongestEnvelope(of: [older, newer], at: launch.addingTimeInterval((4.69 + 0.175) / pace)), 0.5, accuracy: 1e-6,
            "Two dims do not share the strongest envelope."
        )
        XCTAssertEqual(dim.strongestEnvelope(of: [], at: launch), 0, accuracy: 1e-9)
    }
}
