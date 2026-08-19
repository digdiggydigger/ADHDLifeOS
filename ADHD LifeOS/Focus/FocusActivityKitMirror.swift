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
    /// How long the "sprint complete" frame lingers on the Lock Screen after a natural finish.
    private static let completedFrameLingerSeconds: TimeInterval = 120

    private var activity: Activity<FocusActivityAttributes>?
    private var lastState: FocusActivityAttributes.ContentState?
    private let now: () -> Date

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
        // Anything alive at construction is an orphan from a killed process — no sprint can be
        // running before RootView exists — so clear the Lock Screen of stale countdowns.
        for orphan in Activity<FocusActivityAttributes>.activities {
            Task {
                if #available(iOS 16.2, *) {
                    await orphan.end(nil, dismissalPolicy: .immediate)
                } else {
                    await orphan.end(using: nil, dismissalPolicy: .immediate)
                }
            }
        }
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
        Task {
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
        let policy: ActivityUIDismissalPolicy = completedNaturally
            ? .after(now().addingTimeInterval(Self.completedFrameLingerSeconds))
            : .immediate
        self.activity = nil
        lastState = nil
        Task {
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
            isCompleted: false
        )
    }
}

extension FocusSessionService {
    /// RootView's app-wide instance: Firebase history logging plus, where the OS has ActivityKit,
    /// Live Activity mirroring (§7: 16.1+ API over the 16.0 floor, so the mirror is opt-in).
    static func withLiveActivityMirroring(logger: FocusSessionLogging) -> FocusSessionService {
        guard #available(iOS 16.1, *) else { return FocusSessionService(logger: logger) }
        return FocusSessionService(logger: logger, activityMirror: FocusActivityKitMirror())
    }
}
