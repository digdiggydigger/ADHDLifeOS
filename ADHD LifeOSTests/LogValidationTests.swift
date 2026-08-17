//
//  LogValidationTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

final class LogValidationTests: XCTestCase {

    func testCreate_trimsBody() {
        let result = LogValidation.normalizeCreateLogInput(body: "  Went for a walk  ", type: .log, lifeAreaId: nil)

        guard case .success(let normalized) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(normalized.body, "Went for a walk")
    }

    func testCreate_emptyBody_isRejected() {
        let result = LogValidation.normalizeCreateLogInput(body: "   ", type: .log, lifeAreaId: nil)

        XCTAssertEqual(result, .failure(.emptyBody))
    }

    func testCreate_passesThroughTypeAndLifeAreaId() {
        let lifeAreaId = UUID()

        let result = LogValidation.normalizeCreateLogInput(body: "Reflection", type: .journal, lifeAreaId: lifeAreaId)

        guard case .success(let normalized) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(normalized.type, .journal)
        XCTAssertEqual(normalized.lifeAreaId, lifeAreaId)
    }

    func testCreate_omittedLifeAreaId_isNil() {
        let result = LogValidation.normalizeCreateLogInput(body: "Quick note", type: .log, lifeAreaId: nil)

        guard case .success(let normalized) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertNil(normalized.lifeAreaId)
    }
}
