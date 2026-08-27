//
//  ArrivalNudgeContent.swift
//  ADHD LifeOS
//

import Foundation

/// What a background wake can know without a network: each nudging place's display name and its
/// open At-Place task titles, refreshed whenever the app holds both lists (every registration
/// replan does). A crossing relaunches the app with seconds of runtime and no guaranteed
/// connectivity — a cold Firestore fetch there is a nudge that mostly doesn't fire.
///
/// Slightly stale on purpose: a task closed elsewhere lingers until the next replan, which is
/// the honest trade against a nudge that needs the network to exist.
struct AtPlaceSnapshot: Codable, Equatable {
    struct PlaceEntry: Codable, Equatable {
        let placeId: UUID
        let displayName: String
        /// Most urgent first — the order the notification body quotes them in.
        let openTaskTitles: [String]
    }

    let entries: [PlaceEntry]

    static func build(places: [Place], tasks: [TaskItem]) -> AtPlaceSnapshot {
        AtPlaceSnapshot(entries: places.map { place in
            PlaceEntry(
                placeId: place.id,
                displayName: place.emoji.map { "\(place.name) \($0)" } ?? place.name,
                openTaskTitles: tasks
                    .filter { $0.status == .open && $0.atPlaceId == place.id }
                    .sorted {
                        ($0.priority.rawValue, $0.title.localizedLowercase)
                            < ($1.priority.rawValue, $1.title.localizedLowercase)
                    }
                    .map(\.title)
            )
        })
    }
}

/// The nudge's words — or `nil`, which means DO NOT FIRE.
///
/// The nil cases carry variation A's whole restraint contract: an unknown place, a place with
/// nothing open, a missing snapshot — all silence. An empty nudge ("You're at Tesco" with
/// nothing to do there) is exactly how someone learns to swipe these away unread.
enum ArrivalNudgeContent {
    /// A notification is a glance, not a screen — quote at most this many titles.
    static let maximumQuotedTitles = 2

    static func notification(
        for event: PlaceTriggerEvent, snapshot: AtPlaceSnapshot?
    ) -> (title: String, body: String)? {
        guard let entry = snapshot?.entries.first(where: { $0.placeId == event.placeId }),
              !entry.openTaskTitles.isEmpty else { return nil }
        switch event.kind {
        case .arrival:
            return (title: "You're at \(entry.displayName)", body: arrivalBody(for: entry))
        case .departure:
            return (title: "Leaving \(entry.displayName)", body: departureBody(for: entry))
        }
    }

    private static func arrivalBody(for entry: AtPlaceSnapshot.PlaceEntry) -> String {
        let count = entry.openTaskTitles.count
        let lead = count == 1 ? "1 thing lives here" : "\(count) things live here"
        var quoted = entry.openTaskTitles.prefix(maximumQuotedTitles).joined(separator: " · ")
        if count > maximumQuotedTitles {
            quoted += " · +\(count - maximumQuotedTitles) more"
        }
        return "\(lead) — \(quoted)"
    }

    private static func departureBody(for entry: AtPlaceSnapshot.PlaceEntry) -> String {
        if entry.openTaskTitles.count == 1, let only = entry.openTaskTitles.first {
            return "\u{201C}\(only)\u{201D} is still open here."
        }
        return "\(entry.openTaskTitles.count) things are still open here."
    }
}
