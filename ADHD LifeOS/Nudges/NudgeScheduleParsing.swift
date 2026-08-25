//
//  NudgeScheduleParsing.swift
//  ADHD LifeOS
//

import Foundation

/// A structured nudge schedule: an exact time-of-day plus a set of weekdays, using cron's
/// day-of-week convention (`0` = Sunday ... `6` = Saturday) so parsed/encoded values stay
/// cross-client-readable against web's `cron-parser`-based `schedule` column. This is a bounded
/// subset of cron — only minute, hour, and a day-of-week list/range are supported (see the
/// "Flexible Nudge Schedules" feature block in the project's task tracker); day-of-month, month,
/// and step values remain unsupported and make `parse(cronString:)` return `nil`.
struct NudgeSchedule: Equatable, Sendable {
    var hour: Int
    var minute: Int
    var weekdays: Set<Int>

    /// Parses a `MINUTE HOUR * * DOW-LIST` cron string (day-of-month and month must be `*`). The
    /// day-of-week field accepts `*`, comma-separated single days (`0`-`6`, `7` normalized to
    /// `0`), and dash ranges (e.g. `1-5`). Anything else — wrong field count, a non-`*`
    /// day-of-month/month, an out-of-range or non-integer minute/hour, step values, or an empty
    /// day list — returns `nil`, i.e. never-computably-due.
    /// "Daily at 21:00" / "Mon, Wed at 09:30" — the v3 card's schedule line. `nil` for a cron
    /// string the app cannot parse (shown raw instead, never invented).
    static func summary(cronString: String) -> String? {
        guard let schedule = NudgeSchedule.parse(cronString: cronString) else { return nil }
        let time = String(format: "%02d:%02d", schedule.hour, schedule.minute)
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        if schedule.weekdays.count == 7 {
            return "Daily at " + time
        }
        let days = schedule.weekdays.sorted().map { symbols[$0] }.joined(separator: ", ")
        return days + " at " + time
    }

    static func parse(cronString: String) -> NudgeSchedule? {
        let fields = cronString.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard fields.count == 5 else { return nil }
        let (minuteField, hourField, dayOfMonthField, monthField, dayOfWeekField) =
            (fields[0], fields[1], fields[2], fields[3], fields[4])

        guard dayOfMonthField == "*", monthField == "*" else { return nil }
        guard let minute = Int(minuteField), (0...59).contains(minute) else { return nil }
        guard let hour = Int(hourField), (0...23).contains(hour) else { return nil }
        guard let weekdays = parseWeekdays(dayOfWeekField), !weekdays.isEmpty else { return nil }

        return NudgeSchedule(hour: hour, minute: minute, weekdays: weekdays)
    }

    /// Encodes back to the same `MINUTE HOUR * * DOW-LIST` cron form — weekdays are always
    /// written as a sorted comma list (e.g. a preset written as `1-5` may round-trip as
    /// `1,2,3,4,5`; semantically equivalent, not byte-identical, which is an accepted trade-off).
    func encode() -> String {
        let days = weekdays.sorted().map(String.init).joined(separator: ",")
        return "\(minute) \(hour) * * \(days)"
    }

    private static func parseWeekdays(_ field: String) -> Set<Int>? {
        if field == "*" { return Set(0...6) }

        var result = Set<Int>()
        for token in field.split(separator: ",") {
            if let dashIndex = token.firstIndex(of: "-") {
                let lowerToken = token[token.startIndex..<dashIndex]
                let upperToken = token[token.index(after: dashIndex)...]
                guard let lower = normalizedDay(String(lowerToken)),
                      let upper = normalizedDay(String(upperToken)),
                      lower <= upper else { return nil }
                result.formUnion(lower...upper)
            } else {
                guard let day = normalizedDay(String(token)) else { return nil }
                result.insert(day)
            }
        }
        return result
    }

    /// Cron allows both `0` and `7` for Sunday; normalizes `7` to `0` so `weekdays` stays a
    /// canonical `0`-`6` set.
    private static func normalizedDay(_ token: String) -> Int? {
        guard let value = Int(token) else { return nil }
        if value == 7 { return 0 }
        guard (0...6).contains(value) else { return nil }
        return value
    }
}
