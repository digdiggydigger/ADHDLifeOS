//
//  PlaceTriggerTestFire.swift
//  ADHD LifeOS
//

import Foundation

#if DEBUG
/// TEMPORARY field-test tool (E's 2026-09-01 ask, the app-directory field gate): fires a place's
/// triggers on demand so testing an action does not require physically crossing the fence.
/// DEBUG-only — the device carries Debug builds, Release never grows the button.
///
/// It drives the REAL `PlaceTriggerEventHandler` — same notifications, same auto-run writes,
/// same timeline record — with exactly two deliberate departures from a real crossing:
/// - the cooldown is neither consulted nor consumed, so the button fires every tap AND a real
///   walk minutes later still gets its own nudge;
/// - the master nudge switch is forced on, because the button exists to test actions, not gates.
///
/// The snapshot is built live from the place being fired (plus a best-effort tasks fetch), not
/// read from the persisted replan state — a just-edited action must fire immediately.
struct TestFireArrivalStateStore: ArrivalNudgeStateStoring {
    let snapshot: AtPlaceSnapshot

    func readSnapshot() -> AtPlaceSnapshot? { snapshot }
    func writeSnapshot(_ snapshot: AtPlaceSnapshot) {}
    func readCooldowns() -> TriggerCooldownState { TriggerCooldownState() }
    func writeCooldowns(_ state: TriggerCooldownState) {}
}

@MainActor
enum PlaceTriggerTestFire {
    static func fire(
        place: Place,
        kind: PlaceTriggerEvent.Kind,
        fetchTasks: () async throws -> [TaskItem] = {
            try await FirebaseTasksClientAdapter().fetchAllTasks()
        },
        makeHandler: @MainActor (ArrivalNudgeStateStoring) -> PlaceTriggerEventHandler = { store in
            PlaceTriggerEventHandler(store: store, isEnabled: { true })
        }
    ) async {
        let tasks = (try? await fetchTasks()) ?? []
        let store = TestFireArrivalStateStore(snapshot: .build(places: [place], tasks: tasks))
        await makeHandler(store).handle(
            PlaceTriggerEvent(placeId: place.id, kind: kind, occurredAt: .now)
        )
    }
}
#endif
