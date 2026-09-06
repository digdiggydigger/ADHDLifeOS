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
/// - the location-event record happens for EVERY crossing, and deferral does NOT touch it —
///   E ruled on this twice, the second time on device with the facts corrected. It is NOT
///   silent: `JournalTimeline.locationEventLine` renders it as a Journal row ("Arrived at
///   routines test"), which is E's own "journal rows only" call from the location arc. Shown
///   that row surviving a dismissed routine banner, E's verdict was "keep it" — the row says
///   you were HERE, not that you did something, and it is the only durable record of a visit;
/// - a live arrival run ENDS on its own place's departure, before the cooldown guard and
///   outside the master switch — a deletion, never a creation;
/// - past the bounce cooldown, a crossing with no routine to offer runs its AUTO-RUN actions
///   itself (journal lines, captures — pure writes a background wake is allowed to make),
///   regardless of the nudge master switch: they are records, not interruptions;
/// - **a crossing that DOES offer a routine writes nothing at all** (Block A, E's rule): the
///   run, Today's card and the journal line come into existence only when the notification is
///   tapped, so swiping the banner away leaves no trace. The routine rides the notification;
///   `PlaceRoutineActivator` is where it becomes real.
/// - the notifications — one routine notification, or one per EXTERNAL action, then the
///   crossing nudge — fire only with the master switch on, through the same content gate as
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
    /// The auto-run writes, shared with the notification-tap path (`PlaceRoutineActivator`) so
    /// the two can never drift apart on stamping or validation.
    private let executor: PlaceAutoRunExecutor
    /// The routine RECORD (F-RoutineRecord-1): the crossing writes the OFFER — E's one
    /// exception to Block A — and the departure crossing records WHY it ended a run.
    private let routineRecorder: RoutineRunRecording

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
        captureWriter: ((NormalizedCreateCaptureInput) async -> Bool)? = nil,
        routineRecorder: RoutineRunRecording? = nil
    ) {
        self.recorder = recorder ?? FirebaseLocationEventRecorder()
        self.routineRecorder = routineRecorder ?? FirebaseRoutineRunRecorder()
        self.notifier = notifier ?? NotificationCenterImmediateNotifier()
        self.store = store ?? UserDefaultsArrivalNudgeStateStore()
        self.runStore = runStore ?? UserDefaultsRoutineRunStore()
        self.isEnabled = isEnabled
        self.routineScreenAvailable = routineScreenAvailable
        let live = PlaceAutoRunExecutor.live()
        executor = PlaceAutoRunExecutor(
            journalWriter: journalWriter ?? live.journalWriter,
            captureWriter: captureWriter ?? live.captureWriter
        )
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
        await endLiveRunIfThisCrossingEndsIt(event)

        let cooldowns = store.readCooldowns()
        guard TriggerCooldown.shouldFire(event, state: cooldowns, now: event.occurredAt) else { return }
        let plan = PlaceActionPlan.split(entry?.actions, for: event.kind)
        let routineRun = offeredRoutine(for: event, entry: entry)

        // Block A, E's rule: a crossing that OFFERS a routine writes nothing at all — the run,
        // the card and the journal line come into existence when the notification is tapped,
        // and swiping the banner away leaves no trace. A crossing with no routine to initiate
        // has nothing to defer to, so its auto-runs happen here exactly as they always have.
        var ranLines: [String] = []
        if routineRun == nil {
            let stamp = PlaceAutoRunStamp.make(entry: entry, placeId: event.placeId)
            for action in plan.autoRun where await executor.run(action, stamp: stamp) {
                if let line = PlaceActionNotificationContent.ranLine(for: action) {
                    ranLines.append(line)
                }
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

    /// The one run write a CROSSING still makes, and E settled it explicitly (2026-09-04):
    /// ending is a deletion, never a creation, so the deferred-logging rule does not reach it.
    /// Defer this and "ROUTINE LIVE" haunts Today until the midnight sweep — the exact defect
    /// round 2's check 3 was written to catch.
    ///
    /// Runs OUTSIDE `isEnabled()` like the silent record, and the CALLER places it BEFORE the
    /// cooldown guard, because a departure swallowed by its own 30-minute cooldown must still
    /// end the arrival run.
    ///
    /// The `DataChangeSignal` is not optional garnish: Today's card is a PULL surface and this
    /// is the only push it gets, so without it an ended run leaves a stale card on a screen
    /// the user is looking at.
    private func endLiveRunIfThisCrossingEndsIt(_ event: PlaceTriggerEvent) async {
        guard let liveRun = runStore.readLiveRun(now: event.occurredAt),
              RoutineRunLifecycle.ends(liveRun, on: event) else { return }
        runStore.endLiveRun()
        await recordEnd(liveRun.id, reason: .leftPlace, at: event.occurredAt)
        DataChangeSignal.post()
    }

    /// Site 1 of the routine record (F-RoutineRecord-1, E's 2026-09-06 exception to Block A):
    /// the OFFER is recorded, and it is recorded HERE — right after its banner posts — so a
    /// crossing the cooldown, the kill-switch or the threshold suppressed offered nothing and
    /// records nothing. Best-effort like the timeline record: a background wake has no screen
    /// to surface an error on, and a lost offer is a gap in history, not a broken routine.
    private func recordOffer(_ run: RoutineRun, at now: Date) async {
        try? await routineRecorder.offered(RoutineRunRecord.offered(run, now: now))
    }

    private func recordEnd(_ runId: UUID, reason: RoutineRunEndReason, at now: Date) async {
        try? await routineRecorder.ended(runId: runId, reason: reason, at: now)
    }

    /// The routine this crossing OFFERS — minted, frozen, and deliberately never stored. It
    /// rides the notification instead (`PlaceRoutineNotificationContent.userInfo`), and only
    /// the tap turns it into a run that exists.
    ///
    /// Minting the id here rather than composing one from place + direction + date is load
    /// bearing: a `Date` serialised two ways would make every tap mismatch.
    ///
    /// Gated on the 17-only routine screen for the shipped reason — an account's places sync
    /// from other devices, and a 16.x device must keep today's per-action notifications rather
    /// than post one whose tap can do nothing.
    private func offeredRoutine(
        for event: PlaceTriggerEvent, entry: AtPlaceSnapshot.PlaceEntry?
    ) -> RoutineRun? {
        let routinePlan = PlaceRoutinePlan.make(entry?.actions, for: event.kind)
        guard routineScreenAvailable, routinePlan.qualifiesAsRoutine else { return nil }
        return RoutineRun.make(event: event, entry: entry, plan: routinePlan)
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
            let content = PlaceRoutineNotificationContent.notification(for: routineRun)
            await notifier.post(
                title: content.title,
                body: content.body,
                identifier: PlaceRoutineNotificationContent.identifier(
                    placeId: event.placeId, kind: event.kind
                ),
                // The whole frozen run rides the tap (Block A): with nothing written at the
                // crossing there is no stored run for a bare key to resolve against, so the
                // notification has to carry enough to CREATE it.
                userInfo: PlaceRoutineNotificationContent.userInfo(for: routineRun),
                categoryIdentifier: PlaceRoutineNotificationContent.categoryIdentifier
            )
            await recordOffer(routineRun, at: event.occurredAt)
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

}
