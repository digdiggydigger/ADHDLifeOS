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

    /// **Measured off E's own device markings, not chosen.** E marked the target twice on
    /// 2026-09-03 and asked for the capture button *"comfortably aligned with the One line about
    /// today button on the Journal Tab"*: that composer field spans y 677.3-723.7 (centre 700.5)
    /// and E's ring around it centred on 701.5. This gap puts the disc's centre at 698 on an
    /// iPhone 15 Pro — 2.5pt out, inside the width of the line E drew.
    ///
    /// It was 60 for exactly one build, and that was 58pt too generous: the 60 had never meant
    /// "above the bar" — it was measured from the home indicator while the disc overlapped the
    /// bar, so restoring the missing bar height made it wrong in the other direction.
    func testTheGapAboveTheTabBarMatchesEsMarking() {
        XCTAssertEqual(
            AppSearchRowMetrics.gapAboveTabBar, 32,
            "The gap above the tab bar changed. 32 is what centres the capture button on the"
                + " Journal composer, which is the alignment E marked on device."
        )
    }

    /// The gap has to clear the bar and stay clear of it: too small and the disc sits ON the bar
    /// (the 7pt overlap E photographed), too large and it floats away from the composer it is
    /// meant to line up with.
    func testTheGapClearsTheBarWithoutFloatingAway() {
        XCTAssertGreaterThanOrEqual(
            AppSearchRowMetrics.gapAboveTabBar, 24,
            "The capture button is close enough to the tab bar to read as attached to it."
        )
        XCTAssertLessThanOrEqual(
            AppSearchRowMetrics.gapAboveTabBar, 40,
            "The capture button has floated far enough above the bar to stop lining up with a"
                + " screen's own bottom furniture — the Journal composer is the reference."
        )
    }

    // MARK: - The clearance, one number per AXIS

    /// The bottom inset must clear the disc's TOP measured from the safe-area bottom — which is
    /// `bottomFurnitureLift` (the bar band the container deliberately does not reserve) plus the
    /// disc, plus breathing room. The old base was `CaptureDiscMetrics.clearance` (92), a number
    /// derived when `TabView` still reserved the bar's band for free: with the custom bar the
    /// content floor sat 58pt — exactly `AppTabBarMetrics.rowHeight` — inside the disc, and both
    /// `CaptureDiscClearanceUITests` measured rows RESTING under it (3/3 on 2026-09-06).
    func testTheBottomClearanceClearsTheWholeBottomFurniture() {
        XCTAssertEqual(
            CaptureDiscMetrics.bottomClearance,
            AppSearchRowMetrics.bottomFurnitureLift + CaptureDiscMetrics.discDiameter + 8,
            accuracy: 0.001,
            "The bottom clearance no longer derives from the furniture it exists to clear — the"
                + " lift (gap + bar) plus the disc plus 8. A typed number here is how the content"
                + " floor drifted into the disc the first time."
        )
    }

    /// The trailing axis keeps E's settled geometry untouched: margin + disc + 8 = 92. It is a
    /// DIFFERENT measurement from the bottom one now — the bar band sits under the disc, not
    /// beside it — so the two must never collapse into one number again.
    func testTheTrailingClearanceKeepsTheSettledTrailingGeometry() {
        XCTAssertEqual(
            CaptureDiscMetrics.clearance,
            CaptureDiscMetrics.edgeMargin + CaptureDiscMetrics.discDiameter + 8,
            accuracy: 0.001,
            "The trailing clearance moved off E's settled disc geometry (24 + 60 + 8)."
        )
    }

    /// The difference between the two axes IS the bar band. Under `TabView` this was zero —
    /// the system reserved the band — which is exactly how one number served both axes and
    /// exactly why it stopped being true when the custom bar shipped reserving nothing.
    func testTheAxesDifferByExactlyTheBarBand() {
        XCTAssertEqual(
            CaptureDiscMetrics.bottomClearance - CaptureDiscMetrics.clearance,
            AppSearchRowMetrics.bottomFurnitureLift - CaptureDiscMetrics.edgeMargin,
            accuracy: 0.001,
            "The bottom and trailing clearances no longer differ by the bottom furniture the"
                + " trailing axis never meets — one of the derivations has been retyped."
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
