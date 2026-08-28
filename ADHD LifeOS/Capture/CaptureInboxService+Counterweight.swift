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

    /// Learns the count for every OTHER offered tab so the picker isn't half-labelled on a cold
    /// start. A single-filter screen has no other tabs and fetches nothing here.
    ///
    /// Deliberately after the main load and deliberately failure-tolerant: this is decoration on
    /// tabs the user is not looking at, and it must never delay the list they are, nor turn a
    /// perfectly good load into an error. A failure just leaves that count unknown.
    ///
    /// Moved here from the service's own file, which sat at 398/400 — it belongs beside
    /// `refreshToTriageCount` anyway, since both exist to keep a tab label honest.
    func refreshInactiveCount() async {
        for inactive in availableFilters where inactive != filter {
            guard let captures = try? await fetch(inactive) else { continue }
            counts[inactive] = captures.count
        }
    }

    /// Re-learns the tabs a capture may have just ARRIVED on, after it left the one on screen.
    ///
    /// `removeCapture` keeps the active tab honest for free, because it already holds the new
    /// list. The destination cannot be known that cheaply — sorting writes `seen` and journalling
    /// writes `processed`, and which slice a document lands in is the backend query's business,
    /// not a mapping this file should duplicate and then have to keep true. So it re-reads, on
    /// exactly the contract `refreshInactiveCount` already carries: a failed fetch leaves that
    /// number alone, never surfaces an error, and never turns a successful exit into a failed one.
    ///
    /// The cost is one read per inactive tab per exit — two, on the three-tab Inbox — which is the
    /// price of "Promoted (11)" not still reading 11 once a twelfth has arrived (E's screenshot,
    /// 2026-08-28).
    ///
    /// **`weekCounterweightLine` is deliberately NOT refreshed here**, though it goes stale on the
    /// same screen for the same reason. It would cost a third read (`fetchCaptures` pulls the lot)
    /// on every single tap of a screen designed for rapid one-at-a-time triage, and it is a
    /// "this week" figure — slow-moving by construction, and wrong by at most one until the next
    /// load. The tab labels sit directly above a headline that contradicts them; that line does
    /// not. If it ever needs to be live, this is the function it belongs in.
    func refreshCountsAfterExit() async {
        await refreshInactiveCount()
    }
}
