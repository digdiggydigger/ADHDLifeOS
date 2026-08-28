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

    /// Whether the header carries its Arrange control.
    ///
    /// **Two conditions, and both are about the control having something to do.** Reordering is
    /// meaningless below two rows — that rule predates the fold. And a FOLDED section has no rows
    /// on screen at all, so the button's entire effect would happen out of sight (E's screenshot
    /// note, 2026-08-28: it should hide inside the fold along with the list it reorders). Worse
    /// than useless, in fact: entering Arrange mode force-expands the section, so tapping it while
    /// folded would silently undo the fold the user had just chosen.
    ///
    /// That same force-expansion is what makes hiding it safe. Throughout Arrange mode
    /// `isExpanded` is true, so the button — reading "Done" by then — stays on screen as the way
    /// back out. There is no state in which this rule strands someone inside the mode.
    static func showsArrangeControl(areaCount: Int, isExpanded: Bool) -> Bool {
        areaCount >= 2 && isExpanded
    }
}
