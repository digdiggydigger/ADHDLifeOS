//
//  JournalServiceRoutineRunsTests.swift
//  ADHD LifeOSTests
//
//  The Journal load is where the routine record's passive endings get WRITTEN (site 6,
//  F-RoutineRecord-1): it fetches the runs, derives what lapsed, applies that locally so the
//  screen is right immediately, and hands the writes to the recorder once. Garnish like the
//  other side streams — a failed fetch leaves the list empty and the journal loads anyway.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class JournalServiceRoutineRunsTests: XCTestCase {
    private let noon = Date(timeIntervalSince1970: 1_756_296_000)
    private let midnightAfter = Date(timeIntervalSince1970: 1_756_339_200)

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    func testLoad_publishesTheRuns() async {
        let fake = FakeJournalClientAdapting()
        let offer = record(offeredAt: noon)
        fake.routineRunsResult = .success([offer])
        let sut = JournalService(
            client: fake, routineRecorder: FakeRoutineRunRecorder(),
            liveRoutineRunId: { nil }, now: { self.noon.addingTimeInterval(60) }, calendar: utc
        )

        await sut.load()

        XCTAssertEqual(sut.routineRuns, [offer])
    }

    func testLoad_writesEachLapsedRunOnce_andShowsItLapsedImmediately() async {
        let fake = FakeJournalClientAdapting()
        let recorder = FakeRoutineRunRecorder()
        let stale = record(offeredAt: noon)
        var started = record(offeredAt: noon)
        started.started(at: noon.addingTimeInterval(60))
        fake.routineRunsResult = .success([stale, started])
        let sut = JournalService(
            client: fake, routineRecorder: recorder,
            liveRoutineRunId: { nil }, now: { self.midnightAfter.addingTimeInterval(60) }, calendar: utc
        )

        await sut.load()
        await sut.reconcileTask?.value

        XCTAssertEqual(recorder.events.sorted(), ["ended:day_ended", "expired"])
        XCTAssertEqual(recorder.expired.first?.runId, stale.id)
        XCTAssertEqual(recorder.expired.first?.at, midnightAfter, "stamped with the lapse, not the look")
        XCTAssertEqual(sut.routineRuns.map(\.phase), [.expired, .ended], "applied locally, no round trip")
    }

    func testLoad_leavesTheLiveRunToTheLocalStore() async {
        let fake = FakeJournalClientAdapting()
        let recorder = FakeRoutineRunRecorder()
        var live = record(offeredAt: noon)
        live.started(at: noon.addingTimeInterval(60))
        fake.routineRunsResult = .success([live])
        let sut = JournalService(
            client: fake, routineRecorder: recorder,
            liveRoutineRunId: { live.id }, now: { self.midnightAfter.addingTimeInterval(60) }, calendar: utc
        )

        await sut.load()
        await sut.reconcileTask?.value

        XCTAssertTrue(recorder.events.isEmpty)
        XCTAssertEqual(sut.routineRuns.first?.phase, .started)
    }

    func testLoad_survivesAFailedRunsFetch() async {
        let fake = FakeJournalClientAdapting()
        fake.routineRunsResult = .failure(JournalServiceError.fetchFailed("offline"))
        let sut = JournalService(
            client: fake, routineRecorder: FakeRoutineRunRecorder(),
            liveRoutineRunId: { nil }, now: { self.noon }, calendar: utc
        )

        await sut.load()

        XCTAssertTrue(sut.routineRuns.isEmpty)
        if case .failed = sut.state {
            XCTFail("the runs are garnish — their fetch failing must not fail the journal")
        }
    }

    private func record(offeredAt: Date) -> RoutineRunRecord {
        let placeId = UUID()
        let actions = [
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "spotify", displayName: "Spotify")),
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "gym", displayName: "Gym"))
        ]
        let run = RoutineRun.make(
            event: PlaceTriggerEvent(placeId: placeId, kind: .arrival, occurredAt: offeredAt),
            entry: AtPlaceSnapshot.PlaceEntry(
                placeId: placeId, displayName: "Gym 🏋️", openTaskTitles: [],
                arrivalMessage: nil, actions: actions, latitude: nil, longitude: nil
            ),
            plan: PlaceRoutinePlan.make(actions, for: .arrival)
        )
        return RoutineRunRecord.offered(run, now: offeredAt)
    }
}
