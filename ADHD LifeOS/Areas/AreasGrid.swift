//
//  AreasGrid.swift
//  ADHD LifeOS
//

import Foundation

/// The pure arithmetic behind the Areas tab (F-V3-Areas): what each grid card states, the
/// unfiled-captures count, and the week-share bar. Everything derives from data the app already
/// stores, over the same rolling week as the scoreboard — no new fields, no new adapters.
enum AreasGrid {
    struct Item: Identifiable, Equatable {
        let momentum: MomentumScoreboard.AreaMomentum
        let logCount: Int
        let captureCount: Int

        /// The card's task figure: what the area holds this week — still open plus closed.
        var taskCount: Int { momentum.open + momentum.closedThisWeek }
        var id: UUID { momentum.area.id }
    }

    static func build(
        areas: [LifeArea],
        openTasks: [TaskSummary],
        allTasks: [TaskItem],
        logs: [Log],
        captures: [Capture],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> [Item] {
        MomentumScoreboard.areaMomentum(
            areas: areas, openTasks: openTasks, allTasks: allTasks, asOf: now, calendar: calendar
        ).map { momentum in
            Item(
                momentum: momentum,
                logCount: logs.filter { $0.lifeAreaId == momentum.area.id }.count,
                captureCount: captures.filter { $0.lifeAreaId == momentum.area.id }.count
            )
        }
    }

    /// "3 tasks · 1 log" — zeroes are omitted rather than printed, and an empty area says so
    /// plainly instead of listing three zeroes.
    static func metaLine(taskCount: Int, logCount: Int, captureCount: Int) -> String {
        var parts: [String] = []
        if taskCount > 0 { parts.append(taskCount == 1 ? "1 task" : "\(taskCount) tasks") }
        if logCount > 0 { parts.append(logCount == 1 ? "1 log" : "\(logCount) logs") }
        if captureCount > 0 { parts.append(captureCount == 1 ? "1 capture" : "\(captureCount) captures") }
        return parts.isEmpty ? "Nothing here yet" : parts.joined(separator: " · ")
    }

    /// Captures still waiting with no area at all — the "Unfiled" card's count.
    static func unfiledCount(captures: [Capture]) -> Int {
        captures.filter { $0.lifeAreaId == nil }.count
    }

    /// The week's closures split by area — v3's "Where the week went" stacked bar. `nil` when
    /// nothing closed (the views hide the chart rather than drawing an empty rail), and the
    /// caption names the quiet areas instead of letting absence pass silently.
    struct WeekShareSegment: Equatable {
        let area: LifeArea
        let count: Int
        let fraction: Double
    }

    struct WeekShare: Equatable {
        let segments: [WeekShareSegment]
        let caption: String
    }

    static func weekShare(
        areas: [LifeArea],
        allTasks: [TaskItem],
        asOf now: Date = .now,
        calendar: Calendar = .current
    ) -> WeekShare? {
        let week = MomentumScoreboard.closedThisWeek(tasks: allTasks, asOf: now, calendar: calendar)
        let counts = areas.map { area in (area, week.filter { $0.lifeAreaId == area.id }.count) }
        let total = counts.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return nil }
        let segments = counts.filter { $0.1 > 0 }.map { area, count in
            WeekShareSegment(area: area, count: count, fraction: Double(count) / Double(total))
        }
        let listed = segments.map { "\($0.count) \($0.area.name)" }.joined(separator: ", ")
        var caption = "\(total) \(total == 1 ? "item" : "items") closed: \(listed)."
        let quiet = counts.filter { $0.1 == 0 }.map(\.0.name)
        if !quiet.isEmpty {
            caption += " Nothing in \(quiet.joined(separator: ", "))."
        }
        return WeekShare(segments: segments, caption: caption)
    }
}
