//
//  FirebaseManagerNudgeCompletionTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The F-V3-Nudges completion stamps against REAL Firestore (emulator + live rules): the
/// `nudgeFired` payload with its `completion_dates` array must write, satisfy the rules, and
/// decode back as `[Date]`. Written while chasing the nudge journey's dismissal failure — a
/// recording fake cannot catch a wire-level rejection.
final class FirebaseManagerNudgeCompletionTests: XCTestCase {
    private var manager: FirebaseManager { .shared }

    override func setUp() async throws {
        try await super.setUp()
        try await FirebaseEmulatorHarness.requireEmulator()
        try await FirebaseEmulatorHarness.signUpEmptyUser()
    }

    override func tearDown() async throws {
        await FirebaseEmulatorHarness.tearDownCurrentUser()
        try await super.tearDown()
    }

    func testNudgeFiredPayload_roundTripsThroughTheEmulator() async throws {
        let created = Date(timeIntervalSince1970: 1_700_000_000)
        let nudge = Nudge(
            id: UUID(), label: "Hydrate", schedule: "0 9 * * *", active: true,
            createdAt: created, updatedAt: created
        )
        try await manager.createNudge(nudge)

        let firedAt = Date()
        try await manager.updateNudge(
            id: nudge.id,
            fields: FirestoreFieldPayloads.nudgeFired(now: firedAt, completionDates: [firedAt])
        )

        let fetched = try await manager.fetchNudges().first { $0.id == nudge.id }
        let stamps = try XCTUnwrap(fetched?.completionDates)
        XCTAssertEqual(stamps.count, 1)
        XCTAssertEqual(
            stamps[0].timeIntervalSince1970, firedAt.timeIntervalSince1970, accuracy: 0.01
        )
        XCTAssertEqual(
            fetched?.lastFiredAt?.timeIntervalSince1970 ?? 0,
            firedAt.timeIntervalSince1970, accuracy: 0.01
        )
    }
}
