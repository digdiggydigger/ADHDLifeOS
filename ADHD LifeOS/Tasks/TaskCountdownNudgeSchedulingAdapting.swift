//
//  TaskCountdownNudgeSchedulingAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// Thin seam over `UNUserNotificationCenter` so countdown-nudge scheduling is testable without a
/// real notification center, same pattern as this codebase's Supabase client-adapter protocols.
/// Scheduling a new configuration always replaces any previously-scheduled nudges for that task —
/// there is only ever one active countdown-nudge configuration per task at a time.
protocol TaskCountdownNudgeSchedulingAdapting: Sendable {
    /// Requests notification permission if not already determined; returns whether nudges may be
    /// scheduled (already-granted or newly-granted). Does not re-prompt if previously denied.
    func requestAuthorizationIfNeeded() async -> Bool

    /// Cancels any existing nudges for `taskId`, then schedules `fireDates` as local
    /// notifications titled `taskTitle`. A `fireDates` in the past is skipped rather than firing
    /// immediately — callers are expected to have already filtered via
    /// `TaskCountdownNudgeScheduling.resolveFireDates`.
    func scheduleNudges(taskId: UUID, taskTitle: String, fireDates: [ScheduledCountdownNudge]) async

    /// Cancels every nudge currently scheduled for this task, regardless of which mode created
    /// them. Safe to call even if none exist.
    func cancelNudges(taskId: UUID) async

    /// Whether any countdown nudge is currently scheduled for this task — used to determine the
    /// "Nudge me" state when a screen loads. There's no separate persistence layer for this
    /// feature (no new DB column); `UNUserNotificationCenter`'s own pending-requests list is the
    /// source of truth.
    func hasScheduledNudges(taskId: UUID) async -> Bool

    /// Cancels any existing due-moment notification for `taskId`, then schedules a single local
    /// notification titled `taskTitle` to fire at `dueDate`. Independent of the countdown-nudge
    /// scheduling above — a distinct identifier namespace means the two never interfere with each
    /// other's pending-request lookups.
    func scheduleDueMomentNotification(taskId: UUID, taskTitle: String, dueDate: Date) async

    /// Cancels the due-moment notification currently scheduled for this task, if any. Safe to
    /// call even if none exists.
    func cancelDueMomentNotification(taskId: UUID) async

    /// Whether a due-moment notification is currently scheduled for this task — used to
    /// determine the "Notify me when this is due" toggle state when a screen loads. Same
    /// pending-requests-as-source-of-truth pattern as `hasScheduledNudges`.
    func hasDueMomentNotificationScheduled(taskId: UUID) async -> Bool
}
