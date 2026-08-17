//
//  NotificationCenterCountdownNudgeAdapter.swift
//  ADHD LifeOS
//

import Foundation
import UserNotifications

/// Production `TaskCountdownNudgeSchedulingAdapting` backed by `UNUserNotificationCenter`. Not
/// unit-tested — same precedent as this codebase's other adapters (`SupabaseTaskDetailClientAdapter`
/// etc.): it needs a real, on-device notification center, not a fake. `TaskCountdownNudgeScheduling`'s
/// pure math and the `TaskCreateService`/`TaskDetailService` call sites that invoke this adapter are
/// what's unit-tested instead. Identifiers are namespaced per task (`taskCountdownNudge.<taskId>.<index>`)
/// so `cancelNudges`/`hasScheduledNudges` can find exactly this task's nudges among all pending requests.
struct NotificationCenterCountdownNudgeAdapter: TaskCountdownNudgeSchedulingAdapting, @unchecked Sendable {
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

    func scheduleNudges(taskId: UUID, taskTitle: String, fireDates: [ScheduledCountdownNudge]) async {
        await cancelNudges(taskId: taskId)
        for (index, nudge) in fireDates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = taskTitle
            content.body = nudge.body
            content.sound = .default

            let interval = max(nudge.date.timeIntervalSinceNow, 1)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(
                identifier: Self.identifier(taskId: taskId, index: index),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    func cancelNudges(taskId: UUID) async {
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix(taskId: taskId)) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func hasScheduledNudges(taskId: UUID) async -> Bool {
        let pending = await center.pendingNotificationRequests()
        return pending.contains { $0.identifier.hasPrefix(Self.identifierPrefix(taskId: taskId)) }
    }

    private static func identifierPrefix(taskId: UUID) -> String {
        "taskCountdownNudge.\(taskId.uuidString)."
    }

    private static func identifier(taskId: UUID, index: Int) -> String {
        "\(identifierPrefix(taskId: taskId))\(index)"
    }

    func scheduleDueMomentNotification(taskId: UUID, taskTitle: String, dueDate: Date) async {
        await cancelDueMomentNotification(taskId: taskId)

        let content = UNMutableNotificationContent()
        content.title = taskTitle
        content.body = "This task is due now."
        content.sound = .default

        let interval = max(dueDate.timeIntervalSinceNow, 1)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.dueMomentIdentifier(taskId: taskId),
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func cancelDueMomentNotification(taskId: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.dueMomentIdentifier(taskId: taskId)])
    }

    func hasDueMomentNotificationScheduled(taskId: UUID) async -> Bool {
        let pending = await center.pendingNotificationRequests()
        return pending.contains { $0.identifier == Self.dueMomentIdentifier(taskId: taskId) }
    }

    private static func dueMomentIdentifier(taskId: UUID) -> String {
        "taskDueNotification.\(taskId.uuidString)"
    }
}
