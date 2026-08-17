//
//  TaskCountdownNudgeScheduling.swift
//  ADHD LifeOS
//

import Foundation

/// Pure countdown-nudge math for "FEATURE: Task Due-Time Nudges" — independent of
/// `UNUserNotificationCenter` for testability, same pattern as every other pure-logic module in
/// this codebase (`NudgeDueness`, `TaskGrouping`, etc.). Mirrors the design's worked example: `T`
/// minutes remaining split into `N + 1` equal segments for the ≤6-hour even-division mode; a
/// fixed, filtered checkpoint set for the >6-hour adaptive mode.
enum TaskCountdownNudgeScheduling {
    static let evenDivisionCutoff: TimeInterval = 6 * 3600

    static func mode(now: Date, dueDate: Date) -> NudgeCountdownMode {
        dueDate.timeIntervalSince(now) <= evenDivisionCutoff ? .evenDivision : .checkpoint
    }

    /// Fire dates for `count` evenly-spaced nudges between `now` and `dueDate`. Returns an empty
    /// array if the due date isn't strictly in the future or `count` isn't positive — nothing
    /// valid to schedule.
    static func evenDivisionFireDates(now: Date, dueDate: Date, count: Int) -> [Date] {
        let remaining = dueDate.timeIntervalSince(now)
        guard remaining > 0, count > 0 else { return [] }
        let segment = remaining / Double(count + 1)
        return (1...count).map { now.addingTimeInterval(segment * Double($0)) }
    }

    /// The 1/2/3-nudge menu for the ≤6-hour mode, each pre-labeled with its actual interval.
    /// Empty if the due date has already passed (nothing valid to offer).
    static func evenDivisionMenuOptions(now: Date, dueDate: Date) -> [EvenDivisionMenuOption] {
        (1...3).compactMap { count in
            let fireDates = evenDivisionFireDates(now: now, dueDate: dueDate, count: count)
            guard !fireDates.isEmpty else { return nil }
            let remaining = dueDate.timeIntervalSince(now)
            let intervalMinutes = (remaining / Double(count + 1)) / 60
            let plural = count == 1 ? "" : "s"
            let description = "\(count) nudge\(plural) (every \(formatMinutes(intervalMinutes)))"
            return EvenDivisionMenuOption(count: count, intervalDescription: description, fireDates: fireDates)
        }
    }

    /// Checkpoints that land strictly between `now` and `dueDate`, in farthest-to-nearest order —
    /// a task due in 3 months naturally excludes near-term checkpoints already in the past
    /// relative to `now`, and a task due in 2 days excludes checkpoints further out than that.
    static func applicableCheckpoints(now: Date, dueDate: Date) -> [NudgeCheckpoint] {
        NudgeCheckpoint.allCases.filter { fireDate(for: $0, dueDate: dueDate) > now }
    }

    static func fireDate(for checkpoint: NudgeCheckpoint, dueDate: Date) -> Date {
        dueDate.addingTimeInterval(-checkpoint.offset)
    }

    /// Resolves a user's `NudgeCountdownSelection` into concrete fire times + notification body
    /// text, ready for the scheduling adapter. Checkpoints that have already passed relative to
    /// `now` (e.g. the due date was edited after the selection was made) are silently dropped
    /// rather than scheduling a notification in the past.
    static func resolveFireDates(
        selection: NudgeCountdownSelection,
        now: Date,
        dueDate: Date
    ) -> [ScheduledCountdownNudge] {
        switch selection {
        case .none:
            return []
        case .evenDivision(let count):
            return evenDivisionFireDates(now: now, dueDate: dueDate, count: count)
                .map { ScheduledCountdownNudge(date: $0, body: "This task is due soon.") }
        case .checkpoints(let checkpoints):
            return checkpoints
                .map { (checkpoint: $0, date: fireDate(for: $0, dueDate: dueDate)) }
                .filter { $0.date > now }
                .map { ScheduledCountdownNudge(date: $0.date, body: $0.checkpoint.label) }
                .sorted { $0.date < $1.date }
        }
    }

    private static func formatMinutes(_ minutes: Double) -> String {
        if minutes < 1 {
            let seconds = Int((minutes * 60).rounded())
            return "\(seconds)s"
        }
        if minutes.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(minutes)) min"
        }
        return String(format: "%.1f min", minutes)
    }
}
