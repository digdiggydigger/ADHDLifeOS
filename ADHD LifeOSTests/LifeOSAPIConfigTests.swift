//
//  LifeOSAPIConfigTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class LifeOSAPIConfigTests: XCTestCase {

    func testLowercaseUUIDString_uppercaseInput_returnsLowercase() {
        let uuid = UUID(uuidString: "1C4C7551-3F3C-4E2F-B02D-E6095BE570C6")!

        XCTAssertEqual(uuid.lowercaseUUIDString, "1c4c7551-3f3c-4e2f-b02d-e6095be570c6")
    }

    func testLowercaseUUIDString_lowercaseInput_isIdempotent() {
        let uuid = UUID(uuidString: "1c4c7551-3f3c-4e2f-b02d-e6095be570c6")!

        XCTAssertEqual(uuid.lowercaseUUIDString, "1c4c7551-3f3c-4e2f-b02d-e6095be570c6")
    }
}
