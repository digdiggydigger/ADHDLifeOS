//
//  CaptureSkipOrdering.swift
//  ADHD LifeOS
//

import Foundation

/// The triage card's Skip (SUGG-b9): the top capture goes to the back of the queue and the next
/// one surfaces. A pure stage AFTER `CaptureListRefinement`, keyed by id, so the ordering
/// survives the app-wide `DataChangeSignal` refetch — the fetch replaces the array, the skip
/// list stays. Nothing is written anywhere: skipping is a way of looking, not a triage decision.
enum CaptureSkipOrdering {
    /// Unskipped captures keep their refined order; skipped ones follow, in the order they were
    /// skipped. Ids that no longer match a capture (triaged away since) contribute nothing.
    static func apply(captures: [Capture], skippedIds: [UUID]) -> [Capture] {
        guard !skippedIds.isEmpty else { return captures }
        let byId = Dictionary(uniqueKeysWithValues: captures.map { ($0.id, $0) })
        let skippedSet = Set(skippedIds)
        let unskipped = captures.filter { !skippedSet.contains($0.id) }
        let skipped = skippedIds.compactMap { byId[$0] }
        return unskipped + skipped
    }
}
