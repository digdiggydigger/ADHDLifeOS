//
//  CaptureTagIdsCodingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Tag membership lives as a `tag_ids` string array ON the capture document, written only by
/// `arrayUnion`/`arrayRemove` (`FirebaseManager+Tags`) — and the inbox now reads it straight off
/// the decoded `Capture`, so it must survive the REAL Firestore codec spelled exactly as those
/// writes spell it: snake_case key, UPPERCASE uuidStrings.
final class CaptureTagIdsCodingTests: XCTestCase {
    func testCapture_roundTripsTagIdsThroughTheFirestoreCoder() throws {
        let tagIds = [UUID(), UUID()]
        let capture = Capture(
            id: UUID(), content: "buy stamps", kind: .note, processed: false,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            tagIds: tagIds
        )

        let fields = try FirestoreDocumentCoder.encode(capture)
        XCTAssertEqual(
            fields["tag_ids"] as? [String], tagIds.map(\.uuidString),
            "the membership array is snake_case and stores UPPERCASE uuidStrings"
        )
        XCTAssertNil(fields["tagIds"], "captures are camelCase APART from the snake_case exceptions")

        let decoded = try FirestoreDocumentCoder.decode(Capture.self, from: fields)
        XCTAssertEqual(decoded.tagIds, tagIds)
    }

    /// Exactly what `addTagId` leaves on the wire: a bare `[String]` of uppercase uuidStrings,
    /// never touched by this model's encoder.
    func testCapture_decodesTheArrayUnionSpelling() throws {
        let tagId = UUID()
        let capture = Capture(
            id: UUID(), content: "call the dentist", kind: .task, processed: false,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        var fields = try FirestoreDocumentCoder.encode(capture)
        fields["tag_ids"] = [tagId.uuidString]

        let decoded = try FirestoreDocumentCoder.decode(Capture.self, from: fields)
        XCTAssertEqual(decoded.tagIds, [tagId])
    }

    func testCapture_decodesADocumentWithoutTheField() throws {
        let capture = Capture(
            id: UUID(), content: "untagged", kind: .note, processed: false,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let fields = try FirestoreDocumentCoder.encode(capture)
        XCTAssertNil(
            fields["tag_ids"],
            "a nil membership must encode as ABSENT — a create writing [] would be wrong once arrayUnion runs"
        )

        let decoded = try FirestoreDocumentCoder.decode(Capture.self, from: fields)
        XCTAssertNil(decoded.tagIds)
    }
}
