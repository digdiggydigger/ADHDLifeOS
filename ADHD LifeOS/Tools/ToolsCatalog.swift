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
/// The page is also deliberately **sparse**: E wants Routines to have an obvious home when it
/// arrives, and a page already full of cards would not offer one. `ToolsCatalogTests` pins the
/// count so a third card is a decision rather than a drift.
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

    /// The cards to draw.
    ///
    /// **`placesSupported` is the iOS 16 floor, not a preference.** `PlacesListView` and every
    /// type under it are `@available(iOS 17.0, *)`, and this app's deployment target is 16.0, so
    /// on a 16.x phone Places does not exist to push to. The caller answers with a real
    /// `#available` check; passing a constant `true` here would compile perfectly on the 26.5
    /// simulator every build in this project runs against and ship a dead card to the floor.
    ///
    /// Places leads when it is there: it is the door that MOVED, with no other way in, while Life
    /// Areas still has its Settings row.
    static func available(placesSupported: Bool) -> [Entry] {
        placesSupported ? [places, lifeAreas] : [lifeAreas]
    }
}
