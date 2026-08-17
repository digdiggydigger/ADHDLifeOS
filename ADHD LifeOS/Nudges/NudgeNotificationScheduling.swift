//
//  NudgeNotificationScheduling.swift
//  ADHD LifeOS
//

import Foundation

/// Pure weekday-conversion + one-per-weekday expansion, isolated from `NotificationCenterNudgeAdapter`
/// so it's unit-testable without a real `UNUserNotificationCenter` (same pure/impure split as
/// `TaskCountdownNudgeScheduling`).
enum NudgeNotificationScheduling {
    /// One `DateComponents` per weekday in `schedule.weekdays`, each carrying `hour`/`minute` plus
    /// a `weekday` field. `NudgeSchedule.weekdays` uses cron's `0`(Sun)–`6`(Sat) convention (see
    /// `NudgeScheduleParsing.swift`), but `DateComponents.weekday` is `1`(Sun)–`7`(Sat) — this
    /// `+ 1` conversion is the one thing here that must be exact, or notifications fire on the
    /// wrong day.
    static func triggerComponents(for schedule: NudgeSchedule) -> [DateComponents] {
        schedule.weekdays.sorted().map { cronWeekday in
            var components = DateComponents()
            components.hour = schedule.hour
            components.minute = schedule.minute
            components.weekday = cronWeekday + 1
            return components
        }
    }
}
