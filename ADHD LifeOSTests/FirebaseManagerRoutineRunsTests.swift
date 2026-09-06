//
//  FirebaseManagerRoutineRunsTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The routine record against REAL Firestore (emulator + the repo's live rules): a
/// `routine_runs` document must be creatable, UPDATABLE — this is the one new collection that
/// is not append-only, so the rules must place it in the generic owner-CRUD match — and must
/// decode back through the codec with every stamp intact. A recording fake cannot catch a
/// rules rejection; this can, and it is the cheapest rules check available.
final class FirebaseManagerRoutineRunsTests: XCTestCase {
    private var manager: FirebaseManager { .shared }
    private let noon = Date(timeIntervalSince1970: 1_756_296_000)

    override func setUp() async throws {
        try await super.setUp()
        try await FirebaseEmulatorHarness.requireEmulator()
        try await FirebaseEmulatorHarness.signUpEmptyUser()
    }

    override func tearDown() async throws {
        await FirebaseEmulatorHarness.tearDownCurrentUser()
        try await super.tearDown()
    }

    func testARun_isCreatedUpdatedThroughItsLifecycleAndReadBack() async throws {
        let run = gymRun()
        let offered = RoutineRunRecord.offered(run, now: noon)
        try await manager.createRoutineRun(offered)

        try await manager.updateRoutineRun(
            id: run.id, fields: FirestoreFieldPayloads.routineRunStarted(at: noon.addingTimeInterval(60))
        )
        var progressed = run
        progressed.activatedAt = noon.addingTimeInterval(60)
        progressed = PlaceRoutineProgress.marking(progressed, stepAt: 0, as: .done, at: noon.addingTimeInterval(90))
        try await manager.updateRoutineRun(
            id: run.id,
            fields: try FirestoreFieldPayloads.routineRunProgressed(progressed, at: noon.addingTimeInterval(90))
        )
        try await manager.updateRoutineRun(
            id: run.id,
            fields: FirestoreFieldPayloads.routineRunEnded(reason: .completed, at: noon.addingTimeInterval(120))
        )

        let all = try await manager.fetchRoutineRuns()
        let fetched = try XCTUnwrap(all.first { $0.id == run.id })
        XCTAssertEqual(fetched.phase, .ended)
        XCTAssertEqual(fetched.status, .ended)
        XCTAssertEqual(fetched.dismissalMethod, .tap)
        XCTAssertEqual(fetched.endReason, .completed)
        XCTAssertEqual(fetched.completedStepsCount, 1)
        XCTAssertEqual(fetched.timeSpentSeconds, 30)
        XCTAssertEqual(fetched.steps.map(\.state), [.done, .pending])
        XCTAssertEqual(
            fetched.startedAt?.timeIntervalSince1970 ?? 0,
            noon.addingTimeInterval(60).timeIntervalSince1970, accuracy: 0.01
        )
    }

    func testFetch_returnsNewestOfferFirst() async throws {
        let older = RoutineRunRecord.offered(gymRun(offeredAt: noon), now: noon)
        let newer = RoutineRunRecord.offered(gymRun(offeredAt: noon.addingTimeInterval(3_600)), now: noon)
        try await manager.createRoutineRun(older)
        try await manager.createRoutineRun(newer)

        let fetched = try await manager.fetchRoutineRuns()

        XCTAssertEqual(fetched.map(\.id), [newer.id, older.id])
    }

    private func gymRun(offeredAt: Date? = nil) -> RoutineRun {
        let gymId = UUID()
        let actions = [
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "spotify", displayName: "Spotify")),
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "gym", displayName: "Gym"))
        ]
        return RoutineRun.make(
            event: PlaceTriggerEvent(placeId: gymId, kind: .arrival, occurredAt: offeredAt ?? noon),
            entry: AtPlaceSnapshot.PlaceEntry(
                placeId: gymId, displayName: "Gym 🏋️", openTaskTitles: [],
                arrivalMessage: nil, actions: actions, latitude: nil, longitude: nil
            ),
            plan: PlaceRoutinePlan.make(actions, for: .arrival)
        )
    }
}
