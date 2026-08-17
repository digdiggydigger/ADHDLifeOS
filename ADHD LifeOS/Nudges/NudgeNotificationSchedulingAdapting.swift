//
//  NudgeNotificationSchedulingAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Thin seam over `UNUserNotificationCenter` for recurring Nudges push notifications — mirrors
/// `TaskCountdownNudgeSchedulingAdapting`'s shape exactly. Fully independent of the in-app
/// due/dismiss system (`NudgeDueness`, `markFired`): scheduling here never reads or writes
/// `lastFiredAt`, and the in-app "due" computation never consults what's scheduled here.
protocol NudgeNotificationSchedulingAdapting: Sendable {
    /// Requests notification permission if not already determined; returns whether notifications
    /// may be scheduled (already-granted or newly-granted). Does not re-prompt if previously
    /// denied.
    func requestAuthorizationIfNeeded() async -> Bool

    /// Cancels any existing notifications for `nudgeId`, then schedules one recurring
    /// notification per weekday in `schedule.weekdays` (a single `UNCalendarNotificationTrigger`
    /// can't express "any of these weekdays," so a schedule spanning several weekdays needs one
    /// request per day).
    func scheduleNotifications(nudgeId: UUID, label: String, schedule: NudgeSchedule) async

    /// Cancels every notification currently scheduled for this nudge, regardless of how many
    /// weekdays it covered. Safe to call even if none exist.
    func cancelNotifications(nudgeId: UUID) async

    /// Whether any notification is currently scheduled for this nudge. There's no separate
    /// persistence layer for this feature (no new DB column); `UNUserNotificationCenter`'s own
    /// pending-requests list is the source of truth.
    func hasScheduledNotifications(nudgeId: UUID) async -> Bool
}
