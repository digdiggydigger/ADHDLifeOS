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

    // MARK: - Captures: the retired `status` field

    /// The audit's A4. `status` was a THIRD representation of triage position beside `processed`
    /// and `seen`: written at create (`inbox`) and on promotion (`processed`), never touched by
    /// Sorted, and — the point — read by nothing in the app. A field nothing reads cannot be
    /// wrong in a way anyone notices, which is exactly why it drifted. It is gone; these assert
    /// the payloads no longer mint it, in the same absence-of-the-wrong-key style as the
    /// snake_case/camelCase pins above.
    func testCaptureUpdate_titleOnly_touchesNeitherProcessedNorStatus() {
        let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(title: "Dentist"))

        XCTAssertEqual(fields.keys.sorted(), ["title"])
        XCTAssertNil(fields["processed"], "a rename must not re-file the capture")
        XCTAssertNil(fields["status"], "status is retired; processed and seen are the state")
    }

    // MARK: - Captures: the `seen` archive flag

    /// Archiving writes `seen` and ONLY `seen` — deliberately not `processed`. A seen
    /// capture is filed away, not triaged: it stays `processed == false` so it can still be
    /// promoted to a task later from the Captures tab. "Seen implies processed" is the tempting
    /// wrong version of this, and it would strand archived captures un-promotable.
    func testCaptureUpdate_markingSeenWritesOnlyTheSeenField() {
        let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(seen: true))

        XCTAssertEqual(fields.keys.sorted(), ["seen"])
        XCTAssertEqual(fields["seen"] as? Bool, true)
    }

    /// Undo writes an explicit `false`, not a field delete. Either would leave the equality
    /// query's results correct, but a plain `Bool?` has no `.some(nil)` to express a delete with —
    /// and an explicit `false` on the document reads as "was archived, then sent back".
    func testCaptureUpdate_undoingSeenWritesFalseNotADelete() {
        let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(seen: false))

        XCTAssertEqual(fields.keys.sorted(), ["seen"])
        XCTAssertEqual(fields["seen"] as? Bool, false)
        XCTAssertFalse(FirestoreDocumentCoder.isFieldDelete(fields["seen"]))
    }

    // MARK: - Captures: the notes annotation

    func testCaptureUpdate_notesWritesTheAnnotation() {
        let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(notes: .some("Read this later")))

        XCTAssertEqual(fields.keys.sorted(), ["notes"])
        XCTAssertEqual(fields["notes"] as? String, "Read this later")
    }

    /// Deleting your annotation removes the field, mirroring `TaskUpdatePayload.notes` — an empty
    /// string left behind would still render an empty Notes panel.
    func testCaptureUpdate_clearingNotesBecomesADelete() {
        let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(notes: .some(nil)))

        XCTAssertEqual(fields.keys.sorted(), ["notes"])
        XCTAssertTrue(FirestoreDocumentCoder.isFieldDelete(fields["notes"]))
    }

    func testCaptureUpdate_untouchedNotesIsNotWritten() {
        XCTAssertNil(FirestoreFieldPayloads.captureUpdate(CaptureUpdate(seen: true))["notes"])
    }

    // MARK: - Captures: the clearedAt event stamp (M7)

    func testCaptureUpdate_clearedAtWritesATimestamp() {
        let stamp = Date(timeIntervalSince1970: 1_755_000_000)

        let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(clearedAt: .some(stamp)))

        XCTAssertEqual(fields.keys.sorted(), ["clearedAt"])
        XCTAssertEqual(FirestoreDocumentCoder.date(from: fields["clearedAt"]), stamp)
    }

    /// Un-archiving sends the capture back to the inbox, so the exit stamp must go with it.
    func testCaptureUpdate_clearingClearedAtBecomesADelete() {
        let fields = FirestoreFieldPayloads.captureUpdate(CaptureUpdate(clearedAt: .some(nil)))

        XCTAssertTrue(FirestoreDocumentCoder.isFieldDelete(fields["clearedAt"]))
    }

    /// The processed flip, its status twin and the exit stamp travel in ONE write — previously
    /// `markCaptureProcessed` hand-built this dictionary inline, the exact bypass the file header
    /// warns about.
    func testCaptureProcessed_writesTheProcessedFlagAndClearedAtTogether() {
        let stamp = Date(timeIntervalSince1970: 1_755_000_000)

        let fields = FirestoreFieldPayloads.captureProcessed(now: stamp)

        XCTAssertEqual(fields.keys.sorted(), ["clearedAt", "processed"])
        XCTAssertEqual(fields["processed"] as? Bool, true)
        XCTAssertNil(fields["status"], "the retired third state field (A4) must not be re-minted")
        XCTAssertEqual(FirestoreDocumentCoder.date(from: fields["clearedAt"]), stamp)
    }

    /// `captureProcessed`'s inverse, for undoing "Journal it". The exit stamp is DELETED rather
    /// than written false-ish: a capture back in the inbox has not left it, and a stale
    /// `clearedAt` would file it into a day it never belonged to (the M7 honest-data rule, the
    /// same one `CaptureUpdate.clearedAt: .some(nil)` follows when a sort is undone).
    func testCaptureUnprocessed_clearsTheFlagAndDeletesTheExitStamp() {
        let fields = FirestoreFieldPayloads.captureUnprocessed()

        XCTAssertEqual(fields.keys.sorted(), ["clearedAt", "processed"])
        XCTAssertEqual(fields["processed"] as? Bool, false)
        XCTAssertTrue(
            FirestoreDocumentCoder.isFieldDelete(fields["clearedAt"]),
            "back in the inbox means no exit stamp at all, not an old one left standing"
        )
        XCTAssertNil(fields["status"])
    }

    // MARK: - Nudges

    func testNudgeUpdate_emptyPayload_writesNothing() {
        XCTAssertTrue(FirestoreFieldPayloads.nudgeUpdate(NudgeUpdatePayload()).isEmpty)
    }

    /// The schedule is encoded to its cron string at this boundary — the document stores
    /// `MINUTE HOUR * * DOW-LIST`, never a structured object.
    func testNudgeUpdate_encodesTheScheduleAsACronString() {
        var payload = NudgeUpdatePayload()
        payload.schedule = NudgeSchedule(hour: 9, minute: 30, weekdays: [1, 2, 3, 4, 5])

        let fields = FirestoreFieldPayloads.nudgeUpdate(payload)

        XCTAssertEqual(fields["schedule"] as? String, "30 9 * * 1,2,3,4,5")
    }

    func testNudgeUpdate_setsOnlyTheFieldsPresent() {
        var payload = NudgeUpdatePayload()
        payload.label = "Stretch"

        let fields = FirestoreFieldPayloads.nudgeUpdate(payload)

        XCTAssertEqual(fields["label"] as? String, "Stretch")
        XCTAssertNil(fields["schedule"])
        XCTAssertNil(fields["active"])
    }

    func testNudgeUpdate_activeIsWrittenAsABool() {
        var payload = NudgeUpdatePayload()
        payload.active = false

        XCTAssertEqual(FirestoreFieldPayloads.nudgeUpdate(payload)["active"] as? Bool, false)
    }

    /// Any real change stamps `updated_at` — but only a real change: an empty payload writes
    /// nothing at all, so a no-op edit must not bump the timestamp.
    func testNudgeUpdate_anyChangeStampsUpdatedAtFromTheServerClock() {
        var payload = NudgeUpdatePayload()
        payload.label = "Stretch"

        let fields = FirestoreFieldPayloads.nudgeUpdate(payload)

        XCTAssertTrue(FirestoreDocumentCoder.isServerTimestamp(fields["updated_at"]))
        XCTAssertNil(fields["updatedAt"])
    }

    func testNudgeUpdate_emptyPayloadDoesNotStampUpdatedAt() {
        XCTAssertNil(FirestoreFieldPayloads.nudgeUpdate(NudgeUpdatePayload())["updated_at"])
    }

    /// `markFired` is the one nudge write that uses the CLIENT clock, and it writes both stamps as
    /// the same instant so "last fired" and "last updated" cannot disagree by a round trip. That is
    /// deliberately different from `nudgeUpdate`, which defers to the server clock.
    func testNudgeFired_writesBothStampsAsTheSameClientInstant() {
        let earlier = referenceDate.addingTimeInterval(-86_400)
        let fields = FirestoreFieldPayloads.nudgeFired(
            now: referenceDate, completionDates: [earlier, referenceDate]
        )

        XCTAssertEqual(fields.keys.sorted(), ["completion_dates", "last_fired_at", "updated_at"])
        XCTAssertNil(fields["completionDates"], "capture-style camelCase must be ABSENT on nudges")
        XCTAssertEqual(
            (fields["completion_dates"] as? [Any])?.compactMap { FirestoreDocumentCoder.date(from: $0) },
            [earlier, referenceDate]
        )
        XCTAssertEqual(FirestoreDocumentCoder.date(from: fields["last_fired_at"]), referenceDate)
        XCTAssertEqual(FirestoreDocumentCoder.date(from: fields["updated_at"]), referenceDate)
        XCTAssertFalse(
            FirestoreDocumentCoder.isServerTimestamp(fields["updated_at"]),
            "markFired pins the instant client-side, unlike nudgeUpdate"
        )
    }
}

/// The Firestore error facts the Nudges adapter maps on. Kept honest by deriving the domain and
/// code from the SDK rather than hardcoding "FIRFirestoreErrorDomain"/5 in a test, which would
/// drift silently if either ever changed.
final class FirestoreErrorMappingTests: XCTestCase {
    func testIsNotFound_recognisesFirestoresMissingDocumentError() {
        let error = NSError(
            domain: FirestoreErrorMapping.errorDomain,
            code: FirestoreErrorMapping.notFoundCode
        )

        XCTAssertTrue(FirestoreErrorMapping.isNotFound(error))
    }

    func testIsNotFound_rejectsAnotherFirestoreCode() {
        let error = NSError(domain: FirestoreErrorMapping.errorDomain, code: FirestoreErrorMapping.notFoundCode + 1)

        XCTAssertFalse(FirestoreErrorMapping.isNotFound(error))
    }

    /// A "not found" from somewhere else is not Firestore's — the domain has to match, or an
    /// unrelated failure would surface as "this no longer exists".
    func testIsNotFound_rejectsTheSameCodeFromAnotherDomain() {
        let error = NSError(domain: "SomeOtherDomain", code: FirestoreErrorMapping.notFoundCode)

        XCTAssertFalse(FirestoreErrorMapping.isNotFound(error))
    }

    func testIsNotFound_rejectsAPlainSwiftError() {
        XCTAssertFalse(FirestoreErrorMapping.isNotFound(FirebaseManagerError.notSignedIn))
    }
}
