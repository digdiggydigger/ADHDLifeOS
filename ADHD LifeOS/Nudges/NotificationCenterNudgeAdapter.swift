//
//  NotificationCenterNudgeAdapter.swift
//  ADHD LifeOS
//

import Foundation
import UserNotifications

/// Production `NudgeNotificationSchedulingAdapting` backed by `UNUserNotificationCenter`. Not
/// unit-tested — same precedent as `NotificationCenterCountdownNudgeAdapter`: it needs a real,
/// on-device notification center, not a fake. `NudgeNotificationScheduling`'s pure math and the
/// `NudgesService` call sites that invoke this adapter are what's unit-tested instead. Identifiers
/// are namespaced per nudge per weekday (`nudgeNotification.<nudgeId>.<cronWeekday>`, cron's
/// `0`-`6` convention) so `cancelNotifications`/`hasScheduledNotifications` can find exactly this
/// nudge's requests among all pending ones — distinct from the per-task
/// `taskCountdownNudge.<taskId>.<index>`/`taskDueNotification.<taskId>` namespaces, so none of
/// these three features can ever see or cancel each other's requests.
struct NotificationCenterNudgeAdapter: NudgeNotificationSchedulingAdapting, @unchecked Sendable {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func scheduleNotifications(nudgeId: UUID, label: String, schedule: NudgeSchedule) async {
        await cancelNotifications(nudgeId: nudgeId)
        for components in NudgeNotificationScheduling.triggerComponents(for: schedule) {
            guard let weekday = components.weekday else { continue }
            let cronWeekday = weekday - 1

            let content = UNMutableNotificationContent()
            content.title = label
            content.body = "This nudge is due now."
            content.sound = AppFeedback.notificationSound()

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: Self.identifier(nudgeId: nudgeId, cronWeekday: cronWeekday),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func cancelNotifications(nudgeId: UUID) async {
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix(nudgeId: nudgeId)) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func hasScheduledNotifications(nudgeId: UUID) async -> Bool {
        let pending = await center.pendingNotificationRequests()
        return pending.contains { $0.identifier.hasPrefix(Self.identifierPrefix(nudgeId: nudgeId)) }
    }

    private static func identifierPrefix(nudgeId: UUID) -> String {
        "nudgeNotification.\(nudgeId.uuidString)."
    }

    private static func identifier(nudgeId: UUID, cronWeekday: Int) -> String {
        "\(identifierPrefix(nudgeId: nudgeId))\(cronWeekday)"
    }
}
