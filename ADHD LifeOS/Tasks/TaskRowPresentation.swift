//
//  TaskRowPresentation.swift
//  ADHD LifeOS
//

import Foundation

/// The dense task row's one-line meta (F-V3-Tasks-rebuild, the design frame's
/// "💼 Work & Career · P1" line): area · priority · due phrase while a task is open,
/// area · closed time once it isn't. Pure strings so the row view stays logic-free and the
/// wording is pinned by tests.
enum TaskRowPresentation {
    static func metaLine(
        task: TaskItem,
        lifeArea: LifeArea?,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        var parts: [String] = []
        if let lifeArea {
            parts.append("\(lifeArea.colour) \(lifeArea.name)")
        }
        if task.status == .done {
            parts.append(closedPhrase(task: task, calendar: calendar))
        } else {
            parts.append(task.priority.rawValue.uppercased())
            if let duePhrase = duePhrase(for: task.dueDate, asOf: now, calendar: calendar) {
                parts.append(duePhrase)
            }
        }
        return parts.joined(separator: " · ")
    }

    /// Same content in VoiceOver's voice: names spelled out, no emoji, no separator dots.
    static func accessibilityLabel(
        task: TaskItem,
        lifeArea: LifeArea?,
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        var parts: [String] = []
        if let lifeArea {
            parts.append(lifeArea.name)
        }
        if task.status == .done {
            parts.append(closedPhrase(task: task, calendar: calendar))
        } else {
            parts.append("Priority \(task.priority.rawValue)")
            if let duePhrase = duePhrase(for: task.dueDate, asOf: now, calendar: calendar) {
                parts.append(duePhrase)
            }
        }
        return parts.joined(separator: ", ")
    }

    /// "closed 05:41" — the frame's Closed-today reading. `status: done` with no stamp means
    /// "done, at an unknown time" (see `TaskCompletionStamp`), so no moment is invented for it.
    private static func closedPhrase(task: TaskItem, calendar: Calendar) -> String {
        guard let completedAt = task.completedAt else { return "closed" }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "closed \(formatter.string(from: completedAt))"
    }

    private static func duePhrase(for dueDate: Date?, asOf now: Date, calendar: Calendar) -> String? {
        guard let dueDate else { return nil }
        let today = calendar.startOfDay(for: now)
        let dueDay = calendar.startOfDay(for: dueDate)
        if dueDay < today { return "Overdue" }
        if dueDay == today { return "Due today" }
        return dueDate.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }
}
