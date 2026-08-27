//
//  ArrivalNudgeTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The notification nudge (block 4c, variation A) — the one surfacing that can interrupt, and
/// therefore the one whose restraint rules matter most: the EMPTY CASE NEVER FIRES, a bouncing
/// fence never double-fires, and content comes from the local snapshot because a background wake
/// cannot count on a network.
@MainActor
final class ArrivalNudgeTests: XCTestCase {

    private final class FakeNotifier: ImmediateNotifying {
        private(set) var posted: [(title: String, body: String)] = []

        func post(title: String, body: String, identifier: String) async {
            posted.append((title, body))
        }
    }

    private final class FakeStore: ArrivalNudgeStateStoring {
        var snapshot: AtPlaceSnapshot?
        var cooldowns = TriggerCooldownState()

        func readSnapshot() -> AtPlaceSnapshot? { snapshot }
        func writeSnapshot(_ new: AtPlaceSnapshot) { snapshot = new }
        func readCooldowns() -> TriggerCooldownState { cooldowns }
        func writeCooldowns(_ new: TriggerCooldownState) { cooldowns = new }
    }

    private final class FakeRecorder: LocationEventRecording {
        private(set) var recorded: [LocationEvent] = []
        func record(_ event: LocationEvent) async throws { recorded.append(event) }
    }

    private let noon = Date(timeIntervalSince1970: 1_756_296_000)
    private let tescoId = UUID()

    private func snapshot(titles: [String] = ["Return the parcel", "Buy AA batteries"]) -> AtPlaceSnapshot {
        AtPlaceSnapshot(entries: [
            AtPlaceSnapshot.PlaceEntry(placeId: tescoId, displayName: "Tesco 🛒", openTaskTitles: titles)
        ])
    }

    private func arrival(at date: Date? = nil) -> PlaceTriggerEvent {
        PlaceTriggerEvent(placeId: tescoId, kind: .arrival, occurredAt: date ?? noon)
    }

    private func makeSUT(
        store: FakeStore, notifier: FakeNotifier, recorder: FakeRecorder = FakeRecorder(),
        enabled: Bool = true
    ) -> PlaceTriggerEventHandler {
        PlaceTriggerEventHandler(
            recorder: recorder, notifier: notifier, store: store, isEnabled: { enabled }
        )
    }

    // MARK: - Content

    func testContent_arrivalNamesThePlaceAndItsTasks() {
        let content = ArrivalNudgeContent.notification(for: arrival(), snapshot: snapshot())

        XCTAssertEqual(content?.title, "You're at Tesco 🛒")
        XCTAssertEqual(content?.body, "2 things live here — Return the parcel · Buy AA batteries")
    }

    func testContent_arrivalWithOneTaskReadsSingular() {
        let content = ArrivalNudgeContent.notification(
            for: arrival(), snapshot: snapshot(titles: ["Return the parcel"])
        )

        XCTAssertEqual(content?.body, "1 thing lives here — Return the parcel")
    }

    /// A long list is truncated, never dumped — a notification is a glance, not a screen.
    func testContent_capsTheTitlesAtTwo() {
        let content = ArrivalNudgeContent.notification(
            for: arrival(), snapshot: snapshot(titles: ["One", "Two", "Three", "Four"])
        )

        XCTAssertEqual(content?.body, "4 things live here — One · Two · +2 more")
    }

    func testContent_departureNamesWhatIsStillOpen() {
        let event = PlaceTriggerEvent(placeId: tescoId, kind: .departure, occurredAt: noon)

        let single = ArrivalNudgeContent.notification(
            for: event, snapshot: snapshot(titles: ["Return the parcel"])
        )
        let plural = ArrivalNudgeContent.notification(for: event, snapshot: snapshot())

        XCTAssertEqual(single?.title, "Leaving Tesco 🛒")
        XCTAssertEqual(single?.body, "\u{201C}Return the parcel\u{201D} is still open here.")
        XCTAssertEqual(plural?.body, "2 things are still open here.")
    }

    /// The single most important rule in variation A: NO open tasks means NO notification —
    /// an empty nudge is exactly how E learns to ignore the feature.
    func testContent_emptyCaseNeverFires() {
        XCTAssertNil(ArrivalNudgeContent.notification(for: arrival(), snapshot: nil))
        XCTAssertNil(ArrivalNudgeContent.notification(for: arrival(), snapshot: snapshot(titles: [])))
        XCTAssertNil(ArrivalNudgeContent.notification(
            for: PlaceTriggerEvent(placeId: UUID(), kind: .arrival, occurredAt: noon),
            snapshot: snapshot()
        ))
    }

    // MARK: - Cooldown

    func testCooldown_blocksARepeatWithinTheInterval() {
        var state = TriggerCooldownState()
        XCTAssertTrue(TriggerCooldown.shouldFire(arrival(), state: state, now: noon))

        state = TriggerCooldown.recording(arrival(), in: state)

        let bounce = arrival(at: noon.addingTimeInterval(60))
        XCTAssertFalse(
            TriggerCooldown.shouldFire(bounce, state: state, now: bounce.occurredAt),
            "a fence bounce must not double-fire"
        )

        let muchLater = arrival(at: noon.addingTimeInterval(TriggerCooldown.minimumInterval + 1))
        XCTAssertTrue(TriggerCooldown.shouldFire(muchLater, state: state, now: muchLater.occurredAt))
    }

    /// Arrival and departure cool down independently — arriving must not swallow the departure
    /// nudge for the same place minutes later.
    func testCooldown_kindsAreIndependent() {
        var state = TriggerCooldownState()
        state = TriggerCooldown.recording(arrival(), in: state)

        let departure = PlaceTriggerEvent(
            placeId: tescoId, kind: .departure, occurredAt: noon.addingTimeInterval(120)
        )

        XCTAssertTrue(TriggerCooldown.shouldFire(departure, state: state, now: departure.occurredAt))
    }

    // MARK: - The handler puts it together

    func testHandle_firesTheNudgeAndRecordsTheCooldown() async {
        let store = FakeStore()
        store.snapshot = snapshot()
        let notifier = FakeNotifier()
        let sut = makeSUT(store: store, notifier: notifier)

        await sut.handle(arrival())
        await sut.handle(arrival(at: noon.addingTimeInterval(60)))

        XCTAssertEqual(notifier.posted.count, 1, "the bounce must be swallowed by the cooldown")
        XCTAssertEqual(notifier.posted.first?.title, "You're at Tesco 🛒")
    }

    /// The crossing is still RECORDED for the timeline even when nothing is worth a nudge — the
    /// silent log and the notification are independent surfacings of one event.
    func testHandle_emptyPlaceRecordsButNeverNotifies() async {
        let store = FakeStore()
        let notifier = FakeNotifier()
        let recorder = FakeRecorder()
        let sut = makeSUT(store: store, notifier: notifier, recorder: recorder)

        await sut.handle(arrival())

        XCTAssertTrue(notifier.posted.isEmpty)
        XCTAssertEqual(recorder.recorded.count, 1)
    }

    /// The master switch is consulted at FIRE time too — a fence iOS delivers moments after the
    /// switch went off must die here, not nudge one last time.
    func testHandle_killSwitchOffNeverNotifies() async {
        let store = FakeStore()
        store.snapshot = snapshot()
        let notifier = FakeNotifier()
        let sut = makeSUT(store: store, notifier: notifier, enabled: false)

        await sut.handle(arrival())

        XCTAssertTrue(notifier.posted.isEmpty)
    }

    /// An unfired nudge must not consume the cooldown — otherwise an empty arrival inoculates
    /// the place against the real nudge half an hour later.
    func testHandle_onlyAFiredNudgeConsumesTheCooldown() async {
        let store = FakeStore()
        let notifier = FakeNotifier()
        let sut = makeSUT(store: store, notifier: notifier)

        await sut.handle(arrival())
        store.snapshot = snapshot()
        await sut.handle(arrival(at: noon.addingTimeInterval(60)))

        XCTAssertEqual(notifier.posted.count, 1)
    }

    // MARK: - The snapshot

    func testSnapshotBuild_capturesOpenAtPlaceTasksByPriority() {
        let tesco = Place(
            id: tescoId, name: "Tesco",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🛒", nudgeOnArrival: true
        )
        let tasks = [
            TaskItem(
                id: UUID(), lifeAreaId: nil, title: "Return the parcel", status: .open,
                priority: .p3, dueDate: nil, atPlaceId: tescoId
            ),
            TaskItem(
                id: UUID(), lifeAreaId: nil, title: "Buy AA batteries", status: .open,
                priority: .p1, dueDate: nil, atPlaceId: tescoId
            ),
            TaskItem(
                id: UUID(), lifeAreaId: nil, title: "Closed here", status: .done,
                priority: .p1, dueDate: nil, atPlaceId: tescoId
            ),
            TaskItem(
                id: UUID(), lifeAreaId: nil, title: "Belongs nowhere", status: .open,
                priority: .p1, dueDate: nil
            )
        ]

        let built = AtPlaceSnapshot.build(places: [tesco], tasks: tasks)

        XCTAssertEqual(built.entries.count, 1)
        XCTAssertEqual(built.entries.first?.displayName, "Tesco 🛒")
        XCTAssertEqual(built.entries.first?.openTaskTitles, ["Buy AA batteries", "Return the parcel"])
    }

    func testSnapshotStore_roundTrips() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "arrival-nudge-tests"))
        defaults.removePersistentDomain(forName: "arrival-nudge-tests")
        let store = UserDefaultsArrivalNudgeStateStore(defaults: defaults)

        store.writeSnapshot(snapshot())
        var cooldowns = TriggerCooldownState()
        cooldowns = TriggerCooldown.recording(arrival(), in: cooldowns)
        store.writeCooldowns(cooldowns)

        XCTAssertEqual(store.readSnapshot(), snapshot())
        XCTAssertEqual(store.readCooldowns(), cooldowns)
    }
}

/// The per-place custom arrival message (E's follow-up, 2026-08-27): words E chose to hear on
/// arrival. Its presence changes the firing rule DELIBERATELY — the message is the content, so
/// the nudge is never empty and the empty-never-fires gate applies only to places without one.
@MainActor
final class ArrivalMessageTests: XCTestCase {

    private let noon = Date(timeIntervalSince1970: 1_756_296_000)
    private let tescoId = UUID()

    private func entry(
        titles: [String] = [], message: String? = nil
    ) -> AtPlaceSnapshot {
        AtPlaceSnapshot(entries: [
            AtPlaceSnapshot.PlaceEntry(
                placeId: tescoId, displayName: "Tesco 🛒",
                openTaskTitles: titles, arrivalMessage: message
            )
        ])
    }

    private func arrival() -> PlaceTriggerEvent {
        PlaceTriggerEvent(placeId: tescoId, kind: .arrival, occurredAt: noon)
    }

    private func departure() -> PlaceTriggerEvent {
        PlaceTriggerEvent(placeId: tescoId, kind: .departure, occurredAt: noon)
    }

    /// The message alone is enough — E wrote it, so arriving with zero open tasks still says it.
    func testContent_customMessageFiresWithoutTasks() {
        let content = ArrivalNudgeContent.notification(
            for: arrival(), snapshot: entry(message: "Remember why you came in here")
        )

        XCTAssertEqual(content?.title, "You're at Tesco 🛒")
        XCTAssertEqual(content?.body, "Remember why you came in here")
    }

    func testContent_customMessageAndTasksCompose() {
        let content = ArrivalNudgeContent.notification(
            for: arrival(),
            snapshot: entry(titles: ["Return the parcel"], message: "Locker code is 4821")
        )

        XCTAssertEqual(content?.body, "Locker code is 4821 — 1 thing lives here: Return the parcel")
    }

    /// Each crossing reads only its OWN words: an arrival message never speaks on the way out,
    /// so a place with one but nothing open departs silently. Departure got its own message on
    /// 2026-08-28 — see `DepartureMessageTests`.
    func testContent_departureIgnoresTheMessage() {
        XCTAssertNil(ArrivalNudgeContent.notification(
            for: departure(), snapshot: entry(message: "Locker code is 4821")
        ))
    }

    /// No message, no tasks — the original restraint rule is untouched.
    func testContent_withoutAMessageTheEmptyCaseStillNeverFires() {
        XCTAssertNil(ArrivalNudgeContent.notification(for: arrival(), snapshot: entry()))
    }

    // MARK: - The model and the editor carry it

    func testPlace_encodesTheArrivalMessageSnakeCased() throws {
        let place = Place(
            id: UUID(), name: "Tesco",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🛒",
            nudgeOnArrival: true, arrivalMessage: "Locker code is 4821"
        )

        let data = try JSONEncoder().encode(place)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["arrival_message"] as? String, "Locker code is 4821")
        XCTAssertNil(json["arrivalMessage"], "places are snake_cased throughout")
    }

    func testPlace_legacyDocumentDecodesWithNoMessage() throws {
        let legacy = Data("""
        {"id":"5B1E4C1E-0000-0000-0000-000000000009","name":"Tesco","latitude":51.5152,\
        "longitude":-0.1418,"radius_metres":150,"created_at":0}
        """.utf8)

        XCTAssertNil(try JSONDecoder().decode(Place.self, from: legacy).arrivalMessage)
    }

    /// A whitespace-only message stores nil, not "" — an empty string would count as "has a
    /// message" and turn every arrival into a blank nudge.
    func testMakePlace_trimsTheMessageToNil() {
        let made = PlaceEditorValidation.makePlace(
            id: UUID(), name: "Tesco",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🛒",
            nudgeOnArrival: true, arrivalMessage: "   "
        )

        XCTAssertEqual(made?.nudgeOnArrival, true)
        XCTAssertNil(made?.arrivalMessage)
    }

    func testSnapshotBuild_carriesTheMessage() {
        let tesco = Place(
            id: tescoId, name: "Tesco",
            coordinate: PlaceCoordinate(latitude: 51.5152, longitude: -0.1418),
            radiusMetres: 150, emoji: "🛒",
            nudgeOnArrival: true, arrivalMessage: "Locker code is 4821"
        )

        let built = AtPlaceSnapshot.build(places: [tesco], tasks: [])

        XCTAssertEqual(built.entries.first?.arrivalMessage, "Locker code is 4821")
        XCTAssertEqual(built.entries.first?.openTaskTitles, [])
    }
}
