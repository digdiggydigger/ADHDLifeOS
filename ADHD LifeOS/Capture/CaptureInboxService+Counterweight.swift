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
    }
}
