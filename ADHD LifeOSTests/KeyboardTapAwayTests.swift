//
//  KeyboardTapAwayTests.swift
//  ADHD LifeOSTests
//

import UIKit
import XCTest
@testable import ADHD_LifeOS

/// b5, round two (E's pick, 2026-08-26): tapping anywhere that isn't a text input dismisses the
/// keyboard, via one window-level recognizer. The recognizer must IGNORE taps that land inside a
/// text input — otherwise tapping a field would resign the very keyboard the tap is summoning —
/// and that judgement is this walk: is the touched view, or any ancestor, an editable text view?
final class KeyboardTapAwayTests: XCTestCase {
    func testTextFieldAndTextView_areTextInput() {
        XCTAssertTrue(KeyboardTapAway.isInsideTextInput(UITextField()))
        XCTAssertTrue(KeyboardTapAway.isInsideTextInput(UITextView()))
    }

    /// SwiftUI's fields are UIKit-backed, but a touch often lands on a private SUBVIEW of the
    /// backing UITextField/UITextView — the walk must climb to the ancestor.
    func testSubviewInsideATextInput_countsAsTextInput() {
        let field = UITextField()
        let inner = UIView()
        field.addSubview(inner)
        XCTAssertTrue(KeyboardTapAway.isInsideTextInput(inner))
    }

    func testPlainViewInAPlainHierarchy_isNotTextInput() {
        let container = UIView()
        let child = UIView()
        container.addSubview(child)
        XCTAssertFalse(KeyboardTapAway.isInsideTextInput(child))
    }

    /// A view that merely CONTAINS a text field (a form row wrapping one) is not itself inside a
    /// text input — the walk goes up, never down, or tapping anywhere near a field would be
    /// swallowed and the tap-away gesture would never fire on form screens.
    func testAncestorOfATextInput_isNotItselfTextInput() {
        let row = UIView()
        row.addSubview(UITextField())
        XCTAssertFalse(KeyboardTapAway.isInsideTextInput(row))
    }
}
