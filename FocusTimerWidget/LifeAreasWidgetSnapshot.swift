//
//  LifeAreasWidgetSnapshot.swift
//  FocusTimerWidget
//

import Foundation

/// The Life Areas medium widget's payload (E's 2026-08-25 widgets note) — the same two-process
/// contract discipline as `FocusWidgetSnapshot`: the app resolves everything (names, emoji, the
/// palette family INCLUDING the F-V3-AreaColour override) and publishes into the shared App Group;
/// the widget only ever decodes. Versioned, and a payload stamped with a version this build
/// doesn't know is discarded rather than half-decoded.
///
/// Lives in the widget folder and is shared INTO the app target via the project's
/// `membershipExceptions` mechanism, so both sides compile literally the same source.
nonisolated struct LifeAreasWidgetSnapshot: Codable, Equatable, Sendable {
    static let currentVersion = 1

    nonisolated struct Area: Codable, Equatable, Sendable {
        let name: String
        /// The area's emoji (stored in `LifeArea.colour`).
        let emoji: String
        /// The resolved `AreaPalette` asset stem ("AreaWork") — resolved app-side, where the
        /// stored override and the emoji mapping live; the widget just holds same-named
        /// colorsets and appends "Tint" for the wash.
        let paletteAssetStem: String
        let openCount: Int
    }

    let version: Int
    let generatedAt: Date
    /// Display order, already capped to what the medium grid can seat.
    let areas: [Area]

    init(generatedAt: Date, areas: [Area]) {
        self.version = Self.currentVersion
        self.generatedAt = generatedAt
        self.areas = areas
    }

    /// The gallery / fresh-install state: real structure, no fabricated areas.
    static let placeholder = LifeAreasWidgetSnapshot(generatedAt: Date(timeIntervalSince1970: 0), areas: [])
}

nonisolated struct LifeAreasWidgetStore {
    /// The widget kind, shared so the app can reload exactly this timeline.
    static let widgetKind = "LifeAreasWidget"
    static let snapshotKey = "lifeareas.widget.snapshot"

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: FocusWidgetSnapshotStore.appGroupIdentifier)) {
        self.defaults = defaults
    }

    func write(_ snapshot: LifeAreasWidgetSnapshot) {
        guard let defaults, let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.snapshotKey)
    }

    func read() -> LifeAreasWidgetSnapshot? {
        guard
            let data = defaults?.data(forKey: Self.snapshotKey),
            let snapshot = try? JSONDecoder().decode(LifeAreasWidgetSnapshot.self, from: data),
            snapshot.version == LifeAreasWidgetSnapshot.currentVersion
        else { return nil }
        return snapshot
    }

    /// The session-end sweep's half of this store (E's fold call, 2026-09-06) — same reasoning as
    /// `FocusWidgetSnapshotStore.clear()`: the widget renders whatever the App Group holds.
    func clear() {
        defaults?.removeObject(forKey: Self.snapshotKey)
    }
}
