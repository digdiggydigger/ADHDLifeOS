//
//  FakeNotificationAuthorizationReading.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Test double for the read-only notification-authorization seam. Never touches a real
/// `UNUserNotificationCenter`; returns a configurable state and records how often it was read.
final class FakeNotificationAuthorizationReading: NotificationAuthorizationReading, @unchecked Sendable {
    var stateToReturn: NotificationPermissionState
    private(set) var callCount = 0

    init(stateToReturn: NotificationPermissionState = .authorized) {
        self.stateToReturn = stateToReturn
    }

    func authorizationStatus() async -> NotificationPermissionState {
        callCount += 1
        return stateToReturn
    }
}
