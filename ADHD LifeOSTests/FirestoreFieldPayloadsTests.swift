//
//  FirestoreFieldPayloadsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The hand-written Firestore field dictionaries — the highest-risk strings in the app, and until
/// now the only ones nothing could reach. They are not derived from `Codable`, so no round-trip
/// test touches them: every key is a literal typed once, and **a wrong one raises nothing**. The
/// write succeeds against a field nothing reads, and the edit appears to have silently failed.
///
/// The cross-convention pair below is the specific trap this file exists for: a task's life-area
/// key is `life_area_id`, a capture's is `lifeAreaId`. Both are correct. Copying either one to the
/// other document type is undetectable at runtime.
final class FirestoreFieldPayloadsTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_755_000_000)

    // MARK: - Tasks: fully snake_cased

    func testTaskUpdate_emptyPayload_writesNothing() {
        XCTAssertTrue(FirestoreFieldPayloads.taskUpdate(TaskUpdatePayload()).isEmpty)
    }

    func testTaskUpdate_setsOnlyTheFieldsPresentInThePayload() {
        var payload = TaskUpdatePayload()
        payload.title = "Draft the brief"

        let fields = FirestoreFieldPayloads.taskUpdate(payload)

        XCTAssertEqual(fields.keys.sorted(), ["title"])
        XCTAssertEqual(fields["title"] as? String, "Draft the brief")
    }

    func testTaskUpdate_priorityIsWrittenAsItsRawValue() {
        var payload = TaskUpdatePayload()
        payload.priority = .p1

        XCTAssertEqual(FirestoreFieldPayloads.taskUpdate(payload)["priority"] as? String, "p1")
    }

    /// A task's life-area key is snake_cased — the opposite of a capture's. See
    /// `testCaptureUpdate_lifeAreaIdStaysCamelCased`.
    func testTaskUpdate_lifeAreaIdIsSnakeCased() {
        let lifeAreaId = UUID()
        var payload = TaskUpdatePayload()
        payload.lifeAreaId = .some(lifeAreaId)

        let fields = FirestoreFieldPayloads.taskUpdate(payload)

        XCTAssertEqual(fields["life_area_id"] as? String, lifeAreaId.uuidString)
        XCTAssertNil(fields["lifeAreaId"], "that spelling belongs to captures, not tasks")
    }

    func testTaskUpdate_dueDateIsWrittenAsATimestamp() {
        var payload = TaskUpdatePayload()
        payload.dueDate = .some(referenceDate)

        let fields = FirestoreFieldPayloads.taskUpdate(payload)

        XCTAssertEqual(FirestoreDocumentCoder.date(from: fields["due_date"]), referenceDate)
        XCTAssertNil(fields["dueDate"])
    }

    func testTaskUpdate_focusConfigIsSnakeCased() {
        var payload = TaskUpdatePayload()
        payload.focusDurationSeconds = 1_500
        payload.nudgesCount = 3

        let fields = FirestoreFieldPayloads.taskUpdate(payload)

        XCTAssertEqual(fields["focus_duration_seconds"] as? Int, 1_500)
        XCTAssertEqual(fields["nudges_count"] as? Int, 3)
        XCTAssertNil(fields["focusDurationSeconds"])
        XCTAssertNil(fields["nudgesCount"])
    }

    // MARK: - Tasks: the nested-optional clear convention

    /// Outer `nil` = untouched, `.some(nil)` = explicitly cleared. The two must never collapse:
    /// clearing a due date has to erase the field, not skip the write.
    func testTaskUpdate_untouchedNestedOptionalsAreNotWritten() {
        var payload = TaskUpdatePayload()
        payload.title = "Draft the brief"

        let fields = FirestoreFieldPayloads.taskUpdate(payload)

        XCTAssertNil(fields["notes"])
        XCTAssertNil(fields["life_area_id"])
        XCTAssertNil(fields["due_date"])
    }

    func testTaskUpdate_explicitlyClearedFieldsBecomeADelete() {
        var payload = TaskUpdatePayload()
        payload.notes = .some(nil)
        payload.lifeAreaId = .some(nil)
        payload.dueDate = .some(nil)

        let fields = FirestoreFieldPayloads.taskUpdate(payload)

        XCTAssertEqual(fields.keys.sorted(), ["due_date", "life_area_id", "notes"])
        XCTAssertTrue(FirestoreDocumentCoder.isFieldDelete(fields["notes"]))
        XCTAssertTrue(FirestoreDocumentCoder.isFieldDelete(fields["life_area_id"]))
        XCTAssertTrue(FirestoreDocumentCoder.isFieldDelete(fields["due_date"]))
    }

    /// A delete sentinel must not be confused with a server timestamp — they are both `FieldValue`,
    /// and writing the wrong one would stamp a field instead of erasing it.
    func testTaskUpdate_clearIsADeleteNotAServerTimestamp() {
        var payload = TaskUpdatePayload()
        payload.notes = .some(nil)

        let fields = FirestoreFieldPayloads.taskUpdate(payload)

        XCTAssertFalse(FirestoreDocumentCoder.isServerTimestamp(fields["notes"]))
    }

    // MARK: - Task status: the completion stamp

    /// Status and stamp are written together so a task can never be `done` with a stale stamp or
    /// `open` with a live one.
    func testTaskStatus_completingStampsTheClientClock() {
        let fields = FirestoreFieldPayloads.taskStatus(.done, now: referenceDate)

        XCTAssertEqual(fields["status"] as? String, "done")
        XCTAssertEqual(FirestoreDocumentCoder.date(from: fields["completed_at"]), referenceDate)
        XCTAssertNil(fields["completedAt"])
    }

    /// Re-opening clears the stamp rather than leaving yesterday's completion claiming a win.
    func testTaskStatus_reopeningDeletesTheStamp() {
        let fields = FirestoreFieldPayloads.taskStatus(.open, now: referenceDate)

        XCTAssertEqual(fields["status"] as? String, "open")
        XCTAssertTrue(FirestoreDocumentCoder.isFieldDelete(fields["completed_at"]))
    }

    func testTaskStatus_alwaysWritesBothFieldsTogether() {
        for status in [TaskStatus.open, .done] {
            XCTAssertEqual(
                FirestoreFieldPayloads.taskStatus(status, now: referenceDate).keys.sorted(),
                ["completed_at", "status"],
                "status \(status) must carry its stamp decision in the same write"
            )
        }
    }

    // MARK: - Captures: the mixed-case schema

    func testCaptureUpdate_emptyChanges_writesNothing() {
        XCTAssertTrue(FirestoreFieldPayloads.captureUpdate(CaptureUpdate()).isEmpty)
    }

    /// The counterpart to `testTaskUpdate_lifeAreaIdIsSnakeCased`. Only `created_at` is snake_cased
    /// on a capture document; `lifeAreaId` keeps the camelCase the Shortcut and capture function
    /// write.
    func testCaptureUpdate_lifeAreaIdStaysCamelCased() {
        let lifeAreaId = UUID()

        let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(lifeAreaId: .some(lifeAreaId)))

        XCTAssertEqual(fields["lifeAreaId"] as? String, lifeAreaId.uuidString)
        XCTAssertNil(fields["life_area_id"], "that spelling belongs to tasks, not captures")
    }

    /// Triage's Life Area picker can clear a capture back to "None".
    func testCaptureUpdate_clearingLifeAreaBecomesADelete() {
        let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(lifeAreaId: .some(nil)))

        XCTAssertEqual(fields.keys.sorted(), ["lifeAreaId"])
        XCTAssertTrue(FirestoreDocumentCoder.isFieldDelete(fields["lifeAreaId"]))
    }

    func testCaptureUpdate_untouchedLifeAreaIsNotWritten() {
        let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(title: "Dentist"))

        XCTAssertEqual(fields.keys.sorted(), ["title"])
    }

    // MARK: - Captures: status and its derived `processed` flag

    /// `status` and `processed` are two representations of one fact, written together — the inbox
    /// query filters on `processed`, so a status change that left it stale would leave a triaged
    /// capture sitting in the inbox.
    func testCaptureUpdate_processingSetsBothStatusAndTheProcessedFlag() {
        let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(status: .processed))

        XCTAssertEqual(fields["status"] as? String, "processed")
        XCTAssertEqual(fields["processed"] as? Bool, true)
    }

    func testCaptureUpdate_everyNonProcessedStatusClearsTheProcessedFlag() {
        for status in [CaptureStatus.inbox, .needsReview] {
            let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(status: status))

            XCTAssertEqual(fields["processed"] as? Bool, false, "status \(status) is not processed")
        }
    }

    /// `needs-review` is hyphenated on the wire, unlike its Swift case name.
    func testCaptureUpdate_needsReviewKeepsItsHyphenatedRawValue() {
        let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(status: .needsReview))

        XCTAssertEqual(fields["status"] as? String, "needs-review")
    }

    func testCaptureUpdate_titleOnly_doesNotTouchTheProcessedFlag() {
        let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(title: "Dentist"))

        XCTAssertNil(fields["processed"], "a rename must not re-file the capture")
        XCTAssertNil(fields["status"])
    }
}
