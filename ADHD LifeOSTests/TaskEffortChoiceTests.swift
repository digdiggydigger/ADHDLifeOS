//
//  TaskEffortChoiceTests.swift
//  ADHD LifeOSTests
//
//  `F-D1-ComposerBothDoors`: the composer's Time menu. E's round 6 answer gave the composer
//  "C1's area and time pop-up chips (menus, not sheets)"; the values are the ones the capture
//  disc's Task tile already offered as three chips (`QuickCaptureComponents.effortSection`,
//  deleted by this block), ported rather than re-invented.
//

import XCTest
@testable import ADHD_LifeOS

final class TaskEffortChoiceTests: XCTestCase {

    /// The three the fan's chips offered, in the order they sat, spelt as they were spelt.
    func testTheMenuOffersTheThreeValuesTheFanAlreadyHad() {
        XCTAssertEqual(TaskEffortChoice.allCases.map(\.title), ["15 min", "30 min", "1 hr"])
        XCTAssertEqual(TaskEffortChoice.allCases.map(\.seconds), [900, 1800, 3600])
    }

    /// **"15 min" is the default because it is what E approved by looking.** Every composer board
    /// E confirmed (rounds 6, 6b and 7b — boards `60`, `61`, `64`) renders the Time chip reading
    /// "15 min", and the fan's Task tile already wrote 900 seconds on every create.
    func testTheDefaultIsFifteenMinutes() {
        XCTAssertEqual(TaskEffortChoice.standard, .fifteen)
        XCTAssertEqual(TaskEffortChoice.standard.seconds, 900)
    }
}
