//
//  NudgeSchedulePreset.swift
//  ADHD LifeOS
//

import Foundation

/// The three repeat patterns almost every nudge actually wants, plus the escape hatch.
///
/// The old New nudge sheet offered only seven day toggles, so "every weekday" — the commonest
/// answer there is — cost five taps on chips that were too narrow to read (every label wrapped
/// mid-word: "S/un", "M/on", "W/ed"). E's verdict on the device was "very ugly and awkward to
/// use". Presets make the common case one tap and demote the day-by-day picker to the disclosure
/// it should always have been.
///
/// Weekday numbering is cron's, `0` = Sunday … `6` = Saturday, matching `NudgeSchedule` and the
/// `schedule` column web reads. That is the whole reason `.weekdays` is `1...5`: the obvious-
/// looking `0...4` would schedule Sunday–Thursday and still read correct in review.
enum NudgeSchedulePreset: String, CaseIterable, Sendable {
    case daily
    case weekdays
    case weekends
    case custom

    /// The weekday set this preset selects, or `nil` for `.custom`.
    ///
    /// `.custom` deliberately has no canonical set. It is whatever the user picked, so answering
    /// with one would let re-selecting the chip overwrite their selection.
    var weekdays: Set<Int>? {
        switch self {
        case .daily: return Set(0...6)
        case .weekdays: return [1, 2, 3, 4, 5]
        case .weekends: return [0, 6]
        case .custom: return nil
        }
    }

    var title: String {
        switch self {
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .custom: return "Custom"
        }
    }

    /// Which preset a weekday set corresponds to.
    ///
    /// **The empty set is `.custom`, not `.daily`.** Nothing selected cannot be saved —
    /// `NudgeValidation` rejects it and `NudgeSchedule.parse` treats an empty day list as
    /// never-computably-due — so showing a lit Daily chip for it would promise a schedule the
    /// app will refuse.
    static func matching(weekdays: Set<Int>) -> NudgeSchedulePreset {
        for preset in allCases where preset != .custom {
            if preset.weekdays == weekdays { return preset }
        }
        return .custom
    }

    /// The plain-language line under the chips, so the selection is legible without counting dots.
    ///
    /// Custom sets are listed in WEEK order. A `Set` has no order of its own, so rendering it raw
    /// would produce a different sentence between runs for the same schedule.
    static func daySummary(weekdays: Set<Int>) -> String {
        guard !weekdays.isEmpty else { return "No days selected" }
        switch matching(weekdays: weekdays) {
        case .daily: return "Every day"
        case .weekdays: return "Every weekday"
        case .weekends: return "Weekends"
        case .custom: return weekdays.sorted().map { Self.symbols[$0] }.joined(separator: ", ")
        }
    }

    /// Short weekday names in cron order. Shared by the summary line and the Custom picker so the
    /// two can never disagree about which column is which day.
    static let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    /// The single letter each Custom chip shows. Two Tuesdays' worth of ambiguity ("T" and "T",
    /// "S" and "S") is resolved by position, exactly as the system Clock app's alarm repeat
    /// picker does it — the row is always Sun-first and always seven wide.
    static let initials = ["S", "M", "T", "W", "T", "F", "S"]
}
