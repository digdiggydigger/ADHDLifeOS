//
//  HomeLifeAreasSection.swift
//  ADHD LifeOS
//

import Foundation

/// Today's life-area list, the pure half — sibling of `HomeInboxPeek` and `HomeNudgesSection`.
///
/// The list is the tallest thing on Today, and collapsing it is how the screen gets back under
/// control (the nudges section already sits below the fold — a UI journey had to learn to scroll
/// for it). Collapsing must not become hiding, though: the header keeps saying what it folded away.
enum HomeLifeAreasSection {
    /// "5 areas · 3 open" — what the collapsed header carries.
    ///
    /// Nothing open is named rather than rendered as a zero, the rule "Inbox clear" and "Nothing
    /// due" already follow: an empty workload is the win state, not a deficit.
    static func collapsedLine(items: [MomentumScoreboard.AreaMomentum]) -> String {
        guard !items.isEmpty else { return "No areas yet" }
        let areas = items.count == 1 ? "1 area" : "\(items.count) areas"
        let open = items.reduce(0) { $0 + $1.open }
        return open == 0 ? "\(areas) · nothing open" : "\(areas) · \(open) open"
    }
}
