//
//  TabRootReTapPlanTests.swift
//  ADHD LifeOSTests
//
//  `F-JournalPencilDisc`'s re-tap fix, the pure half (§7.4: which path is a pure function, tested
//  once). Step 0 measured the bug on 26.5 and 27.0: after scrolling, the shipped
//  `proxy.scrollTo(anchor: .top)` lands the content at the top of a COLLAPSED bar — 54pt, offset
//  −116 — and the large title never comes back. A UIKit offset to the expanded top restores it
//  (106pt, −168), and an overscroll written with no finger down comes to rest at that top by
//  itself, so the fix FINDS it (the band grows with Dynamic Type) and this function decides.
//
//  Offsets are `contentOffset.y`: more negative is further UP.
//

import CoreGraphics
import XCTest
@testable import ADHD_LifeOS

@MainActor
final class TabRootReTapPlanTests: XCTestCase {

    /// Step 0's own numbers: scrolled, the plain top is −116 (the collapsed bar); the probe finds
    /// −168 (the large title's). With motion, UIKit's own animated scroll-to-top — the status-bar
    /// tap's, proved by Step 0's R3.
    func testAPageWhoseLargeTitleCollapsedAnimatesToTheExpandedTop() {
        XCTAssertEqual(
            TabRootReTapPlan.plan(plainTop: -116, expandedTop: -168, reduceMotion: false),
            .animate(toTop: -168)
        )
    }

    /// Reduce Motion: straight there. A scroll to the top is re-positioning, not an appearance —
    /// the shipped re-tap was already instant under Reduce Motion (`withAnimation(nil)`).
    func testUnderReduceMotionItJumpsToTheExpandedTop() {
        XCTAssertEqual(
            TabRootReTapPlan.plan(plainTop: -116, expandedTop: -168, reduceMotion: true),
            .jump(toTop: -168)
        )
    }

    /// The point of FINDING the top: a bigger Dynamic Type title band is a bigger number, and the
    /// plan takes whatever the probe found rather than a hard-coded 52pt.
    func testTheExpandedTopIsWhateverTheProbeFoundNotAFixedBand() {
        XCTAssertEqual(
            TabRootReTapPlan.plan(plainTop: -116, expandedTop: -212.5, reduceMotion: false),
            .animate(toTop: -212.5)
        )
    }

    /// Every tab but the Journal, and the Journal already expanded: nothing above the plain top, so
    /// the shipped `proxy.scrollTo` runs untouched — both paths, because the reduced one is a
    /// different branch of the same function.
    func testNothingAboveThePlainTopLeavesTheShippedScrollInCharge() {
        for reduceMotion in [false, true] {
            XCTAssertEqual(
                TabRootReTapPlan.plan(plainTop: -62, expandedTop: -62, reduceMotion: reduceMotion),
                .scrollToAnchor,
                "A hidden-bar tab is handed to the fix (reduceMotion: \(reduceMotion))."
            )
            XCTAssertEqual(
                TabRootReTapPlan.plan(plainTop: -168, expandedTop: -168, reduceMotion: reduceMotion),
                .scrollToAnchor,
                "An already-expanded title is re-driven by UIKit (reduceMotion: \(reduceMotion))."
            )
        }
    }

    /// Layout rounds. Half a point is a pixel at 2×, not a large title — a sub-point difference
    /// must not take a hidden-bar tab off its shipped path.
    func testASubPointDifferenceIsNotALargeTitle() {
        XCTAssertEqual(
            TabRootReTapPlan.plan(plainTop: -116, expandedTop: -116.33, reduceMotion: false),
            .scrollToAnchor
        )
    }

    /// Cannot happen — the probe only ever overscrolls UP — but if a bar ever shrank under the
    /// probe, the fix must not scroll DOWN to it.
    func testAProbeThatFindsATopBelowThePlainOneIsIgnored() {
        XCTAssertEqual(
            TabRootReTapPlan.plan(plainTop: -168, expandedTop: -116, reduceMotion: false),
            .scrollToAnchor
        )
    }
}
