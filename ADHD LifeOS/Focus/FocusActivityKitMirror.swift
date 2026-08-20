//
//  FocusActivityKitMirror.swift
//  ADHD LifeOS
//

import ActivityKit
import Foundation

/// The live `FocusActivityMirroring`: projects sprint lifecycle events onto an ActivityKit Live
/// Activity (Lock Screen banner + Dynamic Island).
///
/// §7 availability: ActivityKit is iOS 16.1+ against the app's 16.0 floor, so the whole type is
/// gated — same trap class as `.sensoryFeedback`. Within it, `ActivityContent`/`staleDate` are
/// 16.2+, hence the inner branches (on 16.1 the content is pushed without staleness, so a locked
/// phone shows 00:00 instead of "complete" until the app next opens).
///
/// Free-developer-account constraint: locally-updated Activities only — no push token, no
/// remote-update or frequent-updates plumbing. The OS renders the countdown itself from the
/// deadline, so pause/resume/extend/stop/checkpoint updates are all it ever needs.
@available(iOS 16.1, *)
final class FocusActivityKitMirror: FocusActivityMirroring {
    /// A finished sprint's Activity is dismissed IMMEDIATELY, on every ending.
    ///
    /// It used to linger for two minutes after a natural finish, on the theory that the frame was a
    /// nice acknowledgement. In practice (E, 2026-08-20) that reads as the Activity being stuck:
    /// the sprint is over, yet the Lock Screen still carries a card for it. The acknowledgement now
    /// arrives as the "Sprint complete" NOTIFICATION instead, which is both louder and dismissible,
    /// so the Activity has no reason to outlive the sprint.
    private static let completedDismissalPolicy: ActivityUIDismissalPolicy = .immediate

    private var activity: Activity<FocusActivityAttributes>?
    private var lastState: FocusActivityAttributes.ContentState?
    private let now: () -> Date
    /// The most recent fire-and-forget ActivityKit call, retained so Lock Screen intents can
    /// await it — their app process is re-suspended soon after `perform()` returns, and the
    /// Activity's redraw must land first.
    private var lastActivityTask: Task<Void, Never>?

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
        // Anything alive at construction is an orphan from a killed process — no sprint can be
        // running before RootView exists — so clear the Lock Screen of stale countdowns.
        Task { await FocusActivityAttributes.endAllActivities() }
    }

    func waitForPendingUpdates() async {
        await lastActivityTask?.value
    }

    func sprintStarted(_ snapshot: FocusActivitySnapshot) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let state = FocusActivityAttributes.ContentState(snapshot: snapshot, now: now())
        lastState = state
        do {
            if #available(iOS 16.2, *) {
                activity = try Activity.request(
                    attributes: FocusActivityAttributes(),
                    content: ActivityContent(state: state, staleDate: staleDate(for: state))
                )
            } else {
                activity = try Activity.request(
                    attributes: FocusActivityAttributes(), contentState: state
                )
            }
        } catch {
            // The request can fail (user disabled Live Activities, per-app budget exhausted).
            // The sprint itself is unaffected — the in-app bar remains the source of truth.
            activity = nil
            lastState = nil
        }
    }

    func sprintUpdated(_ snapshot: FocusActivitySnapshot) {
        guard let activity else { return }
        let state = FocusActivityAttributes.ContentState(snapshot: snapshot, now: now())
        lastState = state
        let staleDate = staleDate(for: state)
        lastActivityTask = Task {
            if #available(iOS 16.2, *) {
                await activity.update(ActivityContent(state: state, staleDate: staleDate))
            } else {
                await activity.update(using: state)
            }
        }
    }

    func sprintEnded(completedNaturally: Bool) {
        guard let activity else { return }
        // A natural finish leaves a brief "sprint complete" frame; a manual stop or a
        // replacement sprint clears the Lock Screen immediately.
        var finalState = lastState
        if completedNaturally {
            finalState?.isCompleted = true
            finalState?.pausedAt = nil
        }
        let policy = Self.completedDismissalPolicy
        self.activity = nil
        lastState = nil
        lastActivityTask = Task {
            if #available(iOS 16.2, *) {
                await activity.end(
                    finalState.map { ActivityContent(state: $0, staleDate: nil) },
                    dismissalPolicy: policy
                )
            } else {
                await activity.end(using: finalState, dismissalPolicy: policy)
            }
        }
    }

    /// A running sprint's content goes stale the moment its deadline passes, so the extension can
    /// render "sprint complete" even when the app is suspended and can't push an update (the one
    /// transition a locally-updated Activity can't be told about). Paused content never expires.
    private func staleDate(for state: FocusActivityAttributes.ContentState) -> Date? {
        state.isPaused ? nil : state.deadline
    }
}

@available(iOS 16.1, *)
extension FocusActivityAttributes.ContentState {
    /// Maps the engine's snapshot onto the wire state. While paused there is no live deadline, so
    /// one is synthesized from `now` plus the frozen remainder and the display is pinned to `now`
    /// via `pausedAt` — `Text(timerInterval:pauseTime:)` then shows the frozen clock without the
    /// app ever formatting time itself.
    init(snapshot: FocusActivitySnapshot, now: Date) {
        self.init(
            taskTitle: snapshot.taskTitle,
            lifeAreaEmoji: snapshot.lifeAreaEmoji,
            durationSeconds: snapshot.durationSeconds,
            deadline: snapshot.deadline
                ?? now.addingTimeInterval(TimeInterval(snapshot.pausedRemainingSeconds ?? 0)),
            pausedAt: snapshot.deadline == nil ? now : nil,
            checkpointCount: snapshot.checkpointCount,
            checkpointsReached: snapshot.checkpointsReached,
            checkpointSeconds: snapshot.checkpointSeconds,
            isCompleted: false
        )
    }
}

extension FocusSessionService {
    /// RootView's app-wide instance: Firebase history logging plus, where the OS has ActivityKit,
    /// Live Activity mirroring (§7: 16.1+ API over the 16.0 floor, so the mirror is opt-in).
    ///
    /// On iOS 17+ this also arms the Lock Screen buttons: their `LiveActivityIntent`s run in this
    /// app process and reach the live engine through `FocusSprintIntentActions`. Each action
    /// awaits the mirror's pending ActivityKit call so the redraw lands before the system
    /// re-suspends the app.
    static func withLiveActivityMirroring(logger: FocusSessionLogging) -> FocusSessionService {
        let notifications = NotificationCenterFocusNudgeAdapter()
        guard #available(iOS 16.1, *) else {
            let service = FocusSessionService(logger: logger, notificationScheduler: notifications)
            connectNotificationTaps(to: service)
            return service
        }
        let mirror = FocusActivityKitMirror()
        let service = FocusSessionService(
            logger: logger, activityMirror: mirror, notificationScheduler: notifications
        )
        connectNotificationTaps(to: service)
        if #available(iOS 17.0, *) {
            FocusSprintIntentActions.pauseResume = { [weak service, weak mirror] in
                service?.togglePause()
                await mirror?.waitForPendingUpdates()
                // A pause must also WITHDRAW the pending nudges before the app is re-suspended,
                // or the OS still fires them while the sprint sits frozen.
                await service?.pendingNotificationWork()
            }
            FocusSprintIntentActions.stop = { [weak service, weak mirror] in
                await service?.stop()
                await mirror?.waitForPendingUpdates()
                await service?.pendingNotificationWork()
            }
        }
        return service
    }

    /// Arms the "Sprint complete" notification as the route out of a lingering Live Activity: a tap
    /// settles the sprint against the wall clock, which ends the Activity.
    ///
    /// Wired on BOTH branches above — notifications are not gated on 16.1, so a device without
    /// ActivityKit still gets a tap that finishes a sprint whose countdown expired while suspended.
    /// `weak` because the router outlives nothing in particular but the engine is RootView's.
    private static func connectNotificationTaps(to service: FocusSessionService) {
        FocusNotificationRouter.shared.connect { [weak service] in service?.syncNow() }
    }
}
