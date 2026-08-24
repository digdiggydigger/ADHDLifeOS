//
//  CaptureInboxSummary.swift
//  ADHD LifeOS
//

import Foundation

/// The Inbox header's at-a-glance summary. Pure, like `CaptureRowPresentation` beside it: it
/// decides *what the header says*, never how it is laid out.
///
/// An undifferentiated list of captures is just another pile — the thing an ADHD inbox is supposed
/// to relieve. Naming the shape of the backlog ("2 notes · 1 voice memo") up front lets the user
/// decide how to attack it before reading a single row.
enum CaptureInboxSummary {
    /// The headline count. Zero on the triage tab is deliberately NOT "0 to triage": an empty inbox
    /// is the win state, not a deficit, and should read like one.
    ///
    /// The tab matters — the Promoted tab lists captures already dealt with, so heading it
    /// "N to triage" says the opposite of the truth (seen in-simulator, 2026-08-20).
    static func headline(count: Int, filter: CaptureInboxService.Filter) -> String {
        switch filter {
        case .unprocessed:
            return count <= 0 ? "Inbox clear" : "\(count) to triage"
        case .seen:
            return count <= 0 ? "Nothing seen yet" : "\(count) seen"
        case .promoted:
            return count <= 0 ? "Nothing promoted yet" : "\(count) promoted"
        }
    }

    /// "oldest is 18 hours old" — the inbox's ageing counterweight (Concept C, M5): a frictionless
    /// capture button needs the screen to admit how long things have sat. Hours under two days,
    /// then days; `nil` with nothing waiting so the header drops the clause.
    static func oldestLine(for captures: [Capture], asOf now: Date = .now) -> String? {
        guard let oldest = captures.map(\.createdAt).min() else { return nil }
        let hours = Int(now.timeIntervalSince(oldest) / 3600)
        switch hours {
        case ..<1: return "oldest is under an hour old"
        case 1: return "oldest is 1 hour old"
        case ..<48: return "oldest is \(hours) hours old"
        default: return "oldest is \(hours / 24) days old"
        }
    }

    /// "2 notes · 1 voice memo" — every kind with something waiting, in a fixed order so the same
    /// inbox always reads the same way regardless of capture order. Empty when nothing is waiting,
    /// so the header can drop the line entirely rather than render a stray separator.
    static func breakdown(for captures: [Capture]) -> String {
        CaptureKind.allCases
            .compactMap { kind -> String? in
                let count = captures.filter { $0.kind == kind }.count
                guard count > 0 else { return nil }
                return "\(count) \(name(for: kind, count: count))"
            }
            .joined(separator: " · ")
    }

    /// Kind names read as plain English rather than as enum cases — `voice` alone is an adjective,
    /// so it becomes "voice memo".
    private static func name(for kind: CaptureKind, count: Int) -> String {
        let singular: String
        switch kind {
        case .note: singular = "note"
        case .task: singular = "task"
        case .link: singular = "link"
        case .voice: singular = "voice memo"
        case .photo: singular = "photo"
        }
        return count == 1 ? singular : singular + "s"
    }
}
