//
//  AppSearchRowMetricsTests.swift
//  ADHD LifeOSTests
//
//  The row's geometry, and the clearance it costs the screens that carry it.
//
//  **The clearance is the part that can silently break other screens.**
//  `CaptureDiscMetrics.clearance` is 92 (disc 60 + edge margin 24 + 8) and eleven files lean on it
//  through `.captureDiscClearance()`. Three screens now need MORE room than the other eight, and
//  the wrong fix — a second number typed somewhere — is exactly how `CaptureDiscClearanceCallSite`
//  came to exist: a helper that is correct while nothing calls it, or two spellings that drift.
//  So the taller clearance is DERIVED from the shorter one plus the row, and asserted here.
//

import XCTest
@testable import ADHD_LifeOS

final class AppSearchRowMetricsTests: XCTestCase {

    /// §3's floor. The row's control is a Button, so this is a real touch target, not decoration.
    func testTheFieldClearsTheTouchTargetFloor() {
        XCTAssertGreaterThanOrEqual(
            AppSearchRowMetrics.fieldHeight, 44,
            "The search field is under §3's 44pt touch target. It is the only way into search on"
                + " three screens."
        )
    }

    /// E's settled capture-disc geometry is not this arc's to move (`capture-disc-design`, four
    /// device passes). The row sits BESIDE the disc; it does not renegotiate it.
    func testTheDiscKeepsItsSettledTrailingMargin() {
        XCTAssertEqual(
            CaptureDiscMetrics.edgeMargin, 24,
            "The capture disc's trailing margin moved. That number is E's, settled over four"
                + " device passes, and the search row was added beside the disc — not in place"
                + " of its geometry."
        )
    }

    /// E asked for this by name when approving the layout: *"I just wanna make sure that you have
    /// added spacing between the top of the menu/nav tab bar and the collapsed pill."*
    func testTheGapAboveTheTabBarIsUnchanged() {
        XCTAssertEqual(
            AppSearchRowMetrics.gapAboveTabBar, 60,
            "The 60pt gap between the top of the tab bar and the capture stack changed. That is"
                + " E's 2026-08-31 margin pass and E re-confirmed it when approving this row."
        )
    }

    // MARK: - The clearance

    func testASearchScreenNeedsStrictlyMoreBottomRoom() {
        XCTAssertGreaterThan(
            AppSearchRowMetrics.clearance(hasSearchRow: true),
            AppSearchRowMetrics.clearance(hasSearchRow: false),
            "A screen with a search row asks for the same bottom room as one without, so its last"
                + " row sits under the field."
        )
    }

    func testAScreenWithoutTheRowPaysNothingForIt() {
        XCTAssertEqual(
            AppSearchRowMetrics.clearance(hasSearchRow: false),
            CaptureDiscMetrics.clearance,
            "A screen with no search row is being padded as though it had one — eight screens"
                + " would grow a dead strip at the bottom for a control they never show."
        )
    }

    /// Derived, not typed. Change the field height or the spacing and the clearance follows; type
    /// a second number and it drifts the first time either moves.
    func testTheExtraRoomIsExactlyTheRowAndItsSpacing() {
        let difference = AppSearchRowMetrics.clearance(hasSearchRow: true)
            - AppSearchRowMetrics.clearance(hasSearchRow: false)

        XCTAssertEqual(
            difference,
            AppSearchRowMetrics.fieldHeight + AppSearchRowMetrics.rowSpacing,
            accuracy: 0.001,
            "The search-row clearance is no longer derived from the row it clears. It is a second"
                + " number now, and it will drift the first time the field's height changes."
        )
    }

    /// The disc's outer frame is 60x60 in BOTH states — only the visual capsule shrinks to 60x48
    /// when scrolled — so the row's centre never moves between disc and pill. E's layout is
    /// "centres aligned", and this is what makes that free rather than a tracked animation.
    func testTheRowIsAtLeastAsTallAsTheDiscSoTheCentresCannotDrift() {
        XCTAssertLessThanOrEqual(
            AppSearchRowMetrics.fieldHeight, CaptureDiscMetrics.discDiameter,
            "The field is taller than the disc's frame, so the row's height is now set by the"
                + " field and the disc's centre shifts when the pill collapses — the one thing"
                + " the constant 60x60 frame was protecting."
        )
    }
}
