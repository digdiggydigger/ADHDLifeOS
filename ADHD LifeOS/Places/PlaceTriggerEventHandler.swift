//
//  PlaceTriggerEventHandler.swift
//  ADHD LifeOS
//

import Foundation

/// What a fence crossing DOES — the fan-out point every block-4 surfacing hangs off. Wired to
/// `LocationTriggerService.onEvent` at App init, because a crossing can arrive in a background
/// relaunch where no screen ever mounts.
///
/// The surfacings of one event, in restraint order:
/// - the silent record (variation C) happens for EVERY crossing — memory costs nothing;
/// - past the bounce cooldown, the place's AUTO-RUN actions run themselves (journal lines,
///   captures — pure writes a background wake is allowed to make), regardless of the nudge
///   master switch: they are records, not interruptions, the location-event precedent;
/// - the notifications — one per EXTERNAL action, then the crossing nudge (now also reporting
///   what auto-ran) — fire only with the master switch on, through the same content gate as
///   ever: an action-less, task-less, message-less place still never nudges.
/// - the cooldown is consumed only when something actually HAPPENED (a successful auto-run or
///   a posted notification) — an empty arrival must not inoculate the place, and a FAILED
///   auto-run write gets its retry on the next crossing instead of a 30-minute silence.
@MainActor
final class PlaceTriggerEventHandler {
    static let shared = PlaceTriggerEventHandler()

    private let recorder: LocationEventRecording
    private let notifier: ImmediateNotifying
    private let store: ArrivalNudgeStateStoring
    private let isEnabled: () -> Bool
    /// The auto-run writers, as closures for the `locationStamp` reason: the defaults do the
    /// real Firestore work, a test hands over recorders. `true` means the write landed.
    private let journalWriter: (NormalizedCreateLogInput) async -> Bool
    private let captureWriter: (NormalizedCreateCaptureInput) async -> Bool

    init(
        recorder: LocationEventRecording? = nil,
        notifier: ImmediateNotifying? = nil,
        store: ArrivalNudgeStateStoring? = nil,
        isEnabled: @escaping () -> Bool = { AppFeedback.arrivalNudgesEnabled() },
        journalWriter: ((NormalizedCreateLogInput) async -> Bool)? = nil,
        captureWriter: ((NormalizedCreateCaptureInput) async -> Bool)? = nil
    ) {
        self.recorder = recorder ?? FirebaseLocationEventRecorder()
        self.notifier = notifier ?? NotificationCenterImmediateNotifier()
        self.store = store ?? UserDefaultsArrivalNudgeStateStore()
        self.isEnabled = isEnabled
        self.journalWriter = journalWriter ?? { input in
            (try? await FirebaseJournalClientAdapter().createLog(input)) != nil
        }
        self.captureWriter = captureWriter ?? { input in
            (try? await FirebaseCaptureClientAdapter().createCapture(input)) != nil
        }
    }

    func handle(_ event: PlaceTriggerEvent) async {
        // The silent timeline log. Quietly best-effort: a dropped event on an offline background
        // wake is a small gap in garnish, and there is no screen to surface an error on anyway.
        try? await recorder.record(
            LocationEvent(
                id: UUID(), placeId: event.placeId, kind: event.kind, occurredAt: event.occurredAt
            )
        )

        let cooldowns = store.readCooldowns()
        guard TriggerCooldown.shouldFire(event, state: cooldowns, now: event.occurredAt) else { return }
        let snapshot = store.readSnapshot()
        let entry = snapshot?.entries.first { $0.placeId == event.placeId }
        let plan = PlaceActionPlan.split(entry?.actions, for: event.kind)

        var ranLines: [String] = []
        for action in plan.autoRun where await run(action, entry: entry, event: event) {
            if let line = PlaceActionNotificationContent.ranLine(for: action) {
                ranLines.append(line)
            }
        }

        var postedAnything = false
        // Fire-time gate, not just registration-time: a fence iOS delivers moments after the
        // master switch went off must die here, not nudge one last time.
        if isEnabled() {
            for action in plan.external {
                let content = PlaceActionNotificationContent.external(
                    for: action, placeName: entry?.displayName ?? "", kind: event.kind
                )
                await notifier.post(
                    title: content.title,
                    body: content.body,
                    identifier: PlaceActionNotificationContent.identifier(for: action),
                    userInfo: PlaceActionNotificationContent.userInfo(for: action) ?? [:]
                )
                postedAnything = true
            }
            if let content = ArrivalNudgeContent.notification(
                for: event, snapshot: snapshot, executedLines: ranLines
            ) {
                await notifier.post(
                    title: content.title,
                    body: content.body,
                    identifier: "arrivalNudge-\(event.placeId.uuidString)-\(event.kind.rawValue)"
                )
                postedAnything = true
            }
        }

        if postedAnything || !ranLines.isEmpty {
            store.writeCooldowns(TriggerCooldown.recording(event, in: cooldowns))
        }
    }

    /// Runs one auto-run action, stamped with the place itself — the crossing is the evidence
    /// E is here, so no fix is requested on a background wake. `false` (a failed write, or a
    /// kind that cannot auto-run) reports nothing and consumes nothing.
    private func run(
        _ action: PlaceAction, entry: AtPlaceSnapshot.PlaceEntry?, event: PlaceTriggerEvent
    ) async -> Bool {
        let stamp: LocationStamp? = entry.flatMap { entry in
            guard let latitude = entry.latitude, let longitude = entry.longitude else { return nil }
            return LocationStamp(
                coordinate: PlaceCoordinate(latitude: latitude, longitude: longitude),
                placeId: event.placeId
            )
        }
        switch action.kind {
        case .journalLine(let body):
            guard case .success(var input) = LogValidation.normalizeCreateLogInput(
                body: body, type: .log, lifeAreaId: nil
            ) else { return false }
            input.locationStamp = stamp
            return await journalWriter(input)
        case .createCapture(let text):
            guard case .success(var input) = CaptureValidation.normalizeCreateCaptureInput(
                content: text, kind: .note
            ) else { return false }
            input.locationStamp = stamp
            return await captureWriter(input)
        default:
            return false
        }
    }
}
