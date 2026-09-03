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
        /// E's own words for arriving here — see `Place.arrivalMessage` for how a set message
        /// changes the firing rule. `var` optional so pre-message snapshots decode as nil.
        var arrivalMessage: String?
        /// And for leaving. Same contract, separate words — neither ever speaks on the other's
        /// crossing.
        var departureMessage: String?
        /// What this place DOES on a crossing (the Place Actions arc) — carried into the
        /// snapshot for the same reason the messages are: a background wake can't count on a
        /// network, so execution reads config from here, never from a cold fetch. Optional so
        /// every pre-actions snapshot on a device decodes quietly.
        var actions: [PlaceAction]?
        /// The place's centre, so an auto-run journal line or capture can stamp WHERE it
        /// happened without requesting a fix on a background wake — the crossing itself is the
        /// evidence E is here. Optional for the same pre-actions-snapshot reason.
        var latitude: Double?
        var longitude: Double?
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
                    .map(\.title),
                arrivalMessage: place.arrivalMessage,
                departureMessage: place.departureMessage,
                actions: place.actions,
                latitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude
            )
        })
    }
}

/// The nudge's words — or `nil`, which means DO NOT FIRE.
///
/// The nil cases carry variation A's whole restraint contract: an unknown place, a missing
/// snapshot, or a place with nothing open AND no words of E's own for this crossing — all
/// silence. An empty nudge ("You're at Tesco" with nothing to do there) is exactly how someone
/// learns to swipe these away unread.
enum ArrivalNudgeContent {
    /// A notification is a glance, not a screen — quote at most this many titles.
    static let maximumQuotedTitles = 2

    static func notification(
        for event: PlaceTriggerEvent, snapshot: AtPlaceSnapshot?,
        executedLines: [String] = [], absorbedByRoutine: Bool = false
    ) -> (title: String, body: String)? {
        guard let entry = snapshot?.entries.first(where: { $0.placeId == event.placeId }) else {
            return nil
        }
        let base: (title: String, body: String)?
        switch event.kind {
        case .arrival:
            base = compose(
                title: "You're at \(entry.displayName)",
                message: absorbedByRoutine ? nil : entry.arrivalMessage,
                tasks: entry.openTaskTitles.isEmpty ? nil : (
                    alone: taskLine(for: entry, joiner: " — "),
                    afterMessage: taskLine(for: entry, joiner: ": ")
                )
            )
        case .departure:
            base = compose(
                title: "Leaving \(entry.displayName)",
                message: absorbedByRoutine ? nil : entry.departureMessage,
                tasks: entry.openTaskTitles.isEmpty ? nil : (
                    alone: departureBody(for: entry), afterMessage: departureBody(for: entry)
                )
            )
        }
        // The Place Actions extension of the firing rule: something RAN, so the crossing has
        // content and reports it — the same reasoning that lets a custom message fire alone.
        // With nothing run, the original gate stands untouched.
        // The fifth path (F-Routines-2): a routine notification for this crossing already
        // carries the message AND the report — this nudge composes tasks alone, so one
        // crossing never interrupts twice with the same words.
        guard !executedLines.isEmpty, !absorbedByRoutine else { return base }
        let report = executedLines.joined(separator: " · ")
        guard let base else {
            let title = event.kind == .arrival
                ? "You're at \(entry.displayName)" : "Leaving \(entry.displayName)"
            return (title: title, body: report)
        }
        return (title: base.title, body: "\(base.body) · \(report)")
    }

    /// The one firing rule both crossings obey (E's 2026-08-28 request extended it to departure):
    /// a custom message fires on its own — E wrote it, so the nudge is never empty — and the
    /// empty-never-fires gate applies only to places without one. Each crossing reads only its
    /// OWN message; an arrival message never speaks on the way out.
    ///
    /// `tasks` carries two phrasings because arrival's task line changes when a message leads it
    /// — "… — 1 thing lives here — X" reads wrong with the same joiner used twice. `nil` means
    /// nothing is open here, which is the half of the gate that predates the messages.
    private static func compose(
        title: String, message: String?, tasks: (alone: String, afterMessage: String)?
    ) -> (title: String, body: String)? {
        switch (message, tasks) {
        case (nil, nil):
            return nil
        case (let message?, nil):
            return (title: title, body: message)
        case (let message?, let tasks?):
            return (title: title, body: "\(message) — \(tasks.afterMessage)")
        case (nil, let tasks?):
            return (title: title, body: tasks.alone)
        }
    }

    private static func taskLine(for entry: AtPlaceSnapshot.PlaceEntry, joiner: String) -> String {
        let count = entry.openTaskTitles.count
        let lead = count == 1 ? "1 thing lives here" : "\(count) things live here"
        var quoted = entry.openTaskTitles.prefix(maximumQuotedTitles).joined(separator: " · ")
        if count > maximumQuotedTitles {
            quoted += " · +\(count - maximumQuotedTitles) more"
        }
        return "\(lead)\(joiner)\(quoted)"
    }

    private static func departureBody(for entry: AtPlaceSnapshot.PlaceEntry) -> String {
        if entry.openTaskTitles.count == 1, let only = entry.openTaskTitles.first {
            return "\u{201C}\(only)\u{201D} is still open here."
        }
        return "\(entry.openTaskTitles.count) things are still open here."
    }
}
