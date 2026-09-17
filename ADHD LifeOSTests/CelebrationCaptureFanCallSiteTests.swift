//
//  CelebrationCaptureFanCallSiteTests.swift
//  ADHD LifeOSTests
//
//  `F-FanHoldsCelebration`'s reachability guards. A perfect `CelebrationCenter.captureChanged(isOpen:)`
//  that `RootView` never calls passes every assertion in `CelebrationCaptureFanHoldTests` and holds
//  nothing on the phone — this repo's most repeated defect (the dead shared component). So the
//  wiring is read from source.
//

import XCTest
@testable import ADHD_LifeOS

final class CelebrationCaptureFanCallSiteTests: XCTestCase {

    /// `RootView` owns the fan's state and the centre, and it is the one place that can join them.
    func testRootViewTellsTheCentreWhenTheCaptureFlowOpensAndCloses() throws {
        XCTAssertTrue(
            try Self.flattened("RootView.swift").contains(
                ".onChange(of: capturesHoldCelebrations) { celebrationCenter.captureChanged(isOpen: $0) }"
            ),
            "Nothing tells the centre the capture fan is open, so a celebration still plays over it."
        )
    }

    /// **The composer gap.** Picking a tile sets `isFabOpen = false` and `composerKind` in one
    /// update, and UIKit presents the composer a run loop or two later — so a flag fed by
    /// `isFabOpen` alone would read clear in between, and the hold watch could release a
    /// celebration under the composer as it rises. Feeding the OR keeps the capture flow "open"
    /// straight into the composer; the probe sees the composer from there.
    func testTheCaptureFlowStaysOpenFromTheFanIntoItsComposer() throws {
        XCTAssertTrue(
            try Self.flattened("RootView+Furniture.swift").contains(
                "var capturesHoldCelebrations: Bool { isFabOpen || composerKind != nil }"
            ),
            "The flag is not the fan OR its composer, so a held celebration can slip out as a tile"
                + " opens the composer."
        )
    }

    /// The fan joins the ONE predicate behind both the hold and the release, from the root surface
    /// only, beside the probe — so the hold and the release can never disagree about it.
    func testTheFanJoinsTheOnePredicateBesideTheProbe() throws {
        XCTAssertTrue(
            try Self.flattened("Celebrations/CelebrationCenter.swift").contains(
                "guard frontmost == .root else { return false } return captureIsOpen || probe.isAnythingPresented"
            ),
            "The fan is not part of `isBlocked`, or it is read off the root surface."
        )
    }

    // MARK: - Source

    private static func flattened(_ relativePath: String) throws -> String {
        try appCode(relativePath)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func appCode(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("ADHD LifeOS")
            .appendingPathComponent(relativePath)
        let text = try String(contentsOf: url, encoding: .utf8)
        return text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            .joined(separator: "\n")
    }
}
