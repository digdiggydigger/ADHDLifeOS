//
//  ToolsRoutinesLastRunTests.swift
//  ADHD LifeOSTests
//
//  The Tools Routines row's last-run line (F-RoutineRecord-2-Surfaces, E's call): "when did I
//  last do this" at a glance, from the newest STARTED record for that place and direction.
//  Rows with no history are byte-identical to before, and the catalog still decides nothing
//  about membership — `PlaceRoutinePlan` does.
//

import XCTest
@testable import ADHD_LifeOS

final class ToolsRoutinesLastRunTests: XCTestCase {
    /// 2025-08-27 12:00 UTC — a Wednesday.
    private let noon = Date(timeIntervalSince1970: 1_756_296_000)

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    func testARowWithNoHistory_isUnchanged() {
        let gym = gymPlace()

        let rows = ToolsRoutinesCatalog.rows(from: [gym], runs: [], now: noon, calendar: utc)

        XCTAssertEqual(rows.map(\.subtitle), ["Gym · 2 steps"])
    }

    func testARowWithAStartedRun_gainsTheLastRunLine() {
        let gym = gymPlace()
        var run = record(placeId: gym.id, direction: .arrival, offeredAt: noon.addingTimeInterval(-3_600))
        run.started(at: noon.addingTimeInterval(-3_500))
        run.completedStepsCount = 1

        let rows = ToolsRoutinesCatalog.rows(from: [gym], runs: [run], now: noon, calendar: utc)

        XCTAssertEqual(rows.map(\.subtitle), ["Gym · 2 steps · last run today, 1 of 2"])
    }

    func testTheNewestStartedRunWins_andOffersDoNotCount() {
        let gym = gymPlace()
        var older = record(placeId: gym.id, direction: .arrival, offeredAt: noon.addingTimeInterval(-172_800))
        older.started(at: noon.addingTimeInterval(-172_700))
        older.completedStepsCount = 2
        var newer = record(placeId: gym.id, direction: .arrival, offeredAt: noon.addingTimeInterval(-86_400))
        newer.started(at: noon.addingTimeInterval(-86_300))
        newer.completedStepsCount = 1
        let offerOnly = record(placeId: gym.id, direction: .arrival, offeredAt: noon)

        let rows = ToolsRoutinesCatalog.rows(
            from: [gym], runs: [offerOnly, older, newer], now: noon, calendar: utc
        )

        XCTAssertEqual(rows.map(\.subtitle), ["Gym · 2 steps · last run yesterday, 1 of 2"])
    }

    func testADepartureRun_doesNotTouchTheArrivalRow() {
        let gym = gymPlace(departureSteps: true)
        var departure = record(placeId: gym.id, direction: .departure, offeredAt: noon.addingTimeInterval(-60))
        departure.started(at: noon.addingTimeInterval(-30))
        departure.completedStepsCount = 2

        let rows = ToolsRoutinesCatalog.rows(from: [gym], runs: [departure], now: noon, calendar: utc)

        XCTAssertEqual(rows.map(\.subtitle), ["Gym · 2 steps", "Gym · 2 steps · last run today, 2 of 2"])
    }

    // MARK: - The day word

    func testLastRunPhrase_today_yesterday_weekday_thenDate() {
        XCTAssertEqual(phrase(startedAt: noon.addingTimeInterval(-60)), "last run today, 1 of 2")
        XCTAssertEqual(phrase(startedAt: noon.addingTimeInterval(-86_400)), "last run yesterday, 1 of 2")
        XCTAssertEqual(phrase(startedAt: noon.addingTimeInterval(-2 * 86_400)), "last run Mon, 1 of 2")
        XCTAssertEqual(phrase(startedAt: noon.addingTimeInterval(-6 * 86_400)), "last run Thu, 1 of 2")
        XCTAssertEqual(phrase(startedAt: noon.addingTimeInterval(-8 * 86_400)), "last run Aug 19, 1 of 2")
    }

    private func phrase(startedAt: Date) -> String {
        var run = record(placeId: UUID(), direction: .arrival, offeredAt: startedAt.addingTimeInterval(-10))
        run.started(at: startedAt)
        run.completedStepsCount = 1
        return ToolsRoutinesCatalog.lastRunPhrase(for: run, now: noon, calendar: utc)
    }

    // MARK: - Fixtures

    private func gymPlace(departureSteps: Bool = false) -> Place {
        var actions = [
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "spotify", displayName: "Spotify")),
            PlaceAction(id: UUID(), direction: .arrival, kind: .openApp(scheme: "gym", displayName: "Gym"))
        ]
        if departureSteps {
            actions += [
                PlaceAction(id: UUID(), direction: .departure, kind: .openApp(scheme: "maps", displayName: "Maps")),
                PlaceAction(id: UUID(), direction: .departure, kind: .openApp(scheme: "health", displayName: "Health"))
            ]
        }
        return Place(
            id: UUID(), name: "Gym",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🏋️", actions: actions
        )
    }

    private func record(placeId: UUID, direction: PlaceTriggerEvent.Kind, offeredAt: Date) -> RoutineRunRecord {
        let actionDirection: PlaceActionDirection = direction == .arrival ? .arrival : .departure
        let actions = [
            PlaceAction(id: UUID(), direction: actionDirection, kind: .openApp(scheme: "a", displayName: "A")),
            PlaceAction(id: UUID(), direction: actionDirection, kind: .openApp(scheme: "b", displayName: "B"))
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
