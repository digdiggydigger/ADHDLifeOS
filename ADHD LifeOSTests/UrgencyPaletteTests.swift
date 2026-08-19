//
//  UrgencyPaletteTests.swift
//  ADHD LifeOSTests
//

import UIKit
import XCTest
@testable import ADHD_LifeOS

/// The prototype has THREE urgency bands (high #FF5B5B, medium amber, low emerald) while the
/// native model has FOUR priorities — the settled mapping folds p2 and p3 into the medium band
/// (the chip's P1–P4 label keeps them distinguishable). Locked here so a later edit can't
/// silently re-split the bands or point a priority at a non-existent colorset name.
final class UrgencyPaletteTests: XCTestCase {
    func testAssetNameMapping_foldsFourPrioritiesIntoThreeBands() {
        XCTAssertEqual(UrgencyPalette.assetName(for: .p1), "UrgencyHigh")
        XCTAssertEqual(UrgencyPalette.assetName(for: .p2), "UrgencyMedium")
        XCTAssertEqual(UrgencyPalette.assetName(for: .p3), "UrgencyMedium")
        XCTAssertEqual(UrgencyPalette.assetName(for: .p4), "UrgencyLow")
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
