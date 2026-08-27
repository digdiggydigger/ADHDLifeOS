//
//  LocationEventTimelineTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The silent timeline log (block 4c): fence crossings become quiet event rows between journal
/// entries — pure memory, never an interruption. These pin the recording fan-out, the wire
/// format, and the timeline rules (everything-view only, dangling places dropped).
@MainActor
final class LocationEventTimelineTests: XCTestCase {

    private final class FakeRecorder: LocationEventRecording {
        var recordError: Error?
        private(set) var recorded: [LocationEvent] = []

        func record(_ event: LocationEvent) async throws {
            recorded.append(event)
            if let recordError { throw recordError }
        }
    }

    private let noon = Date(timeIntervalSince1970: 1_756_296_000)

    private func place(name: String = "The Office", emoji: String? = "💼") -> Place {
        Place(
            id: UUID(), name: name,
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: emoji
        )
    }

    private func event(placeId: UUID, kind: PlaceTriggerEvent.Kind = .arrival, at date: Date) -> LocationEvent {
        LocationEvent(id: UUID(), placeId: placeId, kind: kind, occurredAt: date)
    }

    // MARK: - The handler records

    func testHandler_recordsACrossingAsAnEvent() async {
        let recorder = FakeRecorder()
        let sut = PlaceTriggerEventHandler(recorder: recorder)
        let placeId = UUID()

        await sut.handle(PlaceTriggerEvent(placeId: placeId, kind: .departure, occurredAt: noon))

        XCTAssertEqual(recorder.recorded.count, 1)
        XCTAssertEqual(recorder.recorded.first?.placeId, placeId)
        XCTAssertEqual(recorder.recorded.first?.kind, .departure)
        XCTAssertEqual(recorder.recorded.first?.occurredAt, noon)
    }

    /// The record is garnish on the timeline — a failed write must vanish quietly, never crash
    /// or surface an error from a background wake.
    func testHandler_recordFailureIsQuiet() async {
        let recorder = FakeRecorder()
        recorder.recordError = URLError(.notConnectedToInternet)
        let sut = PlaceTriggerEventHandler(recorder: recorder)

        await sut.handle(PlaceTriggerEvent(placeId: UUID(), kind: .arrival, occurredAt: noon))

        XCTAssertEqual(recorder.recorded.count, 1)
    }

    // MARK: - The wire

    func testLocationEvent_encodesWithTheExpectedSpelling() throws {
        let placeId = UUID()
        let event = LocationEvent(id: UUID(), placeId: placeId, kind: .arrival, occurredAt: noon)

        let data = try JSONEncoder().encode(event)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["place_id"] as? String, placeId.uuidString)
        XCTAssertEqual(json["kind"] as? String, "arrival")
        XCTAssertNotNil(json["occurred_at"])
        XCTAssertNil(json["placeId"], "location events are snake_cased like every new collection")
    }

    // MARK: - The timeline rules

    func testDays_interleavesEventsByTimestamp() {
        let office = place()
        let log = Log(
            id: UUID(), lifeAreaId: nil, type: .journal, body: "Standup went fine",
            entryDate: noon.addingTimeInterval(600), createdAt: noon.addingTimeInterval(600)
        )
        let arrival = event(placeId: office.id, at: noon)

        let days = JournalTimeline.days(
            logs: [log], tasks: [],
            locationEvents: [arrival], places: [office],
            asOf: noon
        )

        XCTAssertEqual(days.count, 1)
        XCTAssertEqual(days.first?.entries.count, 2)
        // Newest first within the day: the entry written after the arrival leads.
        XCTAssertEqual(days.first?.entries.first?.id, log.id)
        XCTAssertEqual(days.first?.entries.last?.id, arrival.id)
    }

    /// Events are ambient garnish, not a category: they appear in the Everything view only, and
    /// never under a life-area filter — movement has no life area.
    func testDays_eventsOnlyAppearInTheEverythingView() {
        let office = place()
        let arrival = event(placeId: office.id, at: noon)

        let written = JournalTimeline.days(
            logs: [], tasks: [],
            locationEvents: [arrival], places: [office],
            filter: .written, asOf: noon
        )
        let filtered = JournalTimeline.days(
            logs: [], tasks: [],
            locationEvents: [arrival], places: [office],
            lifeAreaId: UUID(), asOf: noon
        )

        XCTAssertTrue(written.isEmpty)
        XCTAssertTrue(filtered.isEmpty)
    }

    /// A place deleted since leaves dangling events. They are dropped rather than rendered as a
    /// raw UUID — and dropped BEFORE day-grouping, so they can't leave an empty day header.
    func testDays_dropsEventsWhosePlaceIsGone() {
        let days = JournalTimeline.days(
            logs: [], tasks: [],
            locationEvents: [event(placeId: UUID(), at: noon)], places: [],
            asOf: noon
        )

        XCTAssertTrue(days.isEmpty)
    }

    // MARK: - The row's words

    func testEventLine_readsAsArrivedOrLeft() {
        let office = place()
        let home = place(name: "Home", emoji: "🏠")

        XCTAssertEqual(
            JournalTimeline.locationEventLine(
                for: event(placeId: office.id, at: noon), places: [office, home]
            ),
            "Arrived at The Office 💼"
        )
        XCTAssertEqual(
            JournalTimeline.locationEventLine(
                for: event(placeId: home.id, kind: .departure, at: noon), places: [office, home]
            ),
            "Left Home 🏠"
        )
    }

    func testEventLine_withoutAnEmojiUsesTheBareName() {
        let park = place(name: "The Park", emoji: nil)

        XCTAssertEqual(
            JournalTimeline.locationEventLine(
                for: event(placeId: park.id, at: noon), places: [park]
            ),
            "Arrived at The Park"
        )
    }

    // MARK: - The journal loads them beside the entries

    func testJournalService_loadFetchesEventsAndPlacesNonBlocking() async {
        let fake = FakeJournalClientAdapting()
        let office = place()
        fake.locationEventsResult = .success([event(placeId: office.id, at: noon)])
        fake.placesResult = .success([office])
        let sut = JournalService(client: fake, locationStamp: { nil })

        await sut.load()

        XCTAssertEqual(sut.locationEvents.count, 1)
        XCTAssertEqual(sut.places.map(\.name), ["The Office"])
    }
}
