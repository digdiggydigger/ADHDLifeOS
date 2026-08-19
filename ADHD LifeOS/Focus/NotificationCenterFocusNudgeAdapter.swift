//
//  NotificationCenterFocusNudgeAdapter.swift
//  ADHD LifeOS
//

import Foundation
import UserNotifications

/// Production `FocusNotificationScheduling` backed by `UNUserNotificationCenter`. Not unit-tested —
/// the same precedent as `NotificationCenterCountdownNudgeAdapter` and
/// `NotificationCenterNudgeAdapter`: it needs a real notification centre, not a fake.
/// `FocusNotificationPlanning`'s pure rules and the `FocusSessionService` call sites that drive this
/// adapter are what the tests cover.
struct NotificationCenterFocusNudgeAdapter: FocusNotificationScheduling, @unchecked Sendable {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func replaceScheduled(with notifications: [ScheduledFocusNotification]) async {
        await withdrawAll()
        for notification in notifications {
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.body
            content.sound = .default
            // Sprint nudges are the point of the feature, so they get time-sensitive delivery where
            // the OS allows it — they should break through Focus modes the way a timer does.
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }

            let interval = max(notification.fireDate.timeIntervalSinceNow, 1)
            let request = UNNotificationRequest(
                identifier: notification.identifier,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            )
            try? await center.add(request)
        }
    }

    /// Clears this feature's namespace only — a task's countdown nudges and the Nudges tab's
    /// reminders live under different prefixes and must survive a sprint ending.
    private func withdrawAll() async {
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending.map(\.identifier).filter { $0.hasPrefix("focusSprint.") }
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
