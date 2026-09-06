//
//  RoutineDismissRouting.swift
//  ADHD LifeOS
//
//  A SWIPE on the routine banner (F-RoutineRecord-1, site 3). iOS reports a dismissal only
//  when the category carries `.customDismissAction`, and it arrives through the same delegate
//  callback as a tap, distinguished by the action identifier alone. The delegate asks this
//  FIRST: a dismiss that fell through to the routine router would START the routine the user
//  just cleared. Pure decision, then a small doing half — the activator's arrangement.
//

import Foundation
import UserNotifications

enum RoutineDismissRouting {
    /// The run key a dismiss response names, or `nil` when this response is not a routine
    /// dismissal at all, or is one with nothing usable inside.
    static func dismissedRunKey(
        notificationIdentifier: String, actionIdentifier: String, userInfo: [AnyHashable: Any]
    ) -> UUID? {
        guard isRoutineDismissal(notificationIdentifier: notificationIdentifier, actionIdentifier: actionIdentifier)
        else { return nil }
        return PlaceRoutineNotificationContent.run(fromUserInfo: userInfo)?.id
            ?? PlaceRoutineNotificationContent.runKey(fromUserInfo: userInfo)
    }

    /// Ours by prefix AND by action — the placeAction greed rule applied to dismissals, so a
    /// broken payload under our prefix is still claimed rather than mistaken for a tap.
    static func isRoutineDismissal(notificationIdentifier: String, actionIdentifier: String) -> Bool {
        notificationIdentifier.hasPrefix(PlaceRoutineNotificationContent.identifierPrefix)
            && actionIdentifier == UNNotificationDismissActionIdentifier
    }
}

/// The doing half. Records the dismissal on a `Task` the delegate does not wait for — the
/// callback may be a cold background launch with no UI — held so a test can.
@MainActor
final class RoutineDismissRecorder {
    static let shared = RoutineDismissRecorder()

    private let recorder: RoutineRunRecording
    private(set) var recordTask: Task<Void, Never>?

    init(recorder: RoutineRunRecording? = nil) {
        self.recorder = recorder ?? FirebaseRoutineRunRecorder()
    }

    /// `true` when the response was a routine dismissal and is fully handled here — the
    /// delegate then hands it to no router.
    @discardableResult
    func handle(
        notificationIdentifier: String, actionIdentifier: String, userInfo: [AnyHashable: Any],
        now: Date = .now
    ) -> Bool {
        guard RoutineDismissRouting.isRoutineDismissal(
            notificationIdentifier: notificationIdentifier, actionIdentifier: actionIdentifier
        ) else { return false }
        guard let runId = RoutineDismissRouting.dismissedRunKey(
            notificationIdentifier: notificationIdentifier, actionIdentifier: actionIdentifier, userInfo: userInfo
        ) else { return true }
        let recorder = self.recorder
        recordTask = Task {
            try? await recorder.dismissed(runId: runId, at: now)
        }
        return true
    }
}
