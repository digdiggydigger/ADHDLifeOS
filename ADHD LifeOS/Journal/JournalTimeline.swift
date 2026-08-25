//
//  JournalTimeline.swift
//  ADHD LifeOS
//

import Foundation

/// The v3 Journal's day-grouped timeline (F-V3-Journal): written entries, closed tasks, finished
/// focus sprints and the capture log share one stream (the last two per E's 2026-08-25 note),
/// grouped by day, newest day first, each day reading in the order it happened.
/// Closed NUDGES are deliberately absent — only `last_fired_at` exists, which is not a
/// completion history (the honest-data rule; V3-Nudges adds real stamps going forward).
enum JournalTimeline {
    enum Entry: Equatable, Identifiable {
        case log(Log)
        case closedTask(TaskItem)
        case focusSprint(CompletedFocusSession)
        case capture(Capture)

        /// Safe as a bare UUID across all four kinds: each wraps its own document's id, and a
        /// promoted task mints a fresh UUID rather than reusing its capture's — no two entries in
        /// one ForEach can collide (the sibling-identity trap the nudge journey once caught).
        var id: UUID {
            switch self {
            case .log(let log): return log.id
            case .closedTask(let task): return task.id
            case .focusSprint(let sprint): return sprint.id
            case .capture(let capture): return capture.id
            }
        }

        var timestamp: Date {
            switch self {
            case .log(let log): return log.entryDate
            case .closedTask(let task): return task.completedAt ?? .distantPast
            case .focusSprint(let sprint): return sprint.endedAt
            case .capture(let capture): return capture.createdAt
            }
        }
    }

    enum Filter: CaseIterable, Equatable {
        case everything
        case written
        case closed
        case sprints
        case captured

        var title: String {
            switch self {
            case .everything: return "Everything"
            case .written: return "Written"
            case .closed: return "Closed"
            case .sprints: return "Sprints"
            case .captured: return "Captured"
            }
        }
    }

    struct Day: Equatable, Identifiable {
        let date: Date
        let title: String
        let entries: [Entry]
        var id: Date { date }
    }

    /// `lifeAreaId` narrows logs, closed tasks and captures — each document carries the id. It
    /// deliberately does NOT touch sprints: a focus session stores only the area's stamped emoji,
    /// so an id can't reach it; the view pre-filters sprints by that emoji instead.
    static func days(
        logs: [Log],
        tasks: [TaskItem],
        sprints: [CompletedFocusSession] = [],
        captures: [Capture] = [],
        filter: Filter = .everything,
        lifeAreaId: UUID? = nil,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> [Day] {
        var entries: [Entry] = []
        if filter == .everything || filter == .written {
            entries += logs
                .filter { lifeAreaId == nil || $0.lifeAreaId == lifeAreaId }
                .map(Entry.log)
        }
        if filter == .everything || filter == .closed {
            entries += tasks
                .filter { $0.status == .done && $0.completedAt != nil }
                .filter { lifeAreaId == nil || $0.lifeAreaId == lifeAreaId }
                .map(Entry.closedTask)
        }
        if filter == .everything || filter == .sprints {
            entries += sprints.map(Entry.focusSprint)
        }
        if filter == .everything || filter == .captured {
            entries += captures
                .filter { lifeAreaId == nil || $0.lifeAreaId == lifeAreaId }
                .map(Entry.capture)
        }
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.timestamp) }
        return grouped
            .sorted { $0.key > $1.key }
            .map { day, members in
                Day(
                    date: day,
                    title: title(for: day, asOf: now, calendar: calendar),
                    entries: members.sorted { $0.timestamp < $1.timestamp }
                )
            }
    }

    /// "8 closed · 2 written this week" — the header's eyebrow, over the same rolling week as
    /// the scoreboard.
    static func headerLine(
        logs: [Log],
        tasks: [TaskItem],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let closed = MomentumScoreboard.closedThisWeek(tasks: tasks, asOf: now, calendar: calendar).count
        let today = calendar.startOfDay(for: now)
        let windowStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let written = logs.filter { $0.entryDate >= windowStart }.count
        return "\(closed) closed · \(written) written this week"
    }

    /// The sprint row's fact line: "25 min sprint" when it ran its course, "12 of 25 min sprint"
    /// when stopped early — never a silent rounding-up of an abandoned sprint into a full one.
    /// Floor division with a 1-minute floor, same arithmetic as `FocusAnalytics.focusedMinutes`,
    /// so a sub-minute sprint prints "1 min" rather than "0 min".
    static func sprintLine(for session: CompletedFocusSession) -> String {
        let focused = max(1, session.focusedSeconds / 60)
        guard !session.completedNaturally else { return "\(focused) min sprint" }
        let planned = max(1, session.plannedSeconds / 60)
        return "\(focused) of \(planned) min sprint"
    }

    private static func title(for day: Date, asOf now: Date, calendar: Calendar) -> String {
        let today = calendar.startOfDay(for: now)
        if day == today { return "Today" }
        if day == calendar.date(byAdding: .day, value: -1, to: today) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}
