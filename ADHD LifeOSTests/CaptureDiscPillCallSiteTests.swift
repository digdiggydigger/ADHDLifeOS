//
//  CaptureDiscPillCallSiteTests.swift
//  ADHD LifeOSTests
//
//  F-DiscPill's reachability guards, in the `CaptureDiscClearanceCallSiteTests` mould and for
//  the same reason: this repo's most repeated defect (six instances) is a helper that is
//  written, documented and unit-tested while no view actually uses it. A correct
//  `CaptureDiscScrollActivity` that RootView never installs or reads would pass every test in
//  its own file and shrink nothing. Tests prove correctness, never reachability — except these,
//  which read the source, the layer the wiring claim actually lives in.
//

import XCTest
@testable import ADHD_LifeOS

final class CaptureDiscPillCallSiteTests: XCTestCase {

    // MARK: - The wiring

    func testRootViewInstallsThePanObserver() throws {
        XCTAssertTrue(
            try Self.appSource("RootView.swift").contains("CaptureDiscPanObserver.installOnKeyWindow"),
            "Nothing installs the window-level pan observer, so no drag anywhere can ever reach"
                + " the activity model — the disc never shrinks and F-DiscPill is dead code."
        )
    }

    func testRootViewReadsTheActivityModel() throws {
        XCTAssertTrue(
            try Self.appSource("RootView.swift").contains(".isScrolling"),
            "The disc never reads `isScrolling`, so the model can change all it likes and the"
                + " 60pt circle stays a 60pt circle over the content E reported."
        )
    }

    func testRootViewRendersTheDiscLabel() throws {
        // The face lives in its own file (Theme/CaptureDiscLabel.swift, the 400-line split), so
        // the chain observer → model → `showsPill` → label needs this link asserted too — a
        // label nobody renders is the dead-component shape all over again.
        XCTAssertTrue(
            try Self.appSource("RootView.swift").contains("CaptureDiscLabel("),
            "RootView no longer renders `CaptureDiscLabel`, so the morphing face is dead code"
                + " and whatever replaced it is outside every guard in this file."
        )
    }

    // MARK: - The geometry

    func testDiscSpellsItsSizeThroughTheMetrics() throws {
        // The 60pt diameter was inlined beside `CaptureDiscMetrics.clearance`, which spelled
        // the SAME 60 as part of its sum — two spellings of one measurement, exactly the drift
        // the clearance tests exist to prevent. The disc's face now reads the metric.
        let source = try Self.appSource("Theme/CaptureDiscLabel.swift")
        XCTAssertTrue(source.contains("CaptureDiscMetrics.discDiameter"))
        XCTAssertFalse(
            source.contains("width: 60"),
            "A literal 60pt frame is back in the disc's face. The disc's size and the clearance"
                + " must move together — spell it via `CaptureDiscMetrics.discDiameter`."
        )
    }

    func testClearanceIsStillTheFullDiscPlusMargins() {
        // The pill is a MID-SCROLL state; at rest the disc is still the full 60pt, and the last
        // row of every scroll still has to clear it. Eleven call sites depend on this number —
        // if it changes, it must change because the REST geometry changed, not the pill's.
        XCTAssertEqual(CaptureDiscMetrics.clearance, 84)
        XCTAssertEqual(CaptureDiscMetrics.clearance, CaptureDiscMetrics.discDiameter + 16 + 8)
    }

    func testPillIsActuallySmallerThanTheDisc() {
        // The entire point of the block. A "pill" the disc's own size would pass every wiring
        // test and fix nothing. Height was originally bounded at HALF the diameter; E's device
        // verdict (F-PillTune: "the pill button is too small") raised the pill to 52×32, so the
        // guard keeps only its real point — strictly smaller than the disc in both axes.
        XCTAssertLessThan(CaptureDiscMetrics.pillWidth, CaptureDiscMetrics.discDiameter)
        XCTAssertLessThan(CaptureDiscMetrics.pillHeight, CaptureDiscMetrics.discDiameter)
        XCTAssertLessThan(CaptureDiscMetrics.pillGlyphScale, 1)
    }

    func testPillOpacityStaysInTheReadableGlassBand() throws {
        // E's dial sits at 0.68 (device GIF, 2026-08-30). The bounds are the point, not the
        // number: at 1.0 the pill is opaque and the trailing corner swallows content again;
        // below 0.5 a blue control at two-thirds ghost reads as disabled, and the white glyph
        // starts failing against light backgrounds. Retune inside the band freely.
        XCTAssertLessThan(CaptureDiscMetrics.pillOpacity, 1)
        XCTAssertGreaterThanOrEqual(CaptureDiscMetrics.pillOpacity, 0.5)
        // One spelling: the label must read the metric, not carry its own inline alpha.
        XCTAssertTrue(
            try Self.appSource("Theme/CaptureDiscLabel.swift")
                .contains("CaptureDiscMetrics.pillOpacity"),
            "The disc face no longer reads `pillOpacity` — the metric and the rendered alpha"
                + " have come apart, and this test is guarding a number nothing uses."
        )
    }

    // MARK: - Reading the tree

    private static func appSource(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            throw PillSourceError.unreadable(url.path)
        }
        return text
    }

    /// Loud rather than skipped — a guard that quietly disables itself is the failure mode
    /// these tests exist to prevent.
    private enum PillSourceError: Error, CustomStringConvertible {
        case unreadable(String)

        var description: String {
            switch self {
            case .unreadable(let path):
                return "Could not read \(path). This test reads the tree it was compiled from"
                    + " (`#filePath`)."
            }
        }
    }
}
