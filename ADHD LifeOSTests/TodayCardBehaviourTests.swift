//
//  TodayCardBehaviourTests.swift
//  ADHD LifeOSTests
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

/// `F-E3-OneCardToday`: the two decisions the one card makes that are not words — what editing the
/// next step on the card writes, and when the card switches to its compact accessibility layout.
final class TodayCardBehaviourTests: XCTestCase {

    // MARK: - The next step, edited on the card (round 5a: "editable from the card and from task detail")

    /// The card writes exactly what Task Detail's row writes (`F-E2`): trimmed, empty means none,
    /// and cleared is a DELETE of the key (`.some(nil)`), never an empty string.
    func testANewLineIsWrittenTrimmed() {
        XCTAssertEqual(
            TodayNextStep.payload(draft: "  Open the draft  ", current: nil)?.nextStep, .some("Open the draft")
        )
    }

    func testClearingTheLineDeletesIt() {
        XCTAssertEqual(TodayNextStep.payload(draft: "   ", current: "Open the draft")?.nextStep, .some(nil))
    }

    /// Leaving the field unchanged writes nothing — a tap in and out must not cost a network write
    /// or a refetch of Today.
    func testAnUnchangedLineWritesNothing() {
        XCTAssertNil(TodayNextStep.payload(draft: "Open the draft ", current: "Open the draft"))
        XCTAssertNil(TodayNextStep.payload(draft: "", current: nil))
    }

    /// The payload carries the next step and NOTHING else, so a card edit can never overwrite a
    /// field the card does not show.
    func testThePayloadTouchesOnlyTheNextStep() throws {
        let payload = try XCTUnwrap(TodayNextStep.payload(draft: "Open the draft", current: nil))
        var expected = TaskUpdatePayload()
        expected.nextStep = .some("Open the draft")
        XCTAssertEqual(payload, expected)
    }

    // MARK: - The compact card (round 5a: "At AX3 the card is taller than the screen")

    func testTheCardIsCompactAtEveryAccessibilitySizeAndNowhereElse() {
        XCTAssertFalse(TodayCardLayout.isCompact(.large))
        XCTAssertFalse(TodayCardLayout.isCompact(.xxxLarge))
        XCTAssertTrue(TodayCardLayout.isCompact(.accessibility1))
        XCTAssertTrue(TodayCardLayout.isCompact(.accessibility3))
        XCTAssertTrue(TodayCardLayout.isCompact(.accessibility5))
    }
}
