//
//  FirestoreTaskStatusPayloadTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `FirestoreFieldPayloads.taskStatus` — split out of `FirestoreFieldPayloadsTests` when the
/// location trio (block 3 remainder) pushed that file past its length budget. Same contract,
/// same traps: hand-written keys that raise nothing when wrong.
final class FirestoreTaskStatusPayloadTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_755_000_000)

    /// Status and stamp are written together so a task can never be `done` with a stale stamp or
    /// `open` with a live one.
    func testTaskStatus_completingStampsTheClientClock() {
        let fields = FirestoreFieldPayloads.taskStatus(.done, now: referenceDate, locationStamp: nil)

        XCTAssertEqual(fields["status"] as? String, "done")
        XCTAssertEqual(FirestoreDocumentCoder.date(from: fields["completed_at"]), referenceDate)
        XCTAssertNil(fields["completedAt"])
    }

    /// Re-opening clears the stamp rather than leaving yesterday's completion claiming a win.
    func testTaskStatus_reopeningDeletesTheStamp() {
        let fields = FirestoreFieldPayloads.taskStatus(.open, now: referenceDate, locationStamp: nil)

        XCTAssertEqual(fields["status"] as? String, "open")
        XCTAssertTrue(FirestoreDocumentCoder.isFieldDelete(fields["completed_at"]))
    }

    func testTaskStatus_alwaysWritesTheFullFieldSetTogether() {
        for status in [TaskStatus.open, .done] {
            XCTAssertEqual(
                FirestoreFieldPayloads.taskStatus(status, now: referenceDate, locationStamp: nil).keys.sorted(),
                ["completed_at", "latitude", "longitude", "place_id", "status"],
                "status \(status) must carry its stamp decisions in the same write"
            )
        }
    }

    /// Closing with a stamp records WHERE in the same write (block 3 remainder) — snake_case,
    /// the tasks convention, asserted both ways because a wrong key raises nothing.
    func testTaskStatus_completingWithAStampWritesTheLocationTrio() {
        let placeId = UUID()
        let stamp = LocationStamp(
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418), placeId: placeId
        )

        let fields = FirestoreFieldPayloads.taskStatus(.done, now: referenceDate, locationStamp: stamp)

        XCTAssertEqual(fields["place_id"] as? String, placeId.uuidString)
        XCTAssertEqual(fields["latitude"] as? Double, 51.5152)
        XCTAssertEqual(fields["longitude"] as? Double, -0.1418)
        XCTAssertNil(fields["placeId"], "the camelCase spelling belongs to captures, not tasks")
    }

    /// Outside every named place the coordinate still travels — and any dangling `place_id` from
    /// an earlier close is erased rather than left claiming this close happened there.
    func testTaskStatus_completingOutsideANamedPlace_keepsCoordinatesAndErasesThePlace() {
        let stamp = LocationStamp(
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418), placeId: nil
        )

        let fields = FirestoreFieldPayloads.taskStatus(.done, now: referenceDate, locationStamp: stamp)

        XCTAssertTrue(FirestoreDocumentCoder.isFieldDelete(fields["place_id"]))
        XCTAssertEqual(fields["latitude"] as? Double, 51.5152)
        XCTAssertEqual(fields["longitude"] as? Double, -0.1418)
    }

    /// No stamp (tagging off, no permission, no fix) and re-opening both ERASE the trio — a
    /// reopened task was not finished anywhere, and Home Momentum can reopen and re-close.
    func testTaskStatus_noStampAndReopeningBothEraseTheLocationTrio() {
        for status in [TaskStatus.open, .done] {
            let fields = FirestoreFieldPayloads.taskStatus(status, now: referenceDate, locationStamp: nil)
            for key in ["place_id", "latitude", "longitude"] {
                XCTAssertTrue(
                    FirestoreDocumentCoder.isFieldDelete(fields[key]),
                    "\(key) must be erased for status \(status) with no stamp"
                )
            }
        }
    }
}
