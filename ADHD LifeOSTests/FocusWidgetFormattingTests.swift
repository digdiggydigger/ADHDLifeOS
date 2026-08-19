//
//  FocusWidgetFormattingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The widget extension can't link the app's `FocusTimeFormatting`, so `FocusWidgetFormatting`
/// restates it in the shared file. This locks the two together: the Home Screen and the in-app
/// weekly card must never describe the same week differently.
final class FocusWidgetFormattingTests: XCTestCase {
    /// Boundaries plus a spread of ordinary values: sub-minute, whole minutes, mixed, exactly an
    /// hour, over an hour, and negatives.
    private let cases = [-90, -1, 0, 1, 30, 59, 60, 61, 90, 450, 900, 1_500, 3_540, 3_600, 3_661, 5_100, 7_200, 86_400]

    func testHuman_matchesTheAppFormatterEverywhere() {
        for seconds in cases {
            XCTAssertEqual(
                FocusWidgetFormatting.human(seconds: seconds),
                FocusTimeFormatting.human(seconds: seconds),
                "human(\(seconds))"
            )
        }
    }

    func testDuration_matchesTheAppFormatterEverywhere() {
        for seconds in cases {
            XCTAssertEqual(
                FocusWidgetFormatting.duration(seconds: seconds),
                FocusTimeFormatting.duration(seconds: seconds),
                "duration(\(seconds))"
            )
        }
    }

    func testKnownRenderings() {
        XCTAssertEqual(FocusWidgetFormatting.human(seconds: 900), "15m")
        XCTAssertEqual(FocusWidgetFormatting.human(seconds: 450), "7m 30s")
        XCTAssertEqual(FocusWidgetFormatting.duration(seconds: 5_100), "1h 25m")
        XCTAssertEqual(FocusWidgetFormatting.duration(seconds: 0), "0m")
    }
}
