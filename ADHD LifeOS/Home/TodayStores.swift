//
//  TodayStores.swift
//  ADHD LifeOS
//
//  `F-E3-OneCardToday`: the pin toggle and "Not this one", both device-local and keyed PER ACCOUNT
//  — `NudgeFirstRunMarker`'s lesson, where a device-wide key leaked one account's answer into the
//  next account on the same phone. Local rather than Firestore because both are presentation
//  choices about THIS screen, like `lifeAreasCollapsed` was; a pin that syncs across devices would
//  be a `pinned_task_id` on the profile document, and that is a decision for E, not a default.
//

import Foundation

/// The one task the user pinned to Today's card (round 5a: *"a pin toggle (44pt) in the corner"*).
enum TodayPinStore {
    static func key(for uid: String) -> String { "today.pinnedTaskId.\(uid)" }

    static func pinnedTaskId(uid: String, in defaults: UserDefaults = .standard) -> UUID? {
        defaults.string(forKey: key(for: uid)).flatMap(UUID.init(uuidString:))
    }

    /// One pin at a time: pinning another task replaces it.
    static func pin(_ id: UUID, uid: String, in defaults: UserDefaults = .standard) {
        defaults.set(id.uuidString, forKey: key(for: uid))
    }

    static func unpin(uid: String, in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key(for: uid))
    }
}

/// Tasks the user answered "Not this one" to, TODAY. Round 5b: *"Back in the list, not re-suggested
/// today... the card won't offer it again until tomorrow."*
///
/// The set is stored with the day it belongs to, and a read on any other day returns nothing — so
/// the reset at midnight needs no timer, no launch hook and no cleanup.
enum TodaySkipStore {
    static func key(for uid: String) -> String { "today.skippedTaskIds.\(uid)" }

    static func skippedTaskIds(
        uid: String,
        asOf now: Date = .now,
        calendar: Calendar = .current,
        in defaults: UserDefaults = .standard
    ) -> Set<UUID> {
        guard let stored = defaults.dictionary(forKey: key(for: uid)),
              stored[dayField] as? String == dayKey(for: now, calendar: calendar),
              let ids = stored[idsField] as? [String]
        else { return [] }
        return Set(ids.compactMap(UUID.init(uuidString:)))
    }

    static func skip(
        _ id: UUID,
        uid: String,
        asOf now: Date = .now,
        calendar: Calendar = .current,
        in defaults: UserDefaults = .standard
    ) {
        // Reading through the day check first is what drops yesterday's set on the first skip of
        // a new day.
        var ids = skippedTaskIds(uid: uid, asOf: now, calendar: calendar, in: defaults)
        ids.insert(id)
        defaults.set(
            [dayField: dayKey(for: now, calendar: calendar), idsField: ids.map(\.uuidString).sorted()],
            forKey: key(for: uid)
        )
    }

    private static let dayField = "day"
    private static let idsField = "ids"

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }
}
