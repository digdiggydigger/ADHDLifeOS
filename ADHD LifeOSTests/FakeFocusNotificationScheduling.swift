//
//  FakeFocusNotificationScheduling.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

/// Records what the sprint engine hands the notification centre, so the tests can assert the whole
/// schedule at each lifecycle point rather than one request at a time.
final class FakeFocusNotificationScheduling: FocusNotificationScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var _scheduled: [[ScheduledFocusNotification]] = []
    private var _authorizationRequests = 0

    /// Every plan handed over, in order — `.last` is what the OS currently holds.
    var scheduled: [[ScheduledFocusNotification]] {
        lock.lock()
        defer { lock.unlock() }
        return _scheduled
    }

    var authorizationRequests: Int {
        lock.lock()
        defer { lock.unlock() }
        return _authorizationRequests
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        lock.lock()
        _authorizationRequests += 1
        lock.unlock()
        return true
    }

    func replaceScheduled(with notifications: [ScheduledFocusNotification]) async {
        lock.lock()
        _scheduled.append(notifications)
        lock.unlock()
    }
}
