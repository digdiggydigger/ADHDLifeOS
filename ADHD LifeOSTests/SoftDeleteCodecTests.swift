//
//  SoftDeleteCodecTests.swift
//  ADHD LifeOSTests
//
//  `F-C3-RecentlyDeleted`: the soft-delete stamp, on the wire.
//
//  **Why the spelling gets its own tests, and why they assert the WRONG one is ABSENT.** The two
//  collections disagree on purpose (CLAUDE.md: tasks are fully snake_cased, captures are camelCase
//  apart from their snake_case exceptions), and a wrong key raises nothing at all — it writes a
//  field nothing reads, so the item stays in every list and the delete silently does nothing.
//  `CaptureTagIdsCodingTests` is the pattern, `FirestoreDocumentCoder` the real codec seam.
//

import XCTest
@testable import ADHD_LifeOS

final class SoftDeleteCodecTests: XCTestCase {

    private static let stamp = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - Tasks — snake_case

    func testTaskItem_encodesTheStampAsDeletedAtSnakeCase() throws {
        let task = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Renew the passport", status: .open,
            priority: .p3, dueDate: nil, deletedAt: Self.stamp
        )
        let fields = try FirestoreDocumentCoder.encode(task)
        XCTAssertNotNil(fields["deleted_at"], "a task's stamp is snake_case, like every task field")
        XCTAssertNil(fields["deletedAt"], "the camelCase spelling belongs to captures, not tasks")

        let decoded = try FirestoreDocumentCoder.decode(TaskItem.self, from: fields)
        XCTAssertEqual(decoded.deletedAt, Self.stamp)
    }

    /// An absent key, never an explicit null. The spec's own trap is that a
    /// `whereField("deleted_at", isEqualTo: NSNull())` filter matches ONLY documents where the key
    /// is present and null — so writing nulls would split the collection into two shapes and make
    /// the wrong query look like it worked on new documents.
    func testTaskItem_omitsTheKeyEntirelyWhenLive() throws {
        let task = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Renew the passport", status: .open,
            priority: .p3, dueDate: nil
        )
        let fields = try FirestoreDocumentCoder.encode(task)
        XCTAssertNil(fields["deleted_at"])
    }

    /// Every task written before this block has no key at all, and must read as LIVE.
    func testTaskItem_decodesADocumentWrittenBeforeTheFieldExistedAsLive() throws {
        let task = TaskItem(
            id: UUID(), lifeAreaId: nil, title: "Renew the passport", status: .open,
            priority: .p3, dueDate: nil
        )
        var fields = try FirestoreDocumentCoder.encode(task)
        fields.removeValue(forKey: "deleted_at")

        let decoded = try FirestoreDocumentCoder.decode(TaskItem.self, from: fields)
        XCTAssertNil(decoded.deletedAt)
        XCTAssertTrue(SoftDelete.isLive(deletedAt: decoded.deletedAt))
    }

    // MARK: - Captures — camelCase

    func testCapture_encodesTheStampAsDeletedAtCamelCase() throws {
        var capture = Capture(
            id: UUID(), content: "Draft from the note composer", kind: .note,
            processed: false, createdAt: Self.stamp
        )
        capture.deletedAt = Self.stamp
        let fields = try FirestoreDocumentCoder.encode(capture)
        XCTAssertNotNil(fields["deletedAt"], "captures are camelCase apart from their exceptions")
        XCTAssertNil(fields["deleted_at"], "the snake_case spelling belongs to tasks, not captures")

        let decoded = try FirestoreDocumentCoder.decode(Capture.self, from: fields)
        XCTAssertEqual(decoded.deletedAt, Self.stamp)
    }

    func testCapture_omitsTheKeyEntirelyWhenLive() throws {
        let capture = Capture(
            id: UUID(), content: "buy stamps", kind: .note, processed: false, createdAt: Self.stamp
        )
        let fields = try FirestoreDocumentCoder.encode(capture)
        XCTAssertNil(fields["deletedAt"])
    }
}
