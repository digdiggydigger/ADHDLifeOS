//
//  TagDedupTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class TagDedupTests: XCTestCase {

    func testMatchExisting_exactMatch_returnsExistingTag() {
        let urgent = Tag(id: UUID(), name: "urgent")
        let tags = [urgent, Tag(id: UUID(), name: "home")]

        let result = TagDedup.matchExisting(tags: tags, name: "urgent")

        XCTAssertEqual(result, urgent)
    }

    func testMatchExisting_noMatch_returnsNil() {
        let tags = [Tag(id: UUID(), name: "urgent")]

        let result = TagDedup.matchExisting(tags: tags, name: "home")

        XCTAssertNil(result)
    }

    func testMatchExisting_isCaseSensitive() {
        let tags = [Tag(id: UUID(), name: "Urgent")]

        let result = TagDedup.matchExisting(tags: tags, name: "urgent")

        XCTAssertNil(result)
    }

    func testMatchExisting_emptyTagList_returnsNil() {
        let result = TagDedup.matchExisting(tags: [], name: "urgent")

        XCTAssertNil(result)
    }
}
