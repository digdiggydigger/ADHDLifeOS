//
//  FakeNudgeNotificationSchedulingAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

struct ScheduleNotificationsArguments: Equatable {
    let nudgeId: UUID
    let label: String
    let schedule: NudgeSchedule
}

final class FakeNudgeNotificationSchedulingAdapting: NudgeNotificationSchedulingAdapting, @unchecked Sendable {
    var authorizationGranted = true
    var hasScheduledNotificationsResult = false

    private(set) var requestAuthorizationCallCount = 0
    private(set) var scheduleNotificationsCallCount = 0
    private(set) var cancelNotificationsCallCount = 0
    private(set) var hasScheduledNotificationsCallCount = 0
    private(set) var scheduleArguments: [ScheduleNotificationsArguments] = []
    private(set) var cancelNudgeIds: [UUID] = []

    var lastScheduleArguments: ScheduleNotificationsArguments? { scheduleArguments.last }
    var lastCancelNudgeId: UUID? { cancelNudgeIds.last }

    func requestAuthorizationIfNeeded() async -> Bool {
        requestAuthorizationCallCount += 1
        return authorizationGranted
    }

    func scheduleNotifications(nudgeId: UUID, label: String, schedule: NudgeSchedule) async {
        scheduleNotificationsCallCount += 1
        scheduleArguments.append(ScheduleNotificationsArguments(nudgeId: nudgeId, label: label, schedule: schedule))
    }

    func cancelNotifications(nudgeId: UUID) async {
        cancelNotificationsCallCount += 1
        cancelNudgeIds.append(nudgeId)
    }

    func hasScheduledNotifications(nudgeId: UUID) async -> Bool {
        hasScheduledNotificationsCallCount += 1
        return hasScheduledNotificationsResult
    }
}
