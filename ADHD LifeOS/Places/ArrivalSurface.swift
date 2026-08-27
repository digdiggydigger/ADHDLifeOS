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
struct ArrivalSurface: Equatable {
    let place: Place
    /// Open at-place tasks, most urgent first.
    let tasks: [TaskItem]

    static func make(currentPlace: Place?, tasks: [TaskItem]) -> ArrivalSurface? {
        guard let currentPlace else { return nil }
        let open = tasks
            .filter { $0.status == .open && $0.atPlaceId == currentPlace.id }
            .sorted {
                ($0.priority.rawValue, $0.title.localizedLowercase)
                    < ($1.priority.rawValue, $1.title.localizedLowercase)
            }
        guard !open.isEmpty else { return nil }
        return ArrivalSurface(place: currentPlace, tasks: open)
    }

    var headline: String {
        let name = place.emoji.map { "\(place.name) \($0)" } ?? place.name
        return "You're at \(name)"
    }

    var countLine: String {
        tasks.count == 1 ? "1 thing lives here" : "\(tasks.count) things live here"
    }
}

/// The production "which named place am I standing in" for the arrival card. One foreground fix
/// on the When In Use grant — no fences, no Always, which is what makes variation B the gentlest
/// of the three surfacings.
@MainActor
enum CurrentPlaceResolution {
    static func current(
        places: PlacesClientAdapting = FirebasePlacesClientAdapter(),
        isEnabled: () -> Bool = { AppFeedback.arrivalNudgesEnabled() }
    ) async -> Place? {
        guard isEnabled() else { return nil }
        guard CoreLocationFixProvider.shared.authorizationState.allowsTagging else { return nil }
        guard let known = try? await places.fetchPlaces(), !known.isEmpty else { return nil }
        guard let coordinate = await CoreLocationFixProvider.shared.currentCoordinate() else { return nil }
        return PlaceResolution.place(containing: coordinate, in: known)
    }
}
