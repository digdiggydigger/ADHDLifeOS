//
//  NotificationAuthorizationReading.swift
//  ADHD LifeOS
//

import Foundation

/// Read-only seam over `UNUserNotificationCenter` for the Settings → Notifications section, same
/// adapter-protocol pattern as `TaskCountdownNudgeSchedulingAdapting`. Deliberately exposes **only**
/// a status read: this section reports whether iOS has granted notification permission and must
/// never trigger a system permission prompt merely by being opened. There is intentionally no
/// `requestAuthorization`-style method on this protocol, so no Settings code path can prompt.
protocol NotificationAuthorizationReading: Sendable {
    /// Reads the current authorization status without ever requesting permission.
    func authorizationStatus() async -> NotificationPermissionState
}
