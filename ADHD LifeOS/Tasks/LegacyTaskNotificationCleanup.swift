//
//  LegacyTaskNotificationCleanup.swift
//  ADHD LifeOS
//

import Foundation
import UserNotifications

/// One-time sweep for the per-task notification feature deleted in F-V3-Tasks-rebuild (E's b11
/// addendum). The countdown-nudge and due-moment toggles are gone from the UI, but anything they
/// scheduled before the removal is still sitting in the notification center — with no code left
/// that could ever cancel it. This removes exactly those, by the old identifier prefixes, and
/// leaves every other notification (recurring nudges, focus-sprint nudges) untouched.
enum LegacyTaskNotificationCleanup {
    /// The deleted `NotificationCenterCountdownNudgeAdapter`'s namespaces, verbatim.
    static let legacyPrefixes = ["taskCountdownNudge.", "taskDueNotification."]

    static func run(center: UNUserNotificationCenter = .current()) async {
        let pending = await center.pendingNotificationRequests()
        let stale = pending
            .map(\.identifier)
            .filter { identifier in legacyPrefixes.contains { identifier.hasPrefix($0) } }
        guard !stale.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: stale)
    }
}
