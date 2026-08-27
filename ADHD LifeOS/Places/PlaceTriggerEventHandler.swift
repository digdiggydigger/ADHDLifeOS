//
//  PlaceTriggerEventHandler.swift
//  ADHD LifeOS
//

import Foundation

/// What a fence crossing DOES — the fan-out point every block-4 surfacing hangs off. Wired to
/// `LocationTriggerService.onEvent` at App init, because a crossing can arrive in a background
/// relaunch where no screen ever mounts.
///
/// Two independent surfacings of one event, in restraint order:
/// - the silent record (variation C) happens for EVERY crossing — memory costs nothing;
/// - the notification (variation A) fires only through every one of its gates: the master
///   switch (checked again at fire time), the bounce cooldown, and content — no open At-Place
///   tasks means no nudge, ever.
@MainActor
final class PlaceTriggerEventHandler {
    static let shared = PlaceTriggerEventHandler()

    private let recorder: LocationEventRecording
    private let notifier: ImmediateNotifying
    private let store: ArrivalNudgeStateStoring
    private let isEnabled: () -> Bool

    init(
        recorder: LocationEventRecording? = nil,
        notifier: ImmediateNotifying? = nil,
        store: ArrivalNudgeStateStoring? = nil,
        isEnabled: @escaping () -> Bool = { AppFeedback.arrivalNudgesEnabled() }
    ) {
        self.recorder = recorder ?? FirebaseLocationEventRecorder()
        self.notifier = notifier ?? NotificationCenterImmediateNotifier()
        self.store = store ?? UserDefaultsArrivalNudgeStateStore()
        self.isEnabled = isEnabled
    }

    func handle(_ event: PlaceTriggerEvent) async {
        // The silent timeline log. Quietly best-effort: a dropped event on an offline background
        // wake is a small gap in garnish, and there is no screen to surface an error on anyway.
        try? await recorder.record(
            LocationEvent(
                id: UUID(), placeId: event.placeId, kind: event.kind, occurredAt: event.occurredAt
            )
        )
        await nudge(for: event)
    }

    private func nudge(for event: PlaceTriggerEvent) async {
        // Fire-time gate, not just registration-time: a fence iOS delivers moments after the
        // master switch went off must die here, not nudge one last time.
        guard isEnabled() else { return }
        let cooldowns = store.readCooldowns()
        guard TriggerCooldown.shouldFire(event, state: cooldowns, now: event.occurredAt) else { return }
        guard let content = ArrivalNudgeContent.notification(
            for: event, snapshot: store.readSnapshot()
        ) else { return }
        await notifier.post(
            title: content.title,
            body: content.body,
            identifier: "arrivalNudge-\(event.placeId.uuidString)-\(event.kind.rawValue)"
        )
        // Only a FIRED nudge consumes the cooldown — an empty arrival must not inoculate the
        // place against the real nudge later.
        store.writeCooldowns(TriggerCooldown.recording(event, in: cooldowns))
    }
}
