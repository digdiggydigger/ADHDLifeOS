//
//  TaskComposerLayoutTests.swift
//  ADHD LifeOSTests
//
//  `F-D2-ComposerKeyboardLayout`: the rule that picks the composer's layout, and the numbers E
//  approved by looking at round 7b's board `64`.
//

import SwiftUI
import XCTest
@testable import ADHD_LifeOS

final class TaskComposerLayoutTests: XCTestCase {

    /// **L3 up to the largest ordinary size; L1's stacked form at every accessibility size.** The
    /// design record, carried in the option E chose: *"At AX3 the bar cannot share the screen with
    /// the keyboard ... At accessibility sizes the build uses L1's stacked form instead."*
    func testTheStackedFormIsForAccessibilitySizesOnly() {
        for size in [DynamicTypeSize.xSmall, .large, .xxxLarge] {
            XCTAssertFalse(TaskCreateView.usesStackedForm(at: size), "\(size) should ride the keyboard")
        }
        for size in [DynamicTypeSize.accessibility1, .accessibility3, .accessibility5] {
            XCTAssertTrue(TaskCreateView.usesStackedForm(at: size), "\(size) should stack")
        }
    }

    /// Round 7: *"the composer's own chips stay 48"* — the segments and Add. The menu tiles are the
    /// probe's 56, which is what put "Area / None" on two lines inside a 48pt-class target.
    func testTheComposersOwnControlsKeepRound7sTargets() {
        XCTAssertEqual(TaskComposerMetrics.segmentHeight, 48)
        XCTAssertEqual(TaskComposerMetrics.addHeight, 48)
        XCTAssertEqual(ComposerMenuTile.minHeight, 56)
    }

    /// **A tile's words shrink before they clip, but never below legible.** At xxxLarge the compact
    /// third is ~123pt and "15 min" truncated to "15…" at a 0.8 floor (F-D2's XXXL render). A single
    /// 0.7 floor would let a long area name reach 10.5pt at the DEFAULT size, under the HIG's 11pt
    /// minimum (`typography.md`), so the floor drops only where the text is already large.
    func testTheTileTextShrinksFurtherOnlyAtLargeSizes() {
        for size in [DynamicTypeSize.xSmall, .large, .xLarge] {
            XCTAssertEqual(ComposerMenuTile.scaleFloor(at: size), 0.8, "\(size)")
        }
        for size in [DynamicTypeSize.xxLarge, .xxxLarge, .accessibility3] {
            XCTAssertEqual(ComposerMenuTile.scaleFloor(at: size), 0.7, "\(size)")
        }
    }

    /// **Concentric corners.** The bar's container wraps 16pt-radius controls at an 8pt inset, so
    /// its own radius is their sum — any other value draws a corner whose curve does not follow the
    /// controls inside it.
    func testTheBarsCornerIsConcentricWithTheControlsInsideIt() {
        XCTAssertEqual(
            TaskComposerMetrics.barCornerRadius,
            TaskComposerMetrics.controlCornerRadius + TaskComposerMetrics.barPadding
        )
        XCTAssertEqual(TaskComposerMetrics.controlCornerRadius, 16)
        XCTAssertEqual(TaskComposerMetrics.barPadding, 8)
    }
}
