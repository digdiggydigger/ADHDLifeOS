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

    /// Tags ride BOTH types (E's 2026-08-25 note: "journal and logs") — unlike energy/mood,
    /// which stay journal-only.
    func testCreate_passesTagsThroughForBothTypes() {
        let tagIds = [UUID(), UUID()]
        for type in LogType.allCases {
            let result = LogValidation.normalizeCreateLogInput(
                body: "Tagged", type: type, lifeAreaId: nil, tagIds: tagIds
            )
            guard case .success(let normalized) = result else {
                return XCTFail("Expected success for \(type)")
            }
            XCTAssertEqual(normalized.tagIds, tagIds, "tags must survive a \(type) entry")
        }
    }

    func testCreate_defaultsToNoTags() {
        let result = LogValidation.normalizeCreateLogInput(body: "Plain", type: .log, lifeAreaId: nil)

        guard case .success(let normalized) = result else {
            return XCTFail("Expected success")
        }
        XCTAssertEqual(normalized.tagIds, [])
    }
}
