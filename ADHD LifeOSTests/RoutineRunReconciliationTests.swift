//
//  RoutineRunReconciliationTests.swift
//  ADHD LifeOSTests
//
//  Site 6 of the routine record (F-RoutineRecord-1): the passive endings. iOS never reports
//  an ignored banner, and the arc owns no timer, so "timed out" is DERIVED on read by the
//  same lifetime rules a live run obeys — then written ONCE, stamped with the moment the
//  lifetime actually lapsed rather than the moment somebody happened to look.
//

import XCTest
@testable import ADHD_LifeOS

final class RoutineRunReconciliationTests: XCTestCase {
    /// 2025-08-27 12:00:00 UTC — the routine harness's noon, in a fixed zone so "the end of
    /// the day" is one specific instant.
    private let noon = Date(timeIntervalSince1970: 1_756_296_000)
    private let midnightAfter = Date(timeIntervalSince1970: 1_756_339_200)

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    // MARK: - The lapse moment

    func testExpiry_arrivalLapsesAtTheEndOfItsDay() {
        XCTAssertEqual(
            RoutineRunLifecycle.expiry(direction: .arrival, startedAt: noon, calendar: utc), midnightAfter
        )
    }

    func testExpiry_departureLapsesAtItsWindow() {
        XCTAssertEqual(
            RoutineRunLifecycle.expiry(direction: .departure, startedAt: noon, calendar: utc),
            noon.addingTimeInterval(RoutineDefaults.departureRunWindow)
        )
    }

    func testExpiry_departureNeverOutlivesItsDay() {
        let lateEvening = midnightAfter.addingTimeInterval(-60)

        XCTAssertEqual(
            RoutineRunLifecycle.expiry(direction: .departure, startedAt: lateEvening, calendar: utc),
            midnightAfter
        )
    }

    // MARK: - Unopened offers time out

    func testStaleOffer_expiresAtItsLapseMoment_notNow() {
        let offer = record(direction: .arrival, offeredAt: noon)

        let updates = RoutineRunReconciliation.updates(
            records: [offer], liveRunId: nil, now: midnightAfter.addingTimeInterval(3_600), calendar: utc
        )

        XCTAssertEqual(updates, [.expired(runId: offer.id, lapsedAt: midnightAfter)])
    }

    func testFreshOffer_isLeftAlone() {
        let offer = record(direction: .arrival, offeredAt: noon)

        let updates = RoutineRunReconciliation.updates(
            records: [offer], liveRunId: nil, now: noon.addingTimeInterval(3_600), calendar: utc
        )

        XCTAssertTrue(updates.isEmpty)
    }

    func testStaleDepartureOffer_expiresAtTheWindow() {
        let offer = record(direction: .departure, offeredAt: noon)

        let updates = RoutineRunReconciliation.updates(
            records: [offer], liveRunId: nil, now: noon.addingTimeInterval(3_600), calendar: utc
        )

        XCTAssertEqual(updates, [
            .expired(runId: offer.id, lapsedAt: noon.addingTimeInterval(RoutineDefaults.departureRunWindow))
        ])
    }

    // MARK: - Started runs lapse with a reason

    func testStaleStartedArrivalRun_endsAsDayEnded() {
        var run = record(direction: .arrival, offeredAt: noon)
        run.started(at: noon.addingTimeInterval(60))

        let updates = RoutineRunReconciliation.updates(
            records: [run], liveRunId: nil, now: midnightAfter.addingTimeInterval(60), calendar: utc
        )

        XCTAssertEqual(updates, [.ended(runId: run.id, reason: .dayEnded, lapsedAt: midnightAfter)])
    }

    func testStaleStartedDepartureRun_endsAsWindowLapsed() {
        var run = record(direction: .departure, offeredAt: noon)
        run.started(at: noon.addingTimeInterval(60))

        let updates = RoutineRunReconciliation.updates(
            records: [run], liveRunId: nil, now: noon.addingTimeInterval(3_600), calendar: utc
        )

        let window = noon.addingTimeInterval(RoutineDefaults.departureRunWindow)
        XCTAssertEqual(updates, [.ended(runId: run.id, reason: .windowLapsed, lapsedAt: window)])
    }

    func testLateDepartureRunCutOffByMidnight_endsAsDayEnded() {
        var run = record(direction: .departure, offeredAt: midnightAfter.addingTimeInterval(-60))
        run.started(at: midnightAfter.addingTimeInterval(-30))

        let updates = RoutineRunReconciliation.updates(
            records: [run], liveRunId: nil, now: midnightAfter.addingTimeInterval(3_600), calendar: utc
        )

        XCTAssertEqual(updates, [.ended(runId: run.id, reason: .dayEnded, lapsedAt: midnightAfter)])
    }

    // MARK: - What is never touched

    func testTheLiveRun_isNeverTouched() {
        var run = record(direction: .arrival, offeredAt: noon)
        run.started(at: noon.addingTimeInterval(60))

        let updates = RoutineRunReconciliation.updates(
            records: [run], liveRunId: run.id, now: midnightAfter.addingTimeInterval(60), calendar: utc
        )

        XCTAssertTrue(updates.isEmpty, "the local store owns the live run; it ends it, not this")
    }

    func testTerminalRecords_areNeverTouchedTwice() {
        var ended = record(direction: .arrival, offeredAt: noon)
        ended.started(at: noon.addingTimeInterval(60))
        ended.ended(at: noon.addingTimeInterval(600), reason: .completed)
        var expired = record(direction: .arrival, offeredAt: noon)
        expired.expired(at: midnightAfter)
        var dismissed = record(direction: .arrival, offeredAt: noon)
        dismissed.dismissed(at: noon.addingTimeInterval(30))

        let updates = RoutineRunReconciliation.updates(
            records: [ended, expired, dismissed], liveRunId: nil,
            now: midnightAfter.addingTimeInterval(86_400), calendar: utc
        )

        XCTAssertTrue(updates.isEmpty)
    }

    // MARK: - Applying locally, so the screen need not wait for the write

    func testApplying_marksTheLocalCopiesTheSameWayTheWriteWill() {
        let offer = record(direction: .arrival, offeredAt: noon)
        var run = record(direction: .departure, offeredAt: noon)
        run.started(at: noon.addingTimeInterval(60))
        let updates = RoutineRunReconciliation.updates(
            records: [offer, run], liveRunId: nil, now: midnightAfter.addingTimeInterval(60), calendar: utc
        )

        let applied = RoutineRunReconciliation.applying(updates, to: [offer, run])

        XCTAssertEqual(applied[0].phase, .expired)
        XCTAssertEqual(applied[0].expiredAt, midnightAfter)
        XCTAssertEqual(applied[0].dismissalMethod, .timeout)
        XCTAssertEqual(applied[1].phase, .ended)
        XCTAssertEqual(applied[1].endReason, .windowLapsed)
    }

    // MARK: - Fixture

    private func record(direction: PlaceTriggerEvent.Kind, offeredAt: Date) -> RoutineRunRecord {
        let placeId = UUID()
        let actions = [
            PlaceAction(id: UUID(), direction: direction == .arrival ? .arrival : .departure,
                        kind: .openApp(scheme: "spotify", displayName: "Spotify")),
            PlaceAction(id: UUID(), direction: direction == .arrival ? .arrival : .departure,
                        kind: .openApp(scheme: "gym", displayName: "Gym"))
        ]
        let run = RoutineRun.make(
            event: PlaceTriggerEvent(placeId: placeId, kind: direction, occurredAt: offeredAt),
            entry: AtPlaceSnapshot.PlaceEntry(
                placeId: placeId, displayName: "Gym 🏋️", openTaskTitles: [],
                arrivalMessage: nil, actions: actions, latitude: nil, longitude: nil
            ),
            plan: PlaceRoutinePlan.make(actions, for: direction)
        )
        return RoutineRunRecord.offered(run, now: offeredAt)
    }
}
