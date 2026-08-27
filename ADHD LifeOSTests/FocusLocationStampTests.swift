//
//  FocusLocationStampTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// That a finished sprint carries its location stamp into the history write (block 3 remainder) —
/// and the half specific to sprints: only LIVE ends stamp. A sprint that expired while the app
/// was dead is settled at the next launch from wherever the user is THEN, so stamping it would
/// record the wrong place; no stamp beats a wrong one.
@MainActor
final class FocusLocationStampTests: XCTestCase {

    private let coordinate = PlaceCoordinate(latitude: 51.5152, longitude: -0.1418)

    private final class FakeFocusLogger: FocusSessionLogging, @unchecked Sendable {
        var logged: [CompletedFocusSession] = []
        func logCompletedSession(_ session: CompletedFocusSession) async throws {
            logged.append(session)
        }
    }

    private final class FakeFocusSprintStore: FocusSprintPersisting {
        var stored: PersistedFocusSprint?
        var unacknowledged: CompletedFocusSession?

        func read() -> PersistedFocusSprint? { stored }
        func write(_ state: PersistedFocusSprint) { stored = state }
        func clear() { stored = nil }
        func readUnacknowledgedCompletion() -> CompletedFocusSession? { unacknowledged }
        func writeUnacknowledgedCompletion(_ record: CompletedFocusSession) { unacknowledged = record }
        func clearUnacknowledgedCompletion() { unacknowledged = nil }
    }

    private func record(
        placeId: UUID? = nil, latitude: Double? = nil, longitude: Double? = nil
    ) -> CompletedFocusSession {
        CompletedFocusSession(
            id: UUID(), taskId: nil, taskTitle: "Draft the review", lifeAreaEmoji: "💼",
            plannedSeconds: 1500, focusedSeconds: 900, checkpointsReached: 1,
            completedNaturally: false, startedAt: Date(), endedAt: Date(),
            placeId: placeId, latitude: latitude, longitude: longitude
        )
    }

    // MARK: - Live ends stamp

    func testStop_carriesTheStampIntoTheHistoryWrite() async {
        let logger = FakeFocusLogger()
        let placeId = UUID()
        let sut = FocusSessionService(
            logger: logger,
            locationStamp: { LocationStamp(coordinate: self.coordinate, placeId: placeId) }
        )
        sut.start(taskId: nil, taskTitle: "Draft the review", lifeAreaEmoji: "💼", durationSeconds: 100)

        await sut.stop()

        XCTAssertEqual(logger.logged.first?.placeId, placeId)
        XCTAssertEqual(logger.logged.first?.latitude, coordinate.latitude)
        XCTAssertEqual(logger.logged.first?.longitude, coordinate.longitude)
    }

    /// Tagging off, permission absent, no fix — the sprint's history write must land exactly as
    /// it would have. A location lookup must never be why a finished sprint goes unrecorded.
    func testStop_withNoStamp_stillLogsTheSprint() async {
        let logger = FakeFocusLogger()
        let sut = FocusSessionService(logger: logger, locationStamp: { nil })
        sut.start(taskId: nil, taskTitle: "Draft the review", lifeAreaEmoji: "💼", durationSeconds: 100)

        await sut.stop()

        XCTAssertEqual(logger.logged.count, 1)
        XCTAssertNil(logger.logged.first?.placeId)
        XCTAssertNil(logger.logged.first?.latitude)
    }

    /// Starting a new sprint displaces the one in flight — the user is right there starting the
    /// replacement, so the displaced sprint's record is a live end and stamps like one.
    func testStart_replacementLogsTheDisplacedSprintStamped() async {
        let logger = FakeFocusLogger()
        let sut = FocusSessionService(
            logger: logger,
            locationStamp: { LocationStamp(coordinate: self.coordinate, placeId: nil) }
        )
        sut.start(taskId: nil, taskTitle: "First", lifeAreaEmoji: "💼", durationSeconds: 100)

        sut.start(taskId: nil, taskTitle: "Second", lifeAreaEmoji: "📚", durationSeconds: 100)
        for _ in 0..<10 { await Task.yield() }

        XCTAssertEqual(logger.logged.count, 1)
        XCTAssertEqual(logger.logged.first?.taskTitle, "First")
        XCTAssertEqual(logger.logged.first?.latitude, coordinate.latitude)
    }

    // MARK: - Dead ends do not

    /// A sprint that ran out while the app was dead is settled and logged on restore — but
    /// UNSTAMPED, and without even requesting a fix: the device's location at `endedAt` is
    /// unknown by now, and a wrong place is worse than none.
    func testRestore_expiredSprintLogsUnstampedAndRequestsNoFix() async {
        let logger = FakeFocusLogger()
        let store = FakeFocusSprintStore()
        let referenceNow = Date(timeIntervalSince1970: 1_800_000_000)
        store.stored = PersistedFocusSprint(
            session: FocusSession(
                taskId: nil, taskTitle: "While dead", lifeAreaEmoji: "💼", durationSeconds: 60
            ),
            startedAt: referenceNow.addingTimeInterval(-120),
            deadline: referenceNow.addingTimeInterval(-60),
            cadence: .count(1)
        )
        var stampRequests = 0
        let sut = FocusSessionService(
            logger: logger,
            sprintStore: store,
            locationStamp: {
                stampRequests += 1
                return LocationStamp(coordinate: self.coordinate, placeId: nil)
            },
            now: { referenceNow }
        )

        await sut.restorePersistedSprint()

        XCTAssertEqual(logger.logged.count, 1, "an expired sprint is still settled and logged")
        XCTAssertNil(logger.logged.first?.placeId)
        XCTAssertNil(logger.logged.first?.latitude)
        XCTAssertEqual(stampRequests, 0, "a dead-end sprint must not stamp where the user is NOW")
    }

    // MARK: - The model carries it to Firestore

    /// The pure copy helper behind the service: with a stamp all three fields ride; with none the
    /// record is untouched.
    func testStamped_appliesTheStampAdditively() {
        let unstamped = record()
        let placeId = UUID()

        let stamped = unstamped.stamped(with: LocationStamp(coordinate: coordinate, placeId: placeId))

        XCTAssertEqual(stamped.placeId, placeId)
        XCTAssertEqual(stamped.latitude, coordinate.latitude)
        XCTAssertEqual(stamped.longitude, coordinate.longitude)
        XCTAssertEqual(stamped.taskTitle, unstamped.taskTitle)
        XCTAssertEqual(unstamped.stamped(with: nil), unstamped)
    }

    /// Focus sessions are snake_cased like tasks, so `place_id` — asserted both ways because a
    /// wrong key writes a field nothing reads, and raises nothing.
    func testCompletedFocusSession_encodesTheLocationFieldsWithTheExpectedSpelling() throws {
        let placeId = UUID()
        let stamped = record(placeId: placeId, latitude: 51.5152, longitude: -0.1418)

        let data = try JSONEncoder().encode(stamped)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["place_id"] as? String, placeId.uuidString)
        XCTAssertEqual(json["latitude"] as? Double, 51.5152)
        XCTAssertEqual(json["longitude"] as? Double, -0.1418)
        XCTAssertNil(json["placeId"], "the camelCase spelling belongs to captures")
    }

    /// Every sprint recorded before this shipped has none of these fields; they must decode as
    /// absent rather than failing the analytics' whole history read.
    func testCompletedFocusSession_decodesADocumentWithNoLocationFields() throws {
        let legacy = Data("""
        {"id":"5B1E4C1E-0000-0000-0000-000000000007","task_title":"Draft","life_area_emoji":"💼",\
        "planned_seconds":1500,"focused_seconds":900,"checkpoints_reached":1,\
        "completed_naturally":true,"started_at":0,"ended_at":900}
        """.utf8)

        let decoded = try JSONDecoder().decode(CompletedFocusSession.self, from: legacy)

        XCTAssertNil(decoded.placeId)
        XCTAssertNil(decoded.latitude)
        XCTAssertNil(decoded.longitude)
        XCTAssertEqual(decoded.taskTitle, "Draft")
    }
}
