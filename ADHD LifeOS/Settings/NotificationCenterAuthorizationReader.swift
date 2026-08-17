//
//  NotificationCenterAuthorizationReader.swift
//  ADHD LifeOS
//

import Foundation
import UserNotifications

/// Production `NotificationAuthorizationReading` backed by `UNUserNotificationCenter`. Not
/// unit-tested — same precedent as `NotificationCenterCountdownNudgeAdapter`: it needs a real
/// notification center, not a fake, so the pure `NotificationPermissionState` mapping is what the
/// tests cover instead.
///
/// CRITICAL: this reads `notificationSettings().authorizationStatus` only. It never calls
/// `requestAuthorization` and never calls the app's existing `requestAuthorizationIfNeeded()`, so
/// opening Settings can never fire a system permission dialog.
struct NotificationCenterAuthorizationReader: NotificationAuthorizationReading, @unchecked Sendable {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> NotificationPermissionState {
        let settings = await center.notificationSettings()
        return NotificationPermissionState(authorizationStatus: settings.authorizationStatus)
    }
}
