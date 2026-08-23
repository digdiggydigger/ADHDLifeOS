//
//  FirestoreDocumentCoderTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// Round-trips the domain models through the **real** Firestore codec, which the pre-existing
/// coding tests (`TaskFocusFieldsCodingTests`, `ReminderDecodingTests`, `CaptureModelsTests`) do
/// not: those use `JSONDecoder`, and a model can satisfy them while still writing the wrong thing
/// to Firestore. Two differences make that gap real — `Firestore.Encoder` writes a `Date` as a
/// `Timestamp` rather than a number, and these documents are read back with
/// `DocumentSnapshot.data(as:)`, which runs `Firestore.Decoder`, not `JSONDecoder`.
///
/// What every test here is guarding: **a wrong Firestore key does not fail.** It writes a field
/// nothing reads, or decodes as absent, with no error anywhere. The keys asserted below are
/// therefore spelled out as literals on purpose — deriving them from `CodingKeys` would make the
/// test agree with the bug.
final class FirestoreDocumentCoderTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_755_000_000)

    // MARK: - Capture: the mixed-case schema

    /// The trap documented in `FirebaseManager`'s header and the capture pipeline: on a capture
    /// document **only `created_at` is snake_cased**. Everything else keeps the camelCase the
    /// Shortcut and the capture function write. `Capture` is decoded straight off the document, so
    /// getting either half wrong silently drops the field.
    func testCaptureEncoding_snakeCasesOnlyCreatedAt() throws {
        let capture = Capture(
            id: UUID(),
            content: "Ring the dentist",
            kind: .voice,
            processed: false,
            createdAt: referenceDate,
            title: "Dentist",
            status: .inbox,
            lifeAreaId: UUID(),
            mediaURL: URL(string: "https://example.com/audio.m4a"),
            mediaContentType: "audio/m4a",
            thumbnailURL: nil,
            linkPreview: nil,
            aiAssessment: nil
        )

        let document = try FirestoreDocumentCoder.encode(capture)

        XCTAssertNotNil(document["created_at"], "created_at is the one snake_cased capture key")
        XCTAssertNil(document["createdAt"])
        XCTAssertNotNil(document["lifeAreaId"], "lifeAreaId stays camelCase on captures")
        XCTAssertNil(document["life_area_id"])
        XCTAssertNotNil(document["mediaURL"])
        XCTAssertNotNil(document["mediaContentType"])
        XCTAssertNil(document["media_url"])
        XCTAssertNil(document["media_content_type"])
    }

    /// The difference `JSONDecoder`-based tests cannot see: a `Date` crosses as a Firestore
    /// `Timestamp`, not as a seconds-since-1970 number.
    func testCaptureEncoding_datesCrossAsTimestampsNotNumbers() throws {
        let capture = Self.capture(createdAt: referenceDate)

        let document = try FirestoreDocumentCoder.encode(capture)

        XCTAssertEqual(FirestoreDocumentCoder.date(from: document["created_at"]), referenceDate)
        XCTAssertNil(document["created_at"] as? Double, "a raw number here would be a JSON-codec artefact")
    }

    func testCaptureRoundTrip_survivesTheRealCodec() throws {
        let capture = Self.capture(createdAt: referenceDate)

        let document = try FirestoreDocumentCoder.encode(capture)
        let decoded = try FirestoreDocumentCoder.decode(Capture.self, from: document)

        XCTAssertEqual(decoded, capture)
    }

    /// Pins that `created_at` is load-bearing rather than incidental: a document written with the
    /// camelCase spelling does not quietly decode with a default date, it fails.
    func testCaptureDecoding_camelCasedCreatedAtIsRejected() throws {
        var document = try FirestoreDocumentCoder.encode(Self.capture(createdAt: referenceDate))
        document["createdAt"] = document.removeValue(forKey: "created_at")

        XCTAssertThrowsError(try FirestoreDocumentCoder.decode(Capture.self, from: document))
    }

    // MARK: - Tasks: fully snake_cased, the opposite convention

    func testTaskItemEncoding_isFullySnakeCased() throws {
        let task = TaskItem(
            id: UUID(),
            lifeAreaId: UUID(),
            title: "Draft the brief",
            status: .done,
            priority: .p1,
            dueDate: referenceDate,
            focusDurationSeconds: 1_500,
            nudgesCount: 3,
            completedAt: referenceDate
        )

        let document = try FirestoreDocumentCoder.encode(task)

        XCTAssertNotNil(document["life_area_id"], "tasks are the opposite of captures — fully snake_cased")
        XCTAssertNil(document["lifeAreaId"])
        XCTAssertNotNil(document["due_date"])
        XCTAssertNotNil(document["focus_duration_seconds"])
        XCTAssertNotNil(document["nudges_count"])
        XCTAssertNotNil(document["completed_at"])
    }

    /// `completed_at` is the field the Daily Executive Summary counts wins from, and the only
    /// record of *when* a task was finished. It is written by `setTaskStatus` as a `Timestamp`.
    func testTaskItemEncoding_completedAtCrossesAsATimestamp() throws {
        let task = Self.task(completedAt: referenceDate)

        let document = try FirestoreDocumentCoder.encode(task)

        XCTAssertEqual(FirestoreDocumentCoder.date(from: document["completed_at"]), referenceDate)
    }

    /// A task completed before the field existed decodes as "done at an unknown time" rather than
    /// failing — deliberately no day's win, never a fallback to another timestamp.
    func testTaskItemDecoding_absentCompletedAtDecodesAsNil() throws {
        var document = try FirestoreDocumentCoder.encode(Self.task(completedAt: referenceDate))
        document.removeValue(forKey: "completed_at")

        let decoded = try FirestoreDocumentCoder.decode(TaskItem.self, from: document)

        XCTAssertNil(decoded.completedAt)
        XCTAssertEqual(decoded.status, .done)
    }

    func testTaskItemRoundTrip_survivesTheRealCodec() throws {
        let task = Self.task(completedAt: referenceDate)

        let decoded = try FirestoreDocumentCoder.decode(
            TaskItem.self, from: try FirestoreDocumentCoder.encode(task)
        )

        XCTAssertEqual(decoded, task)
    }

    // MARK: - Life areas

    /// `LifeArea`'s own header carries TRAP 4 ("never *encode* a `LifeArea`"), which applies to the
    /// deleted camelCase AWS backend only — `FirebaseManager.saveLifeArea` encodes this type on
    /// every create and archive toggle, and `sort_order` IS this schema's spelling. Pinning it here
    /// so the trap comment is never read as forbidding the Firestore path.
    func testLifeAreaEncoding_usesSortOrder() throws {
        let area = LifeArea(id: UUID(), name: "Health", colour: "🏃", sortOrder: 4, archived: true)

        let document = try FirestoreDocumentCoder.encode(area)

        XCTAssertEqual(document["sort_order"] as? Int, 4)
        XCTAssertNil(document["sortOrder"])
        XCTAssertEqual(document["archived"] as? Bool, true)
    }

    /// `fetchLifeAreas` orders by `sort_order`, and the nine seeded rows predate `archived`.
    func testLifeAreaDecoding_absentArchivedReadsAsFalse() throws {
        var document = try FirestoreDocumentCoder.encode(
            LifeArea(id: UUID(), name: "Admin", colour: "🗂", sortOrder: 0)
        )
        document.removeValue(forKey: "archived")

        let decoded = try FirestoreDocumentCoder.decode(LifeArea.self, from: document)

        XCTAssertFalse(decoded.archived)
    }

    // MARK: - Focus sessions

    /// `fetchFocusSessions` orders by `ended_at`. A Firestore query ordered by a field the document
    /// does not carry returns **empty, not an error** — the silent-empty failure that made the
    /// focus analytics look like a rules problem once already. This asserts the ordering field is
    /// actually written under the name the query asks for.
    func testCompletedFocusSessionEncoding_carriesTheEndedAtOrderingField() throws {
        let session = CompletedFocusSession(
            id: UUID(),
            taskId: UUID(),
            taskTitle: "Draft the brief",
            lifeAreaEmoji: "💼",
            plannedSeconds: 1_500,
            focusedSeconds: 1_310,
            checkpointsReached: 2,
            completedNaturally: false,
            startedAt: referenceDate,
            endedAt: referenceDate.addingTimeInterval(1_310)
        )

        let document = try FirestoreDocumentCoder.encode(session)

        XCTAssertEqual(
            FirestoreDocumentCoder.date(from: document["ended_at"]),
            referenceDate.addingTimeInterval(1_310),
            "fetchFocusSessions orders by ended_at — a missing field returns an empty history, silently"
        )
        XCTAssertNotNil(document["started_at"])
        XCTAssertNotNil(document["task_id"])
        XCTAssertNotNil(document["life_area_emoji"])
        XCTAssertNotNil(document["planned_seconds"])
        XCTAssertNotNil(document["focused_seconds"])
        XCTAssertNotNil(document["checkpoints_reached"])
        XCTAssertNotNil(document["completed_naturally"])
        XCTAssertNil(document["endedAt"])
    }

    func testCompletedFocusSessionRoundTrip_survivesTheRealCodec() throws {
        let session = CompletedFocusSession(
            id: UUID(),
            taskId: nil,
            taskTitle: "Untethered sprint",
            lifeAreaEmoji: "🎯",
            plannedSeconds: 600,
            focusedSeconds: 600,
            checkpointsReached: 1,
            completedNaturally: true,
            startedAt: referenceDate,
            endedAt: referenceDate.addingTimeInterval(600)
        )

        let decoded = try FirestoreDocumentCoder.decode(
            CompletedFocusSession.self, from: try FirestoreDocumentCoder.encode(session)
        )

        XCTAssertEqual(decoded, session)
    }

    // MARK: - Fixtures

    private static func capture(createdAt: Date) -> Capture {
        Capture(
            id: UUID(),
            content: "Ring the dentist",
            kind: .note,
            processed: false,
            createdAt: createdAt,
            title: "Dentist",
            status: .inbox,
            lifeAreaId: UUID(),
            mediaURL: nil,
            mediaContentType: nil,
            thumbnailURL: nil,
            linkPreview: nil,
            aiAssessment: nil
        )
    }

    private static func task(completedAt: Date?) -> TaskItem {
        TaskItem(
            id: UUID(),
            lifeAreaId: UUID(),
            title: "Draft the brief",
            status: .done,
            priority: .p1,
            dueDate: nil,
            focusDurationSeconds: nil,
            nudgesCount: nil,
            completedAt: completedAt
        )
    }
}
