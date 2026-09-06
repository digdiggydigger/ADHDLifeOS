//
//  RoutineRunHistoryServiceTests.swift
//  ADHD LifeOSTests
//
//  The Tools section's read of the routine record (F-RoutineRecord-2-Surfaces): fetch,
//  reconcile the passive endings exactly as the Journal load does — ONE reconciler type,
//  shared, so the two loads cannot drift — and publish. Garnish like every side stream: a
//  failed fetch is an empty list, never an error state.
//

import XCTest
@testable import ADHD_LifeOS

@MainActor
final class RoutineRunHistoryServiceTests: XCTestCase {
    private let noon = Date(timeIntervalSince1970: 1_756_296_000)
    private let midnightAfter = Date(timeIntervalSince1970: 1_756_339_200)

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private final class FakeReader: RoutineRunHistoryReading, @unchecked Sendable {
        var result: Result<[RoutineRunRecord], Error> = .success([])
        func fetchRoutineRuns() async throws -> [RoutineRunRecord] { try result.get() }
    }

    func testLoad_publishesTheRunsReconciled() async {
        let reader = FakeReader()
        let recorder = FakeRoutineRunRecorder()
        let stale = record(offeredAt: noon)
        reader.result = .success([stale])
        let reconciler = RoutineRunReconciler(
            recorder: recorder, liveRunId: { nil }, now: { self.midnightAfter.addingTimeInterval(60) }, calendar: utc
        )
        let sut = RoutineRunHistoryService(reader: reader, reconciler: reconciler)

        await sut.load()
        await reconciler.writeTask?.value

        XCTAssertEqual(sut.runs.map(\.phase), [.expired])
        XCTAssertEqual(recorder.events, ["expired"])
    }

    func testLoad_survivesAFailedFetch() async {
        let reader = FakeReader()
        reader.result = .failure(URLError(.notConnectedToInternet))
        let sut = RoutineRunHistoryService(
            reader: reader,
            reconciler: RoutineRunReconciler(
                recorder: FakeRoutineRunRecorder(), liveRunId: { nil }, now: { self.noon }, calendar: utc
            )
        )

        await sut.load()

        XCTAssertTrue(sut.runs.isEmpty)
    }

    private func record(offeredAt: Date) -> RoutineRunRecord {
        let placeId = UUID()
        let actions = [
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "a", displayName: "A")),
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "b", displayName: "B"))
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
