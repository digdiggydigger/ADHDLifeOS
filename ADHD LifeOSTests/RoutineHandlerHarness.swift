//
//  RoutineHandlerHarness.swift
//  ADHD LifeOSTests
//
//  The shared rig for the routine-branch handler tests (F-Routines-2), split out so the two
//  test classes stay inside the type-length bar. One ordered `SequenceLog` is shared by the
//  fakes on purpose: ORDERING claims (the run is written before the notification posts) must
//  be assertable, not assumed.
//

import Foundation
@testable import ADHD_LifeOS

struct RoutinePosted: Equatable {
    let title: String
    let body: String
    let identifier: String
    let userInfo: [String: String]
    let category: String
}

final class RoutineSequenceLog {
    private(set) var events: [String] = []
    func append(_ event: String) { events.append(event) }
}

final class RoutineFakeNotifier: ImmediateNotifying {
    private let log: RoutineSequenceLog
    private(set) var posted: [RoutinePosted] = []
    private(set) var removedDelivered: [[String]] = []

    init(log: RoutineSequenceLog) { self.log = log }

    func post(title: String, body: String, identifier: String, userInfo: [String: String]) async {
        await post(
            title: title, body: body, identifier: identifier,
            userInfo: userInfo, categoryIdentifier: ""
        )
    }

    func post(
        title: String, body: String, identifier: String,
        userInfo: [String: String], categoryIdentifier: String
    ) async {
        posted.append(RoutinePosted(
            title: title, body: body, identifier: identifier,
            userInfo: userInfo, category: categoryIdentifier
        ))
        log.append("post:\(identifier)")
    }

    func removeDelivered(identifiers: [String]) async {
        removedDelivered.append(identifiers)
        log.append("remove-delivered")
    }
}

final class RoutineFakeRunStore: RoutineRunStoring {
    private let log: RoutineSequenceLog
    var run: RoutineRun?
    private(set) var writes: [RoutineRun] = []
    private(set) var endCount = 0

    init(log: RoutineSequenceLog) { self.log = log }

    func readLiveRun(now: Date) -> RoutineRun? { run }

    func write(_ new: RoutineRun) {
        run = new
        writes.append(new)
        log.append("run-write")
    }

    func endLiveRun() {
        run = nil
        endCount += 1
        log.append("run-end")
    }
}

final class RoutineFakeArrivalStore: ArrivalNudgeStateStoring {
    var snapshot: AtPlaceSnapshot?
    var cooldowns = TriggerCooldownState()

    func readSnapshot() -> AtPlaceSnapshot? { snapshot }
    func writeSnapshot(_ new: AtPlaceSnapshot) { snapshot = new }
    func readCooldowns() -> TriggerCooldownState { cooldowns }
    func writeCooldowns(_ new: TriggerCooldownState) { cooldowns = new }
}

final class RoutineFakeRecorder: LocationEventRecording {
    func record(_ event: LocationEvent) async throws {
        // A real record suspends — keep the handler's suspension windows honest.
        await Task.yield()
    }
}

final class RoutineWriterLog {
    private(set) var journalInputs: [NormalizedCreateLogInput] = []
    func journal(_ input: NormalizedCreateLogInput) -> Bool {
        journalInputs.append(input)
        return true
    }
}

/// Everything a routine-branch handler test needs, one place: the SUT wired to recording
/// fakes, plus the gym fixtures every scenario is written against.
@MainActor
final class RoutineHandlerHarness {
    let noon = Date(timeIntervalSince1970: 1_756_296_000)
    let gymId = UUID()
    let log = RoutineSequenceLog()
    let store = RoutineFakeArrivalStore()
    let runStore: RoutineFakeRunStore
    let notifier: RoutineFakeNotifier
    let writers = RoutineWriterLog()
    let sut: PlaceTriggerEventHandler

    init(enabled: Bool = true, routineScreenAvailable: Bool = true) {
        let log = self.log
        let writers = self.writers
        runStore = RoutineFakeRunStore(log: log)
        notifier = RoutineFakeNotifier(log: log)
        sut = PlaceTriggerEventHandler(
            recorder: RoutineFakeRecorder(), notifier: notifier, store: store,
            runStore: runStore,
            isEnabled: { enabled }, routineScreenAvailable: routineScreenAvailable,
            journalWriter: { input in await Task.yield(); return writers.journal(input) },
            captureWriter: { _ in await Task.yield(); return true }
        )
    }

    // MARK: - Fixtures

    func journalAction() -> PlaceAction {
        PlaceAction(id: UUID(), direction: .arrival, kind: .journalLine(body: "Leg day"))
    }

    func spotifyAction() -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .openApp(scheme: "spotify", displayName: "Spotify")
        )
    }

    func textAction() -> PlaceAction {
        PlaceAction(
            id: UUID(), direction: .arrival,
            kind: .textContact(contactName: "Ben", phoneNumber: "+44111", messageBody: "Here!")
        )
    }

    func installGym(
        actions: [PlaceAction], taskTitles: [String] = [],
        arrivalMessage: String? = nil, departureMessage: String? = nil
    ) {
        store.snapshot = AtPlaceSnapshot(entries: [
            AtPlaceSnapshot.PlaceEntry(
                placeId: gymId, displayName: "Gym 🏋️", openTaskTitles: taskTitles,
                arrivalMessage: arrivalMessage, departureMessage: departureMessage,
                actions: actions, latitude: 51.5152, longitude: -0.1418
            )
        ])
    }

    func event(_ kind: PlaceTriggerEvent.Kind, at date: Date? = nil) -> PlaceTriggerEvent {
        PlaceTriggerEvent(placeId: gymId, kind: kind, occurredAt: date ?? noon)
    }
}
