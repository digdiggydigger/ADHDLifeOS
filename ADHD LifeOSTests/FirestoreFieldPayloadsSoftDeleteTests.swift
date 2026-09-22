//
//  FirestoreFieldPayloadsSoftDeleteTests.swift
//  ADHD LifeOSTests
//
//  `F-C3-RecentlyDeleted`: the soft-delete half of `FirestoreFieldPayloads`, in its own file
//  because the parent had reached SwiftLint's 400-line ceiling — not because it is a different
//  kind of test. Everything `FirestoreFieldPayloadsTests`' header says applies here verbatim:
//  these dictionaries are not derived from `Codable`, every key is a literal typed once, and a
//  wrong one raises nothing.
//

import XCTest
@testable import ADHD_LifeOS

/// The write side of the stamp. **`SoftDeleteCodecTests` cannot reach these** — it asserts the
/// key the MODEL declares, through the real round trip, and a partial update is a second,
/// independent spelling of the same field.
final class FirestoreFieldPayloadsSoftDeleteTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_755_000_000)

    /// **`SoftDeleteCodecTests` does not reach these.** That file asserts the stamp's spelling
    /// through the real `Codable` round trip — the key `TaskItem`/`Capture` declare. A partial
    /// update is a second, independent spelling of the same field, typed here by hand, and the
    /// two are free to drift: a `deleted_at` model key beside a `deletedAt` payload key writes a
    /// field nothing reads, so the delete appears to succeed and the item stays in every list.
    func testTaskSoftDelete_stampsDeletedAtSnakeCasedAndTouchesNothingElse() {
        let fields = FirestoreFieldPayloads.taskSoftDelete(now: referenceDate)

        XCTAssertEqual(
            fields.keys.sorted(), ["deleted_at"],
            "a soft delete writes the stamp and only the stamp — anything else here is a field the"
                + " restore would have to know how to put back"
        )
        XCTAssertEqual(FirestoreDocumentCoder.date(from: fields["deleted_at"]), referenceDate)
        XCTAssertNil(fields["deletedAt"], "that spelling belongs to captures, not tasks")
    }

    /// The erase, not a null. An explicit null leaves the collection in two shapes — some
    /// documents with no key, some with a null one — and `SoftDelete.isLive` would then be
    /// reading two different representations of "live". `captureUnprocessed()` set the precedent.
    func testTaskRestore_erasesTheStampRatherThanWritingNull() {
        let fields = FirestoreFieldPayloads.taskRestore()

        XCTAssertEqual(fields.keys.sorted(), ["deleted_at"])
        XCTAssertTrue(
            FirestoreDocumentCoder.isFieldDelete(fields["deleted_at"]),
            "a restored task must carry no stamp at all, the shape every task written before this"
                + " block already has"
        )
        XCTAssertNil(fields["deletedAt"])
    }

    /// A capture's stamp is camelCase — the opposite of a task's, and the same trap
    /// `testCaptureUpdate_lifeAreaIdStaysCamelCased` guards one field over.
    func testCaptureSoftDelete_stampsDeletedAtCamelCasedAndTouchesNothingElse() {
        let fields = FirestoreFieldPayloads.captureSoftDelete(now: referenceDate)

        XCTAssertEqual(fields.keys.sorted(), ["deletedAt"])
        XCTAssertEqual(FirestoreDocumentCoder.date(from: fields["deletedAt"]), referenceDate)
        XCTAssertNil(fields["deleted_at"], "that spelling belongs to tasks, not captures")
    }

    func testCaptureRestore_erasesTheStampRatherThanWritingNull() {
        let fields = FirestoreFieldPayloads.captureRestore()

        XCTAssertEqual(fields.keys.sorted(), ["deletedAt"])
        XCTAssertTrue(FirestoreDocumentCoder.isFieldDelete(fields["deletedAt"]))
        XCTAssertNil(fields["deleted_at"])
    }

    /// The pair the two conventions make it easiest to get wrong: both payloads name the same
    /// concept and neither may answer to the other's key.
    func testTheTwoSoftDeletePayloadsNeverShareASpelling() {
        let task = FirestoreFieldPayloads.taskSoftDelete(now: referenceDate)
        let capture = FirestoreFieldPayloads.captureSoftDelete(now: referenceDate)

        XCTAssertTrue(Set(task.keys).isDisjoint(with: Set(capture.keys)))
    }
}
