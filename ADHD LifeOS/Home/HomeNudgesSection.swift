//
//  HomeNudgesSection.swift
//  ADHD LifeOS
//

import Foundation

/// Today's nudges module, the pure half — sibling of `HomeInboxPeek` beside it.
///
/// Nudges lost their tab when Captures took the slot back (E's call, 2026-08-28), so Today is
/// where a due nudge is now met and dismissed. That is a deliberate reversal of F-V3-Today, which
/// had replaced Today's inline dismiss strip with a "Nudges waiting" row that only crossed to the
/// tab: with no tab to cross to, a teaser row would leave Today announcing work it could not let
/// you do.
///
/// This decides WHICH nudges appear inline and what the lines say; the section lays them out, and
/// everything the module cannot hold — creating, editing, rescheduling, the completion history —
/// stays on the pushed `NudgesView`.
enum HomeNudgesSection {
    /// Today is the app's densest screen, so the inline cards are capped and the rest are named
    /// rather than rendered — the `HomeInboxPeek.maxRows` bargain, for the same reason.
    static let maxCards = 3

    /// The due nudges that get a card, oldest-due first so the one that has waited longest is the
    /// one you meet. Explicitly re-sorted rather than trusting the caller's ordering.
    static func cards(_ due: [Nudge]) -> [Nudge] {
        Array(due.sorted { lastFired($0) < lastFired($1) }.prefix(maxCards))
    }

    /// Names only what the cards cannot show; `nil` when they already show everything.
    static func overflowLine(dueCount: Int) -> String? {
        let hidden = dueCount - maxCards
        guard hidden > 0 else { return nil }
        return hidden == 1 ? "and 1 more due" : "and \(hidden) more due"
    }

    /// The section's eyebrow. Zero due is not a deficit — it is the state a nudge schedule is
    /// FOR — so it reads as settled rather than as a count of nothing.
    static func countLine(dueCount: Int, scheduledCount: Int) -> String {
        guard dueCount > 0 else {
            return scheduledCount > 0 ? "Nothing due · \(scheduledCount) scheduled" : "No nudges yet"
        }
        return "\(dueCount) due · \(max(scheduledCount, 0)) scheduled"
    }

    /// How many active nudges are NOT due — the "scheduled" half of the eyebrow. Inactive nudges
    /// are excluded: a paused nudge is not waiting for you.
    static func scheduledCount(all: [Nudge], due: [Nudge]) -> Int {
        let dueIds = Set(due.map(\.id))
        return all.filter { $0.active && !dueIds.contains($0.id) }.count
    }

    /// A nudge's reference moment — the same one `NudgeDueness` measures dueness from, so
    /// "waited longest" here means what it means there.
    private static func lastFired(_ nudge: Nudge) -> Date {
        nudge.lastFiredAt ?? nudge.createdAt
    }
}
