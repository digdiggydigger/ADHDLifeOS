//
//  TagEditorPresentation.swift
//  ADHD LifeOS
//

import Foundation

/// Pure, unit-testable presentation logic for the tag editor. No SwiftUI import: this decides *what
/// strings/identifiers* the row and alerts show, never *how* they are laid out. The usage-count
/// phrasing is a real zero/singular/plural branch, tested like `CaptureRowPresentation`.
enum TagEditorPresentation {
    /// Human phrasing for a tag's usage count: `0` → "Not used yet", `1` → "Used on 1 item",
    /// otherwise "Used on N items".
    static func usagePhrase(count: Int) -> String {
        switch count {
        case ...0: return "Not used yet"
        case 1: return "Used on 1 item"
        default: return "Used on \(count) items"
        }
    }

    /// Deterministic, stable row identifier derived from the tag id (lowercased, matching the
    /// backend's id casing), so a UITest can target a specific row rather than a list index.
    static func rowIdentifier(for id: UUID) -> String {
        "tagRow_\(id.lowercaseUUIDString)"
    }

    // **`deleteConfirmMessage` lived here and is GONE (`F-C4-TagsRecentlyDeleted`, E's call
    // 2026-09-22).** It read *"Delete “x”? It's used on 12 items, and this can't be undone."* —
    // and the last clause stopped being true when a tag delete became a 30-day stamp. E was
    // offered a rewritten alert and chose to drop the confirm outright, the same answer they gave
    // for tasks and captures the same day: `alerts.md › Best practices` only asks for an alert on
    // an uncommon destructive action *"that they can't undo"*.
    //
    // What the string carried and the capsule cannot is the USAGE COUNT — how many items the
    // delete touches — visible only before the tap. That is the named cost of E's choice; the
    // count is still on the row and on this screen, one glance above the button.

    /// The rename-clash alert title — names the conflicting tag.
    static func mergeAlertTitle(conflictingName: String) -> String {
        "“\(conflictingName)” already exists"
    }

    /// The rename-clash alert body, naming the survivor and its usage count.
    static func mergeAlertMessage(survivorName: String, survivorUsageCount: Int) -> String {
        let clause: String
        switch survivorUsageCount {
        case ...0: clause = "“\(survivorName)” isn't used yet."
        case 1: clause = "“\(survivorName)” is used on 1 item."
        default: clause = "“\(survivorName)” is used on \(survivorUsageCount) items."
        }
        return "\(clause) Merge this tag into it? This can't be undone."
    }
}
