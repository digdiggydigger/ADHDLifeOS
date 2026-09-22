//
//  TagEditorPresentationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class TagEditorPresentationTests: XCTestCase {

    // MARK: usagePhrase — zero / singular / plural is a real branch

    func test_usagePhrase_zero() {
        XCTAssertEqual(TagEditorPresentation.usagePhrase(count: 0), "Not used yet")
    }

    func test_usagePhrase_one_isSingular() {
        XCTAssertEqual(TagEditorPresentation.usagePhrase(count: 1), "Used on 1 item")
    }

    func test_usagePhrase_many_isPlural() {
        XCTAssertEqual(TagEditorPresentation.usagePhrase(count: 2), "Used on 2 items")
        XCTAssertEqual(TagEditorPresentation.usagePhrase(count: 12), "Used on 12 items")
    }

    // MARK: rowIdentifier

    func test_rowIdentifier_isTagRowPlusLowercasedUUID() {
        let id = UUID(uuidString: "0A749149-4E10-44D7-8728-E0212720950D")!
        XCTAssertEqual(
            TagEditorPresentation.rowIdentifier(for: id),
            "tagRow_0a749149-4e10-44d7-8728-e0212720950d"
        )
    }

    // MARK: merge alert

    func test_mergeAlertTitle_namesConflictingTag() {
        XCTAssertEqual(TagEditorPresentation.mergeAlertTitle(conflictingName: "errands"), "“errands” already exists")
    }

    func test_mergeAlertMessage_zeroOneMany() {
        XCTAssertEqual(
            TagEditorPresentation.mergeAlertMessage(survivorName: "errands", survivorUsageCount: 0),
            "“errands” isn't used yet. Merge this tag into it? This can't be undone."
        )
        XCTAssertEqual(
            TagEditorPresentation.mergeAlertMessage(survivorName: "errands", survivorUsageCount: 1),
            "“errands” is used on 1 item. Merge this tag into it? This can't be undone."
        )
        XCTAssertEqual(
            TagEditorPresentation.mergeAlertMessage(survivorName: "errands", survivorUsageCount: 12),
            "“errands” is used on 12 items. Merge this tag into it? This can't be undone."
        )
    }
}
