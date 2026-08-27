//
//  AboutInfoTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The About row's numbers, read honestly from the bundle (E's 2026-08-25 Settings audit —
/// the placeholder promised "version, environment, and last refresh"; version and build are the
/// two that truthfully exist, so they are what ships).
final class AboutInfoTests: XCTestCase {
    func testRead_takesVersionAndBuildFromTheInfoDictionary() {
        let info = AboutInfo.read(fromInfo: [
            "CFBundleShortVersionString": "1.4",
            "CFBundleVersion": "87"
        ])

        XCTAssertEqual(info.version, "1.4")
        XCTAssertEqual(info.build, "87")
        XCTAssertEqual(info.formatted, "1.4 (87)")
    }

    func testRead_missingKeysFallBackToADashNeverACrash() {
        let info = AboutInfo.read(fromInfo: [:])

        XCTAssertEqual(info.version, "—")
        XCTAssertEqual(info.build, "—")
        XCTAssertEqual(info.formatted, "— (—)")
    }
}
