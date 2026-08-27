//
//  LogTagIdsCodingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Journal entries carry their tags ON the log document as `tag_ids` (E's 2026-08-25 note) —
/// written once at CREATE, because `firestore.rules` denies update on logs (append-only). The
/// field must survive the REAL Firestore codec, including `Log`'s hand-written decoder: a
/// synthesized-looking test through JSONDecoder would not catch that decoder skipping the field.
final class LogTagIdsCodingTests: XCTestCase {
    private func log(tagIds: [UUID]? = nil) -> Log {
        Log(
            id: UUID(), lifeAreaId: nil, type: .journal, body: "entry",
            entryDate: Date(timeIntervalSince1970: 1_700_000_000),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            tagIds: tagIds
        )
    }

    func testLog_roundTripsTagIdsThroughTheFirestoreCoder() throws {
        let tagIds = [UUID(), UUID()]
        let fields = try FirestoreDocumentCoder.encode(log(tagIds: tagIds))

        XCTAssertEqual(
            fields["tag_ids"] as? [String], tagIds.map(\.uuidString),
            "snake_case like every other log field, UPPERCASE uuidStrings like every membership"
        )
        XCTAssertNil(fields["tagIds"])

        let decoded = try FirestoreDocumentCoder.decode(Log.self, from: fields)
        XCTAssertEqual(decoded.tagIds, tagIds)
    }

    func testLog_nilMembershipEncodesAsAbsent() throws {
        let fields = try FirestoreDocumentCoder.encode(log())
        XCTAssertNil(fields["tag_ids"], "an untagged entry writes no empty array")

        let decoded = try FirestoreDocumentCoder.decode(Log.self, from: fields)
        XCTAssertNil(decoded.tagIds)
    }

    func testLog_decodesADocumentWrittenBeforeTheFieldExisted() throws {
        var fields = try FirestoreDocumentCoder.encode(log(tagIds: [UUID()]))
        fields.removeValue(forKey: "tag_ids")

        let decoded = try FirestoreDocumentCoder.decode(Log.self, from: fields)
        XCTAssertNil(decoded.tagIds)
    }
}
