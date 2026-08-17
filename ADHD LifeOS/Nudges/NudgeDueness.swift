//
//  NudgeDueness.swift
//  ADHD LifeOS
//

import Foundation

/// Mirrors web's `isNudgeDue`, but computes next-fire-time in the device's local timezone rather
/// than hardcoding UTC — web's `isNudgeDue` hardcodes `tz: 'UTC'`, causing nudges to fire an hour
/// late during BST (`QA_AUDIT.md` FIX-005, unfixed on web). Mobile does not port that bug.
enum NudgeDueness {
    /// A nudge is due when it's active, its schedule parses (see `NudgeSchedule.parse`), and the
    /// next scheduled fire time strictly after its reference date (`lastFiredAt` if it has ever
    /// fired, else `createdAt`) has already elapsed by `now`.
    static func isNudgeDue(nudge: Nudge, now: Date, timeZone: TimeZone = .current) -> Bool {
        guard nudge.active else { return false }
        guard let schedule = NudgeSchedule.parse(cronString: nudge.schedule) else { return false }

        let referenceDate = nudge.lastFiredAt ?? nudge.createdAt
        let next = nextFireTime(after: referenceDate, schedule: schedule, timeZone: timeZone)
        return next <= now
    }

    /// Walks forward day-by-day (bounded to a week, since every supported schedule repeats
    /// within 7 days) looking for the first local-time occurrence at the schedule's hour/minute
    /// that is both strictly after `reference` and on a day its weekday set allows.
    private static func nextFireTime(after reference: Date, schedule: NudgeSchedule, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        var day = calendar.startOfDay(for: reference)
        for _ in 0..<8 {
            let weekday = calendar.component(.weekday, from: day) - 1 // Foundation 1-7 -> cron 0-6
            if let candidate = calendar.date(bySettingHour: schedule.hour, minute: schedule.minute, second: 0, of: day),
               candidate > reference,
               schedule.weekdays.contains(weekday) {
                return candidate
            }
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
        }
        return .distantFuture
    }
}
