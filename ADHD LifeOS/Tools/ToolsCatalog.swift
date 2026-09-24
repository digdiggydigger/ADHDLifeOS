//
//  ToolsCatalog.swift
//  ADHD LifeOS
//

import Foundation

/// What the Tools tab holds, as a pure list.
///
/// Kept out of `ToolsView`'s body for the reason every presentation type in this app is: view
/// bodies here are ~0% covered by design, so a rule left inside one is a rule nothing checks.
/// `AppTabBarPresentation` and `PlaceAppPickerPresentation` are the house pattern.
///
/// **Two entries, deliberately, and the asymmetry between them is E's call (2026-09-02).**
/// Places moves out of Settings entirely and is reachable ONLY from here; Life Areas gains a door
/// here and **keeps** the one in Settings. That is knowingly the opposite of the de-duplication
/// the Captures rethink spent two blocks on — Life Areas is genuinely both a setting and a tool —
/// so it is not a bug to be tidied.
///
/// The page was left deliberately **sparse** so Routines would have an obvious home when it
/// arrived. It has now arrived (F-Routines-B) — as a headed SECTION below these cards, which is
/// E's own word for it, so it is `ToolsView`'s concern and not an entry here. `ToolsCatalogTests`
/// still pins this count, so a third CARD is a decision rather than a drift.
enum ToolsCatalog {

    /// The doors this page can open. `ToolsView` switches on this to build the push, so the case
    /// list and the entry list are held equal by test rather than by discipline.
    enum Destination: String, Hashable, CaseIterable {
        case places
        case lifeAreas
    }

    /// One bento card.
    struct Entry: Identifiable, Equatable {
        let destination: Destination
        let title: String
        let caption: String
        let systemImage: String

        var id: Destination { destination }

        /// Namespaced per card. Per-CARD and never on the container: an identifier on a container
        /// is inherited by its children, which is what made a whole row ambiguous in the Captures
        /// work.
        var accessibilityIdentifier: String { "toolsCard.\(destination.rawValue)" }
    }

    /// Copy carried over verbatim from the Settings rows these replace — the words are already
    /// E's, and a move is a bad moment to also reword.
    private static let places = Entry(
        destination: .places,
        title: "Places",
        caption: "The spots you keep coming back to — home, the office, the gym.",
        systemImage: "mappin.and.ellipse"
    )

    private static let lifeAreas = Entry(
        destination: .lifeAreas,
        title: "Life Areas",
        caption: "Rename, re-emoji, recolour, create, and archive your Home grid.",
        systemImage: "square.grid.2x2"
    )

    /// The cards to draw, Places first: it is the door that MOVED, with no other way in, while
    /// Life Areas still has its Settings row.
    ///
    /// Until `F-Floor18` this was `available(placesSupported:)`, a `Bool` the caller answered with
    /// a real `#available(iOS 17.0, *)` because Places sat above the old floor and the page had
    /// to survive it not existing. At the 18 floor nothing is absent, so the list is a constant.
    static let entries: [Entry] = [places, lifeAreas]
}
