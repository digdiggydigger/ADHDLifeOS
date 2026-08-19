//
//  TaskFocusFieldsCodingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The per-task focus config (`focus_duration_seconds`, `nudges_count`) is new to the schema, so
/// every task document already in Firestore lacks it — decoding must treat the absent fields as
/// `nil` rather than failing, and encoding must use the snake_case keys the schema convention
/// (and the web prototype's camelCase equivalents) prescribe.
final class TaskFocusFieldsCodingTests: XCTestCase {
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    func testTaskItemDecoding_absentFocusFields_decodeAsNil() throws {
        let json = Data("""
        {"id": "\(UUID().uuidString)", "title": "Legacy task", "status": "open", "priority": "p2"}
        """.utf8)

        let task = try decoder.decode(TaskItem.self, from: json)

        XCTAssertNil(task.focusDurationSeconds)
        XCTAssertNil(task.nudgesCount)
    }

    func testTaskItemDecoding_readsFocusFields() throws {
        let json = Data("""
        {"id": "\(UUID().uuidString)", "title": "Tuned task", "status": "open", "priority": "p1",
         "focus_duration_seconds": 300, "nudges_count": 3}
        """.utf8)

        let task = try decoder.decode(TaskItem.self, from: json)

        XCTAssertEqual(task.focusDurationSeconds, 300)
        XCTAssertEqual(task.nudgesCount, 3)
    }

    func testTaskDetailDecoding_readsFocusFields_andToleratesTheirAbsence() throws {
        let base = """
        {"id": "\(UUID().uuidString)", "title": "Detail task", "status": "open", "priority": "p3",
         "created_at": 1700000000
        """
        let withFields = Data((base + ", \"focus_duration_seconds\": 120, \"nudges_count\": 0}").utf8)
        let withoutFields = Data((base + "}").utf8)

        let tuned = try decoder.decode(TaskDetail.self, from: withFields)
        let legacy = try decoder.decode(TaskDetail.self, from: withoutFields)

        XCTAssertEqual(tuned.focusDurationSeconds, 120)
        XCTAssertEqual(tuned.nudgesCount, 0)
        XCTAssertNil(legacy.focusDurationSeconds)
        XCTAssertNil(legacy.nudgesCount)
    }

    func testTaskItemEncoding_usesSnakeCaseKeys_andOmitsNilFields() throws {
        let tuned = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Tuned", status: .open, priority: .p2,
            dueDate: nil, focusDurationSeconds: 600, nudgesCount: 4
        )
        let legacy = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Legacy", status: .open, priority: .p2, dueDate: nil
        )

        let tunedJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(tuned)) as? [String: Any]
        )
        let legacyJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as? [String: Any]
        )

        XCTAssertEqual(tunedJSON["focus_duration_seconds"] as? Int, 600)
        XCTAssertEqual(tunedJSON["nudges_count"] as? Int, 4)
        XCTAssertNil(legacyJSON["focus_duration_seconds"])
        XCTAssertNil(legacyJSON["nudges_count"])
    }
}
