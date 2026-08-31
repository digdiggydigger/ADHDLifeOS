//
//  LogComposerCopy.swift
//  ADHD LifeOS
//

import Foundation

/// The v3 entry composer's voice (the S1 pattern applied to the journal): say what each type
/// means instead of assuming the Log/Journal split is obvious, and say the append-only rule out
/// loud before the save, not after.
enum LogComposerCopy {
    static let guidance = "One honest line about now is enough."
    static let footer = "Entries are append-only — saved means saved."

    static func explainer(for type: LogType) -> String {
        switch type {
        case .log: return "A quick line, saved as-is — no questions asked."
        case .journal: return "A fuller entry — energy and mood ride along."
        }
    }

    /// What the location switch promises about THIS entry (E, 2026-08-31) — the capture
    /// composer's subtitle, upgraded to name the place when one resolves, in
    /// `JournalTimeline.placeLine`'s spelling. Off wins over a stale place line: the preview is
    /// cleared on toggle-off, but a race must never leave "at The Office" under a switch that
    /// says it won't record.
    static func locationSubtitle(attach: Bool, placeLine: String?) -> String {
        guard attach else { return "This entry won't record where you made it." }
        guard let placeLine else { return "This entry will record where you made it." }
        return "This entry will record you're \(placeLine)."
    }
}
