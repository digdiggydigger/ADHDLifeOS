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
            try Self.rootViewSource().contains("CaptureDiscPanObserver.installOnKeyWindow"),
            "Nothing installs the window-level pan observer, so no drag anywhere can ever reach"
                + " the activity model — the disc never shrinks and F-DiscPill is dead code."
        )
    }

    func testRootViewReadsTheActivityModel() throws {
        XCTAssertTrue(
            try Self.rootViewSource().contains(".isScrolling"),
            "The disc never reads `isScrolling`, so the model can change all it likes and the"
                + " 60pt circle stays a 60pt circle over the content E reported."
        )
    }

    // MARK: - The geometry

    func testDiscSpellsItsSizeThroughTheMetrics() throws {
        // The 60pt diameter was inlined in RootView while `CaptureDiscMetrics.clearance` spelled
        // the SAME 60 as part of its sum — two spellings of one measurement, exactly the drift
        // the clearance tests exist to prevent. The disc now reads the metric.
        let source = try Self.rootViewSource()
        XCTAssertTrue(source.contains("CaptureDiscMetrics.discDiameter"))
        XCTAssertFalse(
            source.contains("width: 60"),
            "A literal 60pt frame is back in RootView. The disc's size and the clearance must"
                + " move together — spell it via `CaptureDiscMetrics.discDiameter`."
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
        // test and fix nothing.
        XCTAssertLessThan(CaptureDiscMetrics.pillWidth, CaptureDiscMetrics.discDiameter)
        XCTAssertLessThan(CaptureDiscMetrics.pillHeight, CaptureDiscMetrics.discDiameter / 2)
        XCTAssertLessThan(CaptureDiscMetrics.pillGlyphScale, 1)
    }

    // MARK: - Reading the tree

    private static func rootViewSource() throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // ADHD LifeOSTests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("ADHD LifeOS/RootView.swift")
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
