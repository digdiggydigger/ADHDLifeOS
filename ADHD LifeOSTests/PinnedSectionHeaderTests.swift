//
//  PinnedSectionHeaderTests.swift
//  ADHDLifeOSTests
//
//  The one pinned-header treatment (F-Tools-4-Headers).
//
//  E's complaint was that a pinned header "reads unfinished", and the measurement said why. On
//  the iPhone 17 render, a row through the pinned header and a row through the card beneath it
//  gave:
//
//      header  x 16.0 → 386.0pt   #F9F9F9   (`.bar`)
//      card    x 16.0 → 386.0pt   #FFFFFF   (`CardSurface`, 16pt continuous corners)
//      page                       #F0F3F6   (`PageBackground`)
//
//  So the strip was a THIRD surface — neither page nor card — spanning the card's exact width
//  with SQUARE corners, sitting directly on a 16pt-rounded card. Nine units off the page is far
//  too little to read as a deliberate surface and far too much to disappear, which is precisely
//  what "unfinished" looks like.
//
//  The fix is subtraction, not more chrome: paint the header the PAGE. It is still opaque (rows
//  cannot show through the letters), it is still pinned, and the rectangle stops existing because
//  its fill and the 16pt gutters either side of it are now the same colour.
//

import XCTest
import UIKit
@testable import ADHD_LifeOS

final class PinnedSectionHeaderTests: XCTestCase {

    /// **The whole decision, in one assertion.** A pinned header is opaque because it must be —
    /// rows slide under it and would otherwise show through the letters — and the surface it is
    /// opaque IN is the page, not a bar material and not the card.
    func testTheHeaderSurfaceIsThePageAndNotAThirdSurface() {
        XCTAssertEqual(
            PinnedHeaderMetrics.surfaceAssetName, "PageBackground",
            "The pinned header stopped being page-coloured. Any other fill re-creates the strip"
                + " E called unfinished: a rectangle with square corners over a 16pt-rounded"
                + " card, visible only because it disagrees with the page around it."
        )
        for wrong in ["CardSurface", "CardSurfaceSecondary", "BarSurface"] {
            XCTAssertNotEqual(
                PinnedHeaderMetrics.surfaceAssetName, wrong,
                "\(wrong) would make the header a surface of its own again."
            )
        }
    }

    func testTheHeaderSurfaceTokenExistsInTheAssetCatalog() {
        let bundle = Bundle(for: ADHD_LifeOS.FirebaseManager.self)
        XCTAssertNotNil(
            UIColor(named: PinnedHeaderMetrics.surfaceAssetName, in: bundle, compatibleWith: nil),
            "Colorset '\(PinnedHeaderMetrics.surfaceAssetName)' is missing from the asset"
                + " catalog, so the header would fall back to clear and let rows show through"
                + " its letters."
        )
    }

    /// **The claim both call sites made in prose and nothing ever checked.** Each said the header
    /// is "opaque on purpose", because rows slide beneath it and a transparent one lets their
    /// text show through the letters — while wearing `.bar`, a MATERIAL, which blurs what is
    /// behind it rather than hiding it. Sampling the pinned header's band to the right of the
    /// label, where no header text exists, gave 43-59 distinct colour bands before the fix and
    /// exactly one after. A comment is not a guard; this is.
    func testTheHeaderSurfaceIsFullyOpaque() throws {
        let bundle = Bundle(for: ADHD_LifeOS.FirebaseManager.self)
        let surface = try XCTUnwrap(
            UIColor(named: PinnedHeaderMetrics.surfaceAssetName, in: bundle, compatibleWith: nil)
        )
        for style in [UIUserInterfaceStyle.light, .dark] {
            let resolved = surface.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            var alpha: CGFloat = 0
            resolved.getRed(nil, green: nil, blue: nil, alpha: &alpha)
            XCTAssertEqual(
                alpha, 1, accuracy: 0.001,
                "The pinned header's surface is translucent in \(style == .light ? "light" : "dark")."
                    + " Rows slide UNDER a pinned header — anything short of opaque lets their"
                    + " text read through its letters, which is the defect `.bar` shipped."
            )
        }
    }

    /// §2's 4/8/16/24 grid. The header's vertical padding is spacing, not a component dimension,
    /// so unlike `AppTabBarMetrics.rowHeight` the grid does govern it.
    func testTheVerticalPaddingIsOnTheSpacingGrid() {
        XCTAssertTrue(
            [4, 8, 16, 24].contains(Int(PinnedHeaderMetrics.verticalPadding)),
            "\(PinnedHeaderMetrics.verticalPadding) is not on CLAUDE.md §2's 4/8/16/24 grid."
        )
    }

    /// The letters need room from the card that stops beneath them, but a pinned header eats
    /// scroll height on every screen that has one — so it is the smaller of the usable gaps.
    func testTheHeaderStaysTighterThanAGroupSeparation() {
        XCTAssertLessThan(
            PinnedHeaderMetrics.verticalPadding * 2, 24,
            "The pinned header now costs more vertical space than §2's macro group separation."
                + " It is chrome that rides above content on every scroll — it should not."
        )
    }
}
