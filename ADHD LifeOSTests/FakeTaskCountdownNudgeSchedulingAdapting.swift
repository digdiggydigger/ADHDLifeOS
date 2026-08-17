//
//  FakeTaskCountdownNudgeSchedulingAdapting.swift
//  ADHD LifeOSTests
//

import Foundation
@testable import ADHD_LifeOS

struct ScheduleNudgesArguments: Equatable {
    let taskId: UUID
    let taskTitle: String
    let fireDates: [ScheduledCountdownNudge]
}

struct ScheduleDueMomentNotificationArguments: Equatable {
    let taskId: UUID
    let taskTitle: String
    let dueDate: Date
}

final class FakeTaskCountdownNudgeSchedulingAdapting: TaskCountdownNudgeSchedulingAdapting, @unchecked Sendable {
    var authorizationGranted = true
    var hasScheduledNudgesResult = false
    var hasDueMomentNotificationScheduledResult = false

    private(set) var requestAuthorizationCallCount = 0
    private(set) var scheduleNudgesCallCount = 0
    private(set) var cancelNudgesCallCount = 0
    private(set) var hasScheduledNudgesCallCount = 0
    private(set) var lastScheduleArguments: ScheduleNudgesArguments?
    private(set) var lastCancelTaskId: UUID?
    private(set) var scheduleDueMomentNotificationCallCount = 0
    private(set) var cancelDueMomentNotificationCallCount = 0
    private(set) var hasDueMomentScheduledCallCount = 0
    private(set) var lastScheduleDueMomentArguments: ScheduleDueMomentNotificationArguments?
    private(set) var lastCancelDueMomentTaskId: UUID?

    func requestAuthorizationIfNeeded() async -> Bool {
        requestAuthorizationCallCount += 1
        return authorizationGranted
    }

    func scheduleNudges(taskId: UUID, taskTitle: String, fireDates: [ScheduledCountdownNudge]) async {
        scheduleNudgesCallCount += 1
        lastScheduleArguments = ScheduleNudgesArguments(taskId: taskId, taskTitle: taskTitle, fireDates: fireDates)
    }

    func cancelNudges(taskId: UUID) async {
        cancelNudgesCallCount += 1
        lastCancelTaskId = taskId
    }

    func hasScheduledNudges(taskId: UUID) async -> Bool {
        hasScheduledNudgesCallCount += 1
        return hasScheduledNudgesResult
    }

    func scheduleDueMomentNotification(taskId: UUID, taskTitle: String, dueDate: Date) async {
        scheduleDueMomentNotificationCallCount += 1
        lastScheduleDueMomentArguments = ScheduleDueMomentNotificationArguments(
            taskId: taskId, taskTitle: taskTitle, dueDate: dueDate
        )
    }

    func cancelDueMomentNotification(taskId: UUID) async {
        cancelDueMomentNotificationCallCount += 1
        lastCancelDueMomentTaskId = taskId
    }

    func hasDueMomentNotificationScheduled(taskId: UUID) async -> Bool {
        hasDueMomentScheduledCallCount += 1
        return hasDueMomentNotificationScheduledResult
    }
}
