//
//  LifeAreaPickerTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The picker's one piece of real logic: an archived row is disabled EXCEPT when it is the current
/// selection (so a task/log already holding an archived area never renders blank).
final class LifeAreaPickerTests: XCTestCase {

    private func area(archived: Bool) -> LifeArea {
        LifeArea(id: UUID(), name: "X", colour: "🎯", sortOrder: 0, archived: archived)
    }

    func testArchivedRow_notSelected_isDisabled() {
        XCTAssertTrue(LifeAreaPicker.isRowDisabled(area: area(archived: true), isSelected: false))
    }

    func testArchivedRow_isCurrentSelection_isEnabled() {
        XCTAssertFalse(LifeAreaPicker.isRowDisabled(area: area(archived: true), isSelected: true))
    }

    func testActiveRow_isNeverDisabled() {
        XCTAssertFalse(LifeAreaPicker.isRowDisabled(area: area(archived: false), isSelected: false))
        XCTAssertFalse(LifeAreaPicker.isRowDisabled(area: area(archived: false), isSelected: true))
    }
}
