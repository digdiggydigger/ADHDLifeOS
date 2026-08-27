//
//  HomeInboxPeek.swift
//  ADHD LifeOS
//

import Foundation

/// Today's inbox card, the pure half (E's 2026-08-25 note: the tray icon's badge was the only
/// trace of the inbox on Today — a count with no content is not a shop window). This decides
/// WHICH captures peek and what the lines say; the card lays them out.
enum HomeInboxPeek {
    /// Three rows keeps the card a glance, not a second inbox — the door is for the rest.
    static let maxRows = 3

    /// The newest waiting captures, explicitly re-sorted rather than trusting the adapter's
    /// ordering — this card's whole promise is "what just landed".
    static func peek(_ captures: [Capture]) -> [Capture] {
        Array(captures.sorted { $0.createdAt > $1.createdAt }.prefix(maxRows))
    }

    static func countLine(_ count: Int) -> String {
        guard count > 0 else { return "Inbox clear" }
        return "\(count) waiting"
    }

    /// Names only what the peek cannot show; `nil` when the peek already shows everything.
    static func overflowLine(total: Int) -> String? {
        let hidden = total - maxRows
        guard hidden > 0 else { return nil }
        return "and \(hidden) more"
    }

    /// The day's throughput — captures promoted, journaled or archived today. Silent at zero:
    /// the card celebrates what moved, it never announces that nothing did.
    static func handledLine(_ count: Int) -> String? {
        guard count > 0 else { return nil }
        return "\(count) handled today"
    }

    /// Same day → the clock time; older → the date. A bare time is useless on anything older
    /// than today — the same lesson `CaptureRowPresentation.caption` already learned.
    static func timeLabel(for capture: Capture, asOf now: Date = .now, calendar: Calendar = .current) -> String {
        calendar.isDate(capture.createdAt, inSameDayAs: now)
            ? capture.createdAt.formatted(date: .omitted, time: .shortened)
            : capture.createdAt.formatted(date: .abbreviated, time: .omitted)
    }
}
