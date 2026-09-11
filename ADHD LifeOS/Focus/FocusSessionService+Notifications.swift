//
//  FocusSessionService+Notifications.swift
//  ADHD LifeOS
//
//  The sprint's notification schedule, moved out of `FocusSessionService.swift` unchanged when
//  F-ConfirmCelebration-1 needed room there for a stored stamp (a stored property cannot live in
//  an extension, so METHODS had to move). Same arrangement as `+Completions` and `+Persistence`;
//  `notificationScheduler` and `notificationTask` lost their `private` for it, and nothing else
//  writes them.
//

import Foundation

extension FocusSessionService {
    /// Awaits any in-flight notification write. Used by tests, and by the Lock Screen intents so a
    /// pause/resume's schedule change lands before the OS re-suspends the app.
    func pendingNotificationWork() async {
        await notificationTask?.value
    }

    /// Re-derives the sprint's whole notification schedule and hands it to the OS, replacing
    /// whatever was pending. Called from every mutation that can change WHEN a nudge is due —
    /// start, pause, resume, extend, re-plan, end — and deliberately NOT from plain ticks: the OS
    /// already holds the schedule, so re-handing it twice a second would be pure churn.
    ///
    /// Fire-and-forget, because the engine's mutations are synchronous and must stay that way; the
    /// writes are chained so they can never land out of order.
    func rescheduleNotifications(requestingAuthorization: Bool = false) {
        guard let notificationScheduler else { return }
        let plan = FocusNotificationPlanning.plan(session: session, deadline: deadline, now: now())
        let previous = notificationTask
        notificationTask = Task {
            await previous?.value
            if requestingAuthorization {
                await notificationScheduler.requestAuthorizationIfNeeded()
            }
            await notificationScheduler.replaceScheduled(with: plan)
        }
    }
}
