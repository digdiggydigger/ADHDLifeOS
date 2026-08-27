//
//  NudgeCompletionCodingTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// `completion_dates` must survive the REAL Firestore codec — an array of Timestamps in, `[Date]`
/// out. The recording-fake tests can't see this seam; the nudge journey caught it failing.
final class NudgeCompletionCodingTests: XCTestCase {
    func testNudge_roundTripsCompletionDatesThroughTheFirestoreCoder() throws {
        let stamps = [
            Date(timeIntervalSince1970: 1_700_000_000),
            Date(timeIntervalSince1970: 1_700_086_400)
        ]
        let nudge = Nudge(
            id: UUID(), label: "Hydrate", schedule: "0 9 * * *", active: true,
            lastFiredAt: stamps[1], completionDates: stamps,
            createdAt: stamps[0], updatedAt: stamps[1]
        )

        let fields = try FirestoreDocumentCoder.encode(nudge)
        XCTAssertNotNil(fields["completion_dates"], "snake_case key must be written")
        XCTAssertNil(fields["completionDates"])

        let decoded = try FirestoreDocumentCoder.decode(Nudge.self, from: fields)
        XCTAssertEqual(decoded.completionDates, stamps)
    }

    func testNudge_decodesADocumentWithoutTheField() throws {
        let nudge = Nudge(
            id: UUID(), label: "Hydrate", schedule: "0 9 * * *", active: true,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        var fields = try FirestoreDocumentCoder.encode(nudge)
        fields.removeValue(forKey: "completion_dates")
        let decoded = try FirestoreDocumentCoder.decode(Nudge.self, from: fields)
        XCTAssertNil(decoded.completionDates)
    }
}
