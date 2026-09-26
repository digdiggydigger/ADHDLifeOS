//
//  TodayCardCopy.swift
//  ADHD LifeOS
//
//  `F-E3-OneCardToday`: every word Today's one card and the lines beneath it say, as pure
//  functions — from board `59` (the frames E chose H1 from) and the round-5 record. Sentence case
//  here; the eyebrow is drawn with `sectionLabel()`, which capitalises it on screen.
//

import Foundation

enum TodayCardCopy {
    /// The card's eyebrow. The place pair draws its own cards and an empty Today draws none, so
    /// neither has one.
    static func eyebrow(
        for slot: TodaySlot,
        asOf now: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String? {
        switch slot {
        case .pinned:
            return "Next · Pinned"
        case .suggested(let task):
            return "Suggested" + dueSuffix(task, asOf: now, calendar: calendar)
        case .paused(let sprint):
            return "Paused · \(sprint.elapsedSeconds / 60) min in"
        case .leaveBy(let commitment, _):
            return "Leave by \(clockTime(commitment.leaveAt, calendar: calendar, locale: locale)) · \(commitment.title)"
        case .place, .nothing:
            return nil
        }
    }

    /// Round 8: *"Still open"* replaced "Overdue" — the app never tallies what was missed.
    private static func dueSuffix(_ task: TaskSummary, asOf now: Date, calendar: Calendar) -> String {
        guard let due = task.dueDate else { return "" }
        let day = calendar.startOfDay(for: due)
        let today = calendar.startOfDay(for: now)
        if day == today { return " · Due today" }
        return day < today ? " · Still open" : ""
    }

    private static func clockTime(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("jmm")
        return formatter.string(from: date)
    }

    /// "Start N min" promises exactly the sprint that launches: the same resolution
    /// `FocusSprintPlan(summary:lifeArea:defaultDurationSeconds:)` applies, so a task with no stored
    /// length says the default rather than a number the sprint will not run.
    static func startTitle(for task: TaskSummary, defaultSprintMinutes: Int) -> String {
        let seconds = FocusSprintConfiguration.resolvedDuration(
            explicit: task.focusDurationSeconds, defaultSeconds: defaultSprintMinutes * 60
        )
        return "Start \(max(1, Int((Double(seconds) / 60).rounded()))) min"
    }

    /// What tapping the pin does, not what it is — VoiceOver reads the verb.
    static func pinLabel(isPinned: Bool) -> String {
        isPinned ? "Unpin" : "Pin to Today"
    }

    /// "8 min left of 20". A part-minute left rounds UP: rounding it down to 0 would read as done.
    static func pausedDetail(_ sprint: TodayPausedSprint) -> String {
        let left = Int((Double(sprint.remainingSeconds) / 60).rounded(.up))
        let total = Int((Double(sprint.durationSeconds) / 60).rounded())
        return "\(left) min left of \(total)"
    }

    /// A "then" row's second line, board `59`'s "🏠 Home · 15 min".
    static func thenMeta(area: LifeArea?, focusDurationSeconds: Int?) -> String? {
        let parts = [
            area.map { "\($0.colour) \($0.name)" },
            MomentumScoreboard.effortLabel(seconds: focusDurationSeconds)
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Idea 9, board `59`: *"✓ 3 done today · Week review ›"*. Once a daily goal is set, E's call
    /// (2026-09-26, Q2): *"'3 of 5 done today'"* — with the ring gone this is the only place a
    /// chosen goal can be seen, and it keeps counting past the goal rather than stopping at it.
    static func doneTodayLine(count: Int, goal: Int?) -> String {
        guard let goal else { return "\(count) done today" }
        return "\(count) of \(goal) done today"
    }
}
