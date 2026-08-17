//
//  LifeAreaModelTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Covers the `archived` field added to the shared `LifeArea` in the Home-reorder block: decoding
/// must treat `true`/`false`/absent correctly (the nine seeded rows predate the field), and the
/// memberwise init must keep defaulting it to `false` so the many manual construction sites compile.
final class LifeAreaModelTests: XCTestCase {

    private func decode(archived: String) throws -> LifeArea {
        let json = #"{"id":"\#(UUID().uuidString)","name":"Work","colour":"💼","sort_order":1\#(archived)}"#
        return try JSONDecoder().decode(LifeArea.self, from: Data(json.utf8))
    }

    func testDecode_archivedTrue() throws {
        XCTAssertTrue(try decode(archived: #","archived":true"#).archived)
    }

    func testDecode_archivedFalse() throws {
        XCTAssertFalse(try decode(archived: #","archived":false"#).archived)
    }

    func testDecode_absentArchived_isFalse() throws {
        // The nine seeded rows have no `archived` key — a missing field must read as not-archived.
        XCTAssertFalse(try decode(archived: "").archived)
    }

    func testMemberwiseInit_defaultsArchivedToFalse() {
        let area = LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 1)
        XCTAssertFalse(area.archived)
    }
}
