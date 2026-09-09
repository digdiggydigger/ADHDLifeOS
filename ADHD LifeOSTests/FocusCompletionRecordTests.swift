//
//  FocusCompletionRecordTests.swift
//  ADHD LifeOSTests
//
//  F-FocusCard-2's record half: `CompletedFocusSession.confirmedAt`, the field that distinguishes
//  a sprint the user has ACKNOWLEDGED from one that merely finished.
//
//  Written before the implementation (`claudecode.md`). The two guards that matter most here are
//  about history rather than about the new feature: every record already in E's Firestore was
//  written without this key, and every record already in E's analytics must keep counting.
//

import XCTest
@testable import ADHD_LifeOS

final class FocusCompletionRecordTests: XCTestCase {

    private func record(
        id: UUID = UUID(),
        focusedSeconds: Int = 1530,
        placeId: UUID? = nil,
        confirmedAt: Date? = nil
    ) -> CompletedFocusSession {
        CompletedFocusSession(
            id: id, taskId: UUID(), taskTitle: "Draft the quarterly review",
            lifeAreaEmoji: "💼", plannedSeconds: 1500, focusedSeconds: focusedSeconds,
            checkpointsReached: 2, completedNaturally: true,
            startedAt: Date(timeIntervalSince1970: 1_800_000_000),
            endedAt: Date(timeIntervalSince1970: 1_800_001_530),
            placeId: placeId, latitude: placeId == nil ? nil : 51.5,
            longitude: placeId == nil ? nil : -0.12,
            confirmedAt: confirmedAt
        )
    }

    // MARK: - Every record already in Firestore predates the key

    /// **The guard that protects E's real history.** Every `focus_sessions` document written
    /// before this block has no `confirmed_at` at all. Make the property non-optional — the
    /// plausible simplification, since every NEW record eventually gets one — and the decoder
    /// throws `keyNotFound` on all of them, which renders the whole weekly/trend analytics empty
    /// rather than merely un-confirmed.
    func testLegacyRecordDecodesAsProvisional() throws {
        let legacy = Data(
            """
            {
              "id": "3F2504E0-4F89-11D3-9A0C-0305E82C3301",
              "task_title": "Break down Q3 Project Proposal",
              "life_area_emoji": "💼",
              "planned_seconds": 1500,
              "focused_seconds": 1500,
              "checkpoints_reached": 2,
              "completed_naturally": true,
              "started_at": 750000000,
              "ended_at": 750001500
            }
            """.utf8
        )

        let decoded = try JSONDecoder().decode(CompletedFocusSession.self, from: legacy)

        XCTAssertNil(
            decoded.confirmedAt,
            "A record written before F-FocusCard-2 must decode with no confirmation date."
        )
        XCTAssertTrue(
            decoded.isProvisional,
            "A record with no `confirmed_at` IS provisional — that is the whole meaning of the"
                + " field, and it is what makes every historic record read correctly."
        )
        XCTAssertEqual(decoded.focusedSeconds, 1500, "The rest of the legacy record must survive.")
    }

    // MARK: - The house spelling

    /// `focus_sessions` is snake_cased throughout (`life_area_emoji`, `place_id`, `started_at`).
    /// A missing `CodingKeys` line is invisible to a round-trip test — the encoder and decoder
    /// simply agree on the wrong spelling — so the assertion has to be that `confirmedAt` is
    /// ABSENT as well as that `confirmed_at` is present.
    func testConfirmedAtRoundTripsUnderItsSnakeCaseKey() throws {
        let confirmed = record().confirmed(at: Date(timeIntervalSince1970: 1_800_002_000))

        let data = try JSONEncoder().encode(confirmed)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertNotNil(json["confirmed_at"], "The confirmation date is not being encoded at all.")
        XCTAssertNil(
            json["confirmedAt"],
            "`confirmed_at` is being written camelCased. `focus_sessions` is fully snake_cased —"
                + " a wrong key raises nothing, it just writes a field nothing reads."
        )

        let decoded = try JSONDecoder().decode(CompletedFocusSession.self, from: data)
        XCTAssertEqual(decoded.confirmedAt, confirmed.confirmedAt)
        XCTAssertFalse(decoded.isProvisional)
    }

    // MARK: - `confirmed(at:)` is additive, exactly like `stamped(with:)`

    func testConfirmedKeepsTheIdentityAndEveryOtherField() {
        let id = UUID()
        let placeId = UUID()
        let original = record(id: id, placeId: placeId)

        let confirmed = original.confirmed(at: Date(timeIntervalSince1970: 1_800_002_000))

        XCTAssertEqual(
            confirmed.id, id,
            "`confirmed(at:)` minted a new id. `FirebaseManager.save(_:id:in:)` keys on"
                + " `id.uuidString`, so a new id writes a SECOND history row instead of upserting"
                + " the one the sprint already wrote — the sprint would count twice."
        )
        XCTAssertEqual(confirmed.placeId, placeId, "The location stamp was dropped on confirm.")
        XCTAssertEqual(confirmed.latitude, original.latitude)
        XCTAssertEqual(confirmed.longitude, original.longitude)
        XCTAssertEqual(confirmed.focusedSeconds, original.focusedSeconds)
        XCTAssertEqual(confirmed.startedAt, original.startedAt)
        XCTAssertEqual(confirmed.endedAt, original.endedAt)
        XCTAssertEqual(confirmed.confirmedAt, Date(timeIntervalSince1970: 1_800_002_000))
        XCTAssertTrue(original.isProvisional, "`confirmed(at:)` must not mutate the receiver.")
    }

    // MARK: - The field is inert to every existing reader

    /// **Banked time is banked.** The confirmation is a UI acknowledgement, not a data gate: a
    /// sprint the user never confirms still counts in the weekly totals, the trend chart and the
    /// widget. Filtering on the new field is the plausible next step and it would silently
    /// rewrite E's history the moment an unconfirmed card was left on screen.
    func testAnalyticsCountProvisionalAndConfirmedRecordsAlike() {
        let day = Date(timeIntervalSince1970: 1_800_000_000)
        let provisional = record(focusedSeconds: 600)
        let confirmed = record(focusedSeconds: 900).confirmed(at: day)

        let buckets = FocusAnalytics.rollingDays(
            sessions: [provisional, confirmed], days: 7, now: day
        )
        let total = buckets.reduce(0) { $0 + $1.focusedSeconds }

        XCTAssertEqual(
            total, 1500,
            "Analytics are filtering on `confirmedAt`. Banked time is banked — the confirmation"
                + " acknowledges a completion, it does not gate the data."
        )
    }
}
