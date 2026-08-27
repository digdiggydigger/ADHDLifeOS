//
//  AppearancePreferenceTests.swift
//  ADHD LifeOSTests
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

/// The appearance override's pure mapping (F-V3-Settings): System means NO override, and an
/// unknown stored raw value must fall back to system rather than crash or force a look.
final class AppearancePreferenceTests: XCTestCase {
    func testColorSchemeMapping() {
        XCTAssertNil(AppearancePreference.system.colorScheme)
        XCTAssertEqual(AppearancePreference.light.colorScheme, .light)
        XCTAssertEqual(AppearancePreference.dark.colorScheme, .dark)
    }

    func testUnknownRawValueFallsBackToSystem() {
        XCTAssertEqual(AppearancePreference(rawValue: "sepia") ?? .system, .system)
    }

    func testStorageKeyIsStable() {
        XCTAssertEqual(AppearancePreference.storageKey, "settings.appearance")
    }
}
