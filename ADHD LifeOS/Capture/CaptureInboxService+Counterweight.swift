//
//  CaptureInboxService+Counterweight.swift
//  ADHD LifeOS
//
//  S1's weekly capture-vs-clear counterweight (Concept C, block M10), in its own file the way
//  `+Media`/`+Tags`/`+Triage` keep the core service inside its length budget.
//

import Foundation

@MainActor
extension CaptureInboxService {
    /// Decoration by the same rule as `refreshInactiveCount`: fetched after the list the user
    /// is looking at, and failure-tolerant — a failed fetch keeps the previous line (nil on a
    /// cold start) rather than turning a good load into an error. Quick capture calls this
    /// directly, since it never runs `load()`.
    func refreshWeekCounterweight() async {
        guard let captures = try? await client.fetchCaptures() else { return }
        weekCounterweightLine = CaptureInboxSummary.weeklyCounterweight(for: captures)
        weekHealth = CaptureInboxSummary.weekHealth(for: captures)
    }

    /// The Captures tab does not OFFER the to-triage slice, so `refreshInactiveCount` never learns
    /// it — but that tab's Inbox door has to carry a live number (E, 2026-08-28: "keep the list,
    /// make the door louder"). Lives here rather than in the service's own file only because that
    /// file sits at its length ceiling; `fetch`/`counts` are internal for exactly this reason.
    ///
    /// Failure-tolerant like every other count on these screens: an unknown count renders no line
    /// at all rather than claiming zero.
    func refreshToTriageCount() async {
        guard !availableFilters.contains(.unprocessed),
              let waiting = try? await fetch(.unprocessed) else { return }
        counts[.unprocessed] = waiting.count
    }
}
