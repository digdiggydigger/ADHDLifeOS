//
//  CollapsibleSectionTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The shared collapse affordance (E, 2026-08-28: "a little down and upwards arrow to represent
/// the states of collapsed or uncollapsed"), used by the Journal's day sections and Today's
/// life-area list.
///
/// The glyph choice lives in ONE place on purpose. Two screens each picking their own chevron is
/// how an app ends up with a control that means "open" in one place and "close" in another, and
/// the direction is precisely the sort of thing worth being able to flip in a single line after
/// seeing it on a real screen.
final class CollapsibleSectionTests: XCTestCase {

    /// The arrow points AT the content: expanded points down at the rows below it, collapsed
    /// points up at the header that swallowed them. E's call after seeing both, 2026-08-28 —
    /// the first cut pointed at the gesture instead and was flipped.
    func testChevron_pointsAtTheContentNotTheGesture() {
        XCTAssertEqual(CollapsibleSection.chevron(isExpanded: true), "chevron.down")
        XCTAssertEqual(CollapsibleSection.chevron(isExpanded: false), "chevron.up")
    }

    /// VoiceOver must be told the state, because the glyph carries it and §4 forbids meaning
    /// living in a glyph alone.
    func testAccessibilityHint_namesBothTheStateAndTheAction() {
        XCTAssertEqual(CollapsibleSection.hint(isExpanded: true), "Expanded. Double tap to collapse.")
        XCTAssertEqual(CollapsibleSection.hint(isExpanded: false), "Collapsed. Double tap to expand.")
    }
}
