//
//  MomentumThemeTokenTests.swift
//  ADHD LifeOSTests
//

import UIKit
import XCTest
@testable import ADHD_LifeOS

/// Every non-area token the Momentum v3 layer introduces (or re-values) must exist in the asset
/// catalog — a missing colorset renders as clear, not as an error, so this is the only guard.
/// The area families are covered by `AreaPaletteTests`.
final class MomentumThemeTokenTests: XCTestCase {
    func testEveryV3TokenExistsInTheAssetCatalog() {
        let bundle = Bundle(for: ADHD_LifeOS.FirebaseManager.self)
        let tokens = [
            "AccentColor",
            "PageBackground", "CardSurface", "CardSurfaceSecondary", "BarSurface", "CardBorder",
            "LabelPrimary", "LabelSecondary", "LabelTertiary",
            "TrackNeutral", "TrackNeutralStrong", "Scrim",
            "StateGo", "StateGoVivid", "StateWarn", "StateWarnVivid", "StateRisk",
            "OnStateGo", "OnStateWarn"
        ]
        for name in tokens {
            XCTAssertNotNil(
                UIColor(named: name, in: bundle, compatibleWith: nil),
                "Colorset '\(name)' is missing from the asset catalog"
            )
        }
    }
}
