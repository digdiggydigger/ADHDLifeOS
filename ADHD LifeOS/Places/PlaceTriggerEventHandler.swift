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
    private let runStore: RoutineRunStoring
    private let isEnabled: () -> Bool
    /// The routine screen is 17-gated but crossings are not, and an account's places can come
    /// from another device — a 16.x device receiving a qualifying crossing keeps today's
    /// per-action notifications (never a notification whose tap can do nothing). Injectable
    /// so both branches are pinned without an iOS 16 simulator.
    private let routineScreenAvailable: Bool
    /// The auto-run writers, as closures for the `locationStamp` reason: the defaults do the
    /// real Firestore work, a test hands over recorders. `true` means the write landed.
    private let journalWriter: (NormalizedCreateLogInput) async -> Bool
    private let captureWriter: (NormalizedCreateCaptureInput) async -> Bool

    init(
        recorder: LocationEventRecording? = nil,
        notifier: ImmediateNotifying? = nil,
        store: ArrivalNudgeStateStoring? = nil,
        // Defaulted so the DEBUG test-fire path (which constructs the handler without
        // injection) exercises the routine branch against the REAL run store for free.
        runStore: RoutineRunStoring? = nil,
        isEnabled: @escaping () -> Bool = { AppFeedback.arrivalNudgesEnabled() },
        routineScreenAvailable: Bool = { if #available(iOS 17.0, *) { return true }
                                         return false }(),
        journalWriter: ((NormalizedCreateLogInput) async -> Bool)? = nil,
        captureWriter: ((NormalizedCreateCaptureInput) async -> Bool)? = nil
    ) {
        self.recorder = recorder ?? FirebaseLocationEventRecorder()
        self.notifier = notifier ?? NotificationCenterImmediateNotifier()
        self.store = store ?? UserDefaultsArrivalNudgeStateStore()
        self.runStore = runStore ?? UserDefaultsRoutineRunStore()
        self.isEnabled = isEnabled
        self.routineScreenAvailable = routineScreenAvailable
        self.journalWriter = journalWriter ?? { input in
            (try? await FirebaseJournalClientAdapter().createLog(input)) != nil
        }
        self.captureWriter = captureWriter ?? { input in
            (try? await FirebaseCaptureClientAdapter().createCapture(input)) != nil
        }
    }

    /// Crossings currently being handled, keyed place|direction. iOS can deliver one crossing
    /// twice within seconds (seen live, block-3 simulator drive), and the persisted cooldown
    /// cannot stop the twin: this method SUSPENDS between reading the cooldown and writing it,
    /// so both deliveries used to pass the check and the journal line was written twice. The
    /// guard is checked and set before the first await, which on the main actor closes the
    /// window; the persisted cooldown still covers duplicates across relaunches.
    private var inFlight: Set<String> = []

    func handle(_ event: PlaceTriggerEvent) async {
        let flightKey = "\(event.placeId.uuidString)|\(event.kind.rawValue)"
        guard !inFlight.contains(flightKey) else { return }
        inFlight.insert(flightKey)
        defer { inFlight.remove(flightKey) }

        // The silent timeline log. Quietly best-effort: a dropped event on an offline background
        // wake is a small gap in garnish, and there is no screen to surface an error on anyway.
        try? await recorder.record(
            LocationEvent(
                id: UUID(), placeId: event.placeId, kind: event.kind, occurredAt: event.occurredAt
            )
        )

        let snapshot = store.readSnapshot()
        let entry = snapshot?.entries.first { $0.placeId == event.placeId }
        let routineRun = applyRunLifecycle(for: event, entry: entry)

        let cooldowns = store.readCooldowns()
        guard TriggerCooldown.shouldFire(event, state: cooldowns, now: event.occurredAt) else { return }
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
            postedAnything = await postCrossingNotifications(
                for: event, snapshot: snapshot,
                routineRun: routineRun, externals: plan.external, ranLines: ranLines
            )
        }

        if postedAnything || !ranLines.isEmpty {
            store.writeCooldowns(TriggerCooldown.recording(event, in: cooldowns))
        }
    }

    /// Run LIFECYCLE (F-Routines-2) — records, like the auto-runs, so it runs OUTSIDE
    /// `isEnabled()`; and the CALLER places it BEFORE the cooldown guard, because a departure
    /// swallowed by its own 30-minute cooldown must still end the arrival run — otherwise
    /// "routine live" haunts Today until the midnight sweep. Creation obeys the same
    /// placement (newest wins): E standing in the gym again after a bounce must find the
    /// routine on Today even though the bounce posts nothing.
    ///
    /// Returns the minted run when this crossing qualifies as a routine (2+ tap-steps, and
    /// only where the 17-gated routine screen can honour the tap).
    private func applyRunLifecycle(
        for event: PlaceTriggerEvent, entry: AtPlaceSnapshot.PlaceEntry?
    ) -> RoutineRun? {
        if let liveRun = runStore.readLiveRun(now: event.occurredAt),
           RoutineRunLifecycle.ends(liveRun, on: event) {
            runStore.endLiveRun()
        }
        let routinePlan = PlaceRoutinePlan.make(entry?.actions, for: event.kind)
        guard routineScreenAvailable, routinePlan.qualifiesAsRoutine else { return nil }
        let run = RoutineRun.make(event: event, entry: entry, plan: routinePlan)
        runStore.write(run)
        return run
    }

    /// The interruption half of one crossing, behind BOTH gates (cooldown and master
    /// switch). With a routine run minted, ONE routine notification absorbs the message and
    /// the auto-run report (E's settled call #2) and the task nudge composes tasks alone;
    /// without one, the shipped per-action fan-out runs byte-identically.
    private func postCrossingNotifications(
        for event: PlaceTriggerEvent, snapshot: AtPlaceSnapshot?, routineRun: RoutineRun?,
        externals: [PlaceAction], ranLines: [String]
    ) async -> Bool {
        let entry = snapshot?.entries.first { $0.placeId == event.placeId }
        var postedAnything = false
        if let routineRun {
            let content = PlaceRoutineNotificationContent.notification(
                for: routineRun, ranLines: ranLines
            )
            await notifier.post(
                title: content.title,
                body: content.body,
                identifier: PlaceRoutineNotificationContent.identifier(
                    placeId: event.placeId, kind: event.kind
                ),
                // ONLY the minted run key rides the tap: the screen reads steps from the
                // store, and a key mismatch IS the stale-tap rule.
                userInfo: PlaceRoutineNotificationContent.userInfo(for: routineRun),
                categoryIdentifier: PlaceRoutineNotificationContent.categoryIdentifier
            )
            // Tray hygiene: a still-delivered per-action notification from an earlier
            // crossing must not compete with the routine that replaces it. Removal rides
            // the post — with the switch off, the tray is not touched at all.
            await notifier.removeDelivered(identifiers: routineRun.steps
                .filter { $0.state != .autoDone }
                .map { PlaceActionNotificationContent.identifier(for: $0.action) })
            postedAnything = true
        } else {
            for action in externals {
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
        }
        if let content = ArrivalNudgeContent.notification(
            for: event, snapshot: snapshot, executedLines: ranLines,
            absorbedByRoutine: routineRun != nil
        ) {
            await notifier.post(
                title: content.title,
                body: content.body,
                identifier: "arrivalNudge-\(event.placeId.uuidString)-\(event.kind.rawValue)"
            )
            postedAnything = true
        }
        return postedAnything
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
