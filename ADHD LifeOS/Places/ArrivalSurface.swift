//
//  ArrivalSurface.swift
//  ADHD LifeOS
//

import Foundation

/// The Home arrival card's content (block 4c, variation B): what opening the app AT a named
/// place should surface.
///
/// The rule that keeps it honest, pinned by tests: NO card unless there is something to DO here.
/// Being at a place with nothing open for it is ambient truth, and ambient truth on Today — the
/// one screen that must stay scannable — is noise. The empty case never renders, the same
/// principle as the notification that never fires.
///
/// "Here" is EVERY place the fix fell inside, not the single tightest one (2026-09-08). E's real
/// home holds three saved places with the floor radius, centred metres apart, and only one of
/// them ever has tasks; resolving to one place made the card a coin flip per fix, and a pull
/// re-tossed the coin. The first containing place with something open wins, tightest first.
struct ArrivalSurface: Equatable {
    let place: Place
    /// Open at-place tasks, most urgent first.
    let tasks: [TaskItem]

    static func make(currentPlace: Place?, tasks: [TaskItem]) -> ArrivalSurface? {
        make(currentPlaces: currentPlace.map { [$0] } ?? [], tasks: tasks)
    }

    /// `currentPlaces` in the resolver's order — tightest first — so two containing places that
    /// both have work resolve to the more specific one.
    static func make(currentPlaces: [Place], tasks: [TaskItem]) -> ArrivalSurface? {
        for place in currentPlaces {
            let open = openTasks(at: place, in: tasks)
            if !open.isEmpty { return ArrivalSurface(place: place, tasks: open) }
        }
        return nil
    }

    /// What a refresh does to the card it already has: replace it only when the fix positively
    /// says otherwise. No fix — a timeout, a request already in flight, airplane mode — keeps the
    /// previous card re-checked against the fresh tasks (its work may have closed since, and new
    /// work may have appeared); a fix inside no place, or inside another, replaces it honestly;
    /// nothing to be at clears it, so a card never outlives the toggle or the permission.
    static func refreshed(previous: ArrivalSurface?, fix: CurrentPlaceFix, tasks: [TaskItem]) -> ArrivalSurface? {
        switch fix {
        case .off:
            return nil
        case .noFix:
            return previous.flatMap { make(currentPlaces: [$0.place], tasks: tasks) }
        case .inside(let places):
            return make(currentPlaces: places, tasks: tasks)
        }
    }

    private static func openTasks(at place: Place, in tasks: [TaskItem]) -> [TaskItem] {
        tasks
            .filter { $0.status == .open && $0.atPlaceId == place.id }
            .sorted {
                ($0.priority.rawValue, $0.title.localizedLowercase)
                    < ($1.priority.rawValue, $1.title.localizedLowercase)
            }
    }

    var headline: String {
        let name = place.emoji.map { "\(place.name) \($0)" } ?? place.name
        return "You're at \(name)"
    }

    var countLine: String {
        tasks.count == 1 ? "1 thing lives here" : "\(tasks.count) things live here"
    }
}

/// What a "where am I" resolution KNOWS, kept apart from what it found — the arrival card treats
/// "don't know" and "nowhere" differently, and a single optional could not.
enum CurrentPlaceFix: Equatable {
    /// Nothing to be at: the toggle is off, permission is missing, or no place is saved.
    case off
    /// A fix was wanted and did not arrive (or the places could not be fetched).
    case noFix
    /// A fix arrived; the places it fell inside, tightest first. Empty means "inside none".
    case inside([Place])
}

/// The production "which named places am I standing in" for the arrival card. One foreground fix
/// on the When In Use grant — no fences, no Always, which is what makes variation B the gentlest
/// of the three surfacings.
@MainActor
enum CurrentPlaceResolution {
    static func current(
        places: PlacesClientAdapting = FirebasePlacesClientAdapter(),
        isEnabled: () -> Bool = { AppFeedback.arrivalNudgesEnabled() },
        provider: LocationFixProviding = CoreLocationFixProvider.shared
    ) async -> CurrentPlaceFix {
        guard isEnabled() else { return .off }
        guard provider.authorizationState.allowsTagging else { return .off }
        // A failed fetch is "don't know", never "nowhere".
        guard let known = try? await places.fetchPlaces() else { return .noFix }
        guard !known.isEmpty else { return .off }
        guard let coordinate = await provider.currentCoordinate() else { return .noFix }
        return .inside(PlaceResolution.places(containing: coordinate, in: known))
    }
}
