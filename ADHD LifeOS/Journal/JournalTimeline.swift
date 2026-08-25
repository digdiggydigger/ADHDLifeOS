//
//  JournalTimeline.swift
//  ADHD LifeOS
//

import Foundation

/// The v3 Journal's day-grouped timeline (F-V3-Journal): written entries and closed tasks share
/// one stream, grouped by day, newest day first, each day reading in the order it happened.
/// Closed NUDGES are deliberately absent — only `last_fired_at` exists, which is not a
/// completion history (the honest-data rule; V3-Nudges adds real stamps going forward).
enum JournalTimeline {
    enum Entry: Equatable, Identifiable {
        case log(Log)
        case closedTask(TaskItem)

        var id: UUID {
            switch self {
            case .log(let log): return log.id
            case .closedTask(let task): return task.id
            }
        }

        var timestamp: Date {
            switch self {
            case .log(let log): return log.entryDate
            case .closedTask(let task): return task.completedAt ?? .distantPast
            }
        }
    }

    enum Filter: CaseIterable, Equatable {
        case everything
        case written
        case closed

        var title: String {
            switch self {
            case .everything: return "Everything"
            case .written: return "Written"
            case .closed: return "Closed"
            }
        }
    }

    struct Day: Equatable, Identifiable {
        let date: Date
        let title: String
        let entries: [Entry]
        var id: Date { date }
    }

    static func days(
        logs: [Log],
        tasks: [TaskItem],
        filter: Filter = .everything,
        lifeAreaId: UUID? = nil,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> [Day] {
        var entries: [Entry] = []
        if filter != .closed {
            entries += logs
                .filter { lifeAreaId == nil || $0.lifeAreaId == lifeAreaId }
                .map(Entry.log)
        }
        if filter != .written {
            entries += tasks
                .filter { $0.status == .done && $0.completedAt != nil }
                .filter { lifeAreaId == nil || $0.lifeAreaId == lifeAreaId }
                .map(Entry.closedTask)
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

    private static func title(for day: Date, asOf now: Date, calendar: Calendar) -> String {
        let today = calendar.startOfDay(for: now)
        if day == today { return "Today" }
        if day == calendar.date(byAdding: .day, value: -1, to: today) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}
