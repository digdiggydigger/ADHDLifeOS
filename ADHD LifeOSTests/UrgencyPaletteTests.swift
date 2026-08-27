//
//  UrgencyPaletteTests.swift
//  ADHD LifeOSTests
//

import UIKit
import XCTest
@testable import ADHD_LifeOS

/// Three urgency bands, four priorities — p2 and p3 fold into the middle band (the chip's P1–P4
/// label keeps them distinguishable). Since the Momentum v3 layer the bands point at the shared
/// State tokens (risk/warn/go) rather than their own colorsets. Locked here so a later edit can't
/// silently re-split the bands or point a priority at a non-existent colorset name.
final class UrgencyPaletteTests: XCTestCase {
    func testAssetNameMapping_foldsFourPrioritiesIntoThreeBands() {
        XCTAssertEqual(UrgencyPalette.assetName(for: .p1), "StateRisk")
        XCTAssertEqual(UrgencyPalette.assetName(for: .p2), "StateWarn")
        XCTAssertEqual(UrgencyPalette.assetName(for: .p3), "StateWarn")
        XCTAssertEqual(UrgencyPalette.assetName(for: .p4), "StateGo")
    }

    func testEveryPriorityResolvesToAnExistingColorAsset() {
        for priority in TaskPriority.allCases {
            let name = UrgencyPalette.assetName(for: priority)
            XCTAssertNotNil(
                UIColor(named: name, in: Bundle(for: ADHD_LifeOS.FirebaseManager.self), compatibleWith: nil),
                "Colorset '\(name)' is missing from the asset catalog"
            )
        }
    }
}
