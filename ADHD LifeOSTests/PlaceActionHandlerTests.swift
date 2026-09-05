//
//  PlaceActionHandlerTests.swift
//  ADHD LifeOSTests
//

import XCTest
@testable import ADHD_LifeOS

/// The wake-path fan-out with actions in it (F-PlaceActions-3): auto-runs run themselves and
/// get reported, externals post one notification each, the cooldown is consumed only by real
/// activity, and every pre-actions gate — bounce, master switch, empty-never-fires — holds.
@MainActor
final class PlaceActionHandlerTests: XCTestCase {

    private struct PostedNotification: Equatable {
        let title: String
        let body: String
        let identifier: String
        let userInfo: [String: String]
    }

    private final class FakeNotifier: ImmediateNotifying {
        private(set) var posted: [PostedNotification] = []
        private(set) var categories: [String] = []
        private(set) var removedDelivered: [[String]] = []

        func post(title: String, body: String, identifier: String, userInfo: [String: String]) async {
            posted.append(PostedNotification(
                title: title, body: body, identifier: identifier, userInfo: userInfo
            ))
            categories.append("")
        }

        func post(
            title: String, body: String, identifier: String,
            userInfo: [String: String], categoryIdentifier: String
        ) async {
            posted.append(PostedNotification(
                title: title, body: body, identifier: identifier, userInfo: userInfo
            ))
            categories.append(categoryIdentifier)
        }

        func removeDelivered(identifiers: [String]) async {
            removedDelivered.append(identifiers)
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
        func record(_ event: LocationEvent) async throws {
            // A real record suspends — the duplicate-delivery test needs the handler to be
            // mid-flight when the second delivery lands, exactly as Firestore makes it live.
            await Task.yield()
            recorded.append(event)
        }
    }

    private final class WriterLog {
        private(set) var journalInputs: [NormalizedCreateLogInput] = []
        private(set) var captureInputs: [NormalizedCreateCaptureInput] = []
        var journalSucceeds = true

        func journal(_ input: NormalizedCreateLogInput) -> Bool {
            journalInputs.append(input)
            return journalSucceeds
        }

        func capture(_ input: NormalizedCreateCaptureInput) -> Bool {
            captureInputs.append(input)
            return true
        }
    }

    private let noon = Date(timeIntervalSince1970: 1_756_296_000)
    private let gymId = UUID()

    private func gymSnapshot(actions: [PlaceAction], taskTitles: [String] = []) -> AtPlaceSnapshot {
        AtPlaceSnapshot(entries: [
            AtPlaceSnapshot.PlaceEntry(
                placeId: gymId, displayName: "Gym 💪", openTaskTitles: taskTitles,
                actions: actions, latitude: 51.5152, longitude: -0.1418
            )
        ])
    }

    private func arrival() -> PlaceTriggerEvent {
        PlaceTriggerEvent(placeId: gymId, kind: .arrival, occurredAt: noon)
    }

    private func makeSUT(
        store: FakeStore, notifier: FakeNotifier, writers: WriterLog,
        enabled: Bool = true
    ) -> PlaceTriggerEventHandler {
        PlaceTriggerEventHandler(
            recorder: FakeRecorder(), notifier: notifier, store: store,
            isEnabled: { enabled },
            // The writers SUSPEND, like the Firestore calls they stand in for — the
            // duplicate-delivery race lives in exactly that suspension window.
            journalWriter: { input in await Task.yield(); return writers.journal(input) },
            captureWriter: { input in await Task.yield(); return writers.capture(input) }
        )
    }

    private func journalAction() -> PlaceAction {
        PlaceAction(id: UUID(), direction: .arrival, kind: .journalLine(body: "At the gym 💪"))
    }

    private func spotifyAction() -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openApp(scheme: "spotify", displayName: "Spotify")
        )
    }

    // MARK: - Auto-run

    func testHandle_autoRunWritesTheJournalLineStampedWithThePlace() async {
        let store = FakeStore()
        store.snapshot = gymSnapshot(actions: [journalAction()])
        let writers = WriterLog()
        let sut = makeSUT(store: store, notifier: FakeNotifier(), writers: writers)

        await sut.handle(arrival())

        XCTAssertEqual(writers.journalInputs.count, 1)
        XCTAssertEqual(writers.journalInputs.first?.body, "At the gym 💪")
        XCTAssertEqual(writers.journalInputs.first?.locationStamp?.placeId, gymId)
        XCTAssertEqual(writers.journalInputs.first?.locationStamp?.coordinate.latitude, 51.5152)
    }

    /// The crossing nudge REPORTS what auto-ran — that report is content, so an action-only
    /// place fires where the empty-never-fires gate would once have silenced it.
    func testHandle_reportsTheAutoRunOnTheCrossingNudge() async {
        let store = FakeStore()
        store.snapshot = gymSnapshot(actions: [journalAction()])
        let notifier = FakeNotifier()
        let sut = makeSUT(store: store, notifier: notifier, writers: WriterLog())

        await sut.handle(arrival())

        XCTAssertEqual(notifier.posted.count, 1)
        XCTAssertEqual(notifier.posted.first?.title, "You're at Gym 💪")
        XCTAssertEqual(notifier.posted.first?.body, "Journaled \u{201C}At the gym 💪\u{201D}")
        XCTAssertFalse(store.cooldowns.lastFired.isEmpty, "real activity consumes the cooldown")
    }

    /// Auto-runs are records, not interruptions — the nudge master switch silences every
    /// NOTIFICATION but must not stop a journal line E configured from being written.
    func testHandle_killSwitchOffStillAutoRunsButPostsNothing() async {
        let store = FakeStore()
        store.snapshot = gymSnapshot(actions: [journalAction()])
        let notifier = FakeNotifier()
        let writers = WriterLog()
        let sut = makeSUT(store: store, notifier: notifier, writers: writers, enabled: false)

        await sut.handle(arrival())

        XCTAssertEqual(writers.journalInputs.count, 1)
        XCTAssertTrue(notifier.posted.isEmpty)
        XCTAssertFalse(store.cooldowns.lastFired.isEmpty, "a run consumed the cooldown")
    }

    /// A FAILED write consumes nothing — the next crossing retries instead of a 30-minute
    /// silence swallowing the line E asked for.
    func testHandle_failedAutoRunDoesNotConsumeTheCooldown() async {
        let store = FakeStore()
        store.snapshot = gymSnapshot(actions: [journalAction()])
        let writers = WriterLog()
        writers.journalSucceeds = false
        let sut = makeSUT(store: store, notifier: FakeNotifier(), writers: writers)

        await sut.handle(arrival())

        XCTAssertTrue(store.cooldowns.lastFired.isEmpty)
    }

    // MARK: - External actions

    func testHandle_externalActionPostsItsOwnTappableNotification() async {
        let store = FakeStore()
        let spotify = spotifyAction()
        store.snapshot = gymSnapshot(actions: [spotify])
        let notifier = FakeNotifier()
        let sut = makeSUT(store: store, notifier: notifier, writers: WriterLog())

        await sut.handle(arrival())

        XCTAssertEqual(notifier.posted.count, 1, "external only — no tasks/message, no crossing nudge")
        let posted = notifier.posted[0]
        XCTAssertEqual(posted.title, "Open Spotify")
        XCTAssertEqual(posted.identifier, PlaceActionNotificationContent.identifier(for: spotify))
        XCTAssertEqual(
            PlaceActionNotificationContent.action(fromUserInfo: posted.userInfo), spotify,
            "the tap must be able to reconstruct the action from the notification alone"
        )
        XCTAssertFalse(store.cooldowns.lastFired.isEmpty)
    }

    func testHandle_killSwitchOffPostsNoExternalNotifications() async {
        let store = FakeStore()
        store.snapshot = gymSnapshot(actions: [spotifyAction()])
        let notifier = FakeNotifier()
        let sut = makeSUT(store: store, notifier: notifier, writers: WriterLog(), enabled: false)

        await sut.handle(arrival())

        XCTAssertTrue(notifier.posted.isEmpty)
        XCTAssertTrue(store.cooldowns.lastFired.isEmpty, "nothing happened, nothing consumed")
    }

    // MARK: - The standing gates

    func testHandle_bounceWithinTheCooldownRunsNothing() async {
        let store = FakeStore()
        store.snapshot = gymSnapshot(actions: [journalAction(), spotifyAction()])
        let notifier = FakeNotifier()
        let writers = WriterLog()
        let sut = makeSUT(store: store, notifier: notifier, writers: writers)

        await sut.handle(arrival())
        let postedAfterFirst = notifier.posted.count
        await sut.handle(
            PlaceTriggerEvent(placeId: gymId, kind: .arrival, occurredAt: noon.addingTimeInterval(60))
        )

        XCTAssertEqual(writers.journalInputs.count, 1, "the bounce must not double-write")
        XCTAssertEqual(notifier.posted.count, postedAfterFirst)
    }

    /// iOS can deliver the same crossing twice in quick succession (seen live in the block-3
    /// simulator drive: two `didEnterRegion` for one arrival, seconds apart). Both used to pass
    /// the cooldown check before either wrote it — the handler suspends at its awaits — and the
    /// journal line was written twice. The in-flight guard closes that window.
    func testHandle_simultaneousDuplicateDeliveriesRunOnce() async {
        let store = FakeStore()
        store.snapshot = gymSnapshot(actions: [journalAction()])
        let writers = WriterLog()
        let sut = makeSUT(store: store, notifier: FakeNotifier(), writers: writers)

        async let first: Void = sut.handle(arrival())
        async let second: Void = sut.handle(arrival())
        _ = await (first, second)

        XCTAssertEqual(writers.journalInputs.count, 1, "one crossing, one line — however many deliveries")
    }

    func testHandle_actionlessEmptyPlaceStillNeverFires() async {
        let store = FakeStore()
        store.snapshot = gymSnapshot(actions: [])
        let notifier = FakeNotifier()
        let sut = makeSUT(store: store, notifier: notifier, writers: WriterLog())

        await sut.handle(arrival())

        XCTAssertTrue(notifier.posted.isEmpty)
        XCTAssertTrue(store.cooldowns.lastFired.isEmpty)
    }

    /// Tasks, a custom message, an auto-run report and an external offer can all ride one
    /// crossing: externals post their own, the nudge composes the rest.
    func testHandle_actionsComposeWithTasksOnTheCrossingNudge() async {
        let store = FakeStore()
        store.snapshot = gymSnapshot(
            actions: [journalAction(), spotifyAction()], taskTitles: ["Stretch"]
        )
        let notifier = FakeNotifier()
        let sut = makeSUT(store: store, notifier: notifier, writers: WriterLog())

        await sut.handle(arrival())

        XCTAssertEqual(notifier.posted.count, 2)
        XCTAssertEqual(notifier.posted[0].title, "Open Spotify")
        XCTAssertEqual(notifier.posted[1].title, "You're at Gym 💪")
        XCTAssertTrue(notifier.posted[1].body.contains("Stretch"))
        XCTAssertTrue(notifier.posted[1].body.contains("Journaled"))
    }
}
