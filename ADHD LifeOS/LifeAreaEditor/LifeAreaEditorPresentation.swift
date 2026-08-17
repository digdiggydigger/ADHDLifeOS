//
//  LifeAreaEditorPresentation.swift
//  ADHD LifeOS
//

import Foundation

/// Pure, unit-testable presentation logic for the Life Area editor. No SwiftUI import: this decides
/// *what strings/identifiers* rows and alerts show, never *how* they are laid out.
enum LifeAreaEditorPresentation {
    /// Split areas into the two list sections. Both are sorted by `sortOrder` (the order the Home
    /// grid uses); active first, archived separately. Pure so the partition is unit-testable and the
    /// view never re-derives it.
    static func partition(
        _ areas: [EditableLifeArea]
    ) -> (active: [EditableLifeArea], archived: [EditableLifeArea]) {
        let sorted = areas.sorted { $0.sortOrder < $1.sortOrder }
        return (sorted.filter { !$0.archived }, sorted.filter { $0.archived })
    }

    /// Deterministic, stable row identifier derived from the area id (lowercased, matching the
    /// backend's id casing), so a UITest can target a specific row rather than a list index.
    static func rowIdentifier(for id: UUID) -> String {
        "lifeAreaRow_\(id.lowercaseUUIDString)"
    }

    /// The text badge on an archived row. Archived-ness must be carried in **text**, never by colour
    /// alone (§4), so VoiceOver and colour-blind users both get it.
    static let archivedBadge = "Archived"

    // MARK: - Create-conflict alert (two branches)

    /// Title for the create-name-taken alert — same for both branches.
    static func createConflictTitle(name: String) -> String {
        "“\(name)” already exists"
    }

    /// Body when the taken name belongs to an **archived** area: the alert will offer
    /// "Unarchive it instead?".
    static func createConflictArchivedMessage(name: String) -> String {
        "You already have an archived life area called “\(name)”. Unarchive it instead of making a new one?"
    }

    /// Body when the taken name belongs to a **live** area: Cancel only, nothing to unarchive.
    static func createConflictLiveMessage(name: String) -> String {
        "You already have a life area called “\(name)”. Pick a different name."
    }

    // MARK: - Rename-conflict alert (always Cancel-only)

    /// Title for the rename-name-taken alert.
    static func renameConflictTitle(name: String) -> String {
        "“\(name)” is taken"
    }

    /// Body for a rename clash. Cancel-only in **both** cases: unarchiving the other area cannot
    /// resolve a rename, so offering it would be a button that can't do what it says. When the holder
    /// is archived we still say so, so the state is explicable rather than a mystery.
    static func renameConflictMessage(name: String, archived: Bool) -> String {
        if archived {
            return "That name is taken by an archived life area called “\(name)”. Choose a different name."
        }
        return "You already have a life area called “\(name)”. Choose a different name."
    }
}
