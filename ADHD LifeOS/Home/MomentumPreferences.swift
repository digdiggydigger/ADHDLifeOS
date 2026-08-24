//
//  MomentumPreferences.swift
//  ADHD LifeOS
//
//  "What counts as momentum" (Concept C, block M2): the two preferences the scoreboard actually
//  honours — the daily goal behind the closure ring, and whether streaks are counted at all.
//  The concept's "count cleared captures / count nudges" toggles are deliberately absent:
//  nothing stamps when a capture clears or a nudge is marked done, so the ring could not
//  honestly count either yet. Shipping the switch without the data would be a lie in a Form row.
//

import Foundation

struct MomentumPreferences: Codable, Equatable, Sendable {
    /// The Stepper's bounds, and `normalized()`'s clamp. Twelve is a ceiling, not a suggestion —
    /// an ADHD daily goal that needs thirteen slots has stopped being a goal.
    static let goalRange = 1...12

    static let `default` = MomentumPreferences(dailyGoal: 5, showStreaks: true)

    var dailyGoal: Int
    /// Off keeps every number but stops counting consecutive days — the scoreboard shows the
    /// "still open" counterweight instead of a streak.
    var showStreaks: Bool

    /// Every read path passes through this, so no writer — Stepper, old build, bad migration —
    /// can hand the ring a goal it would divide by zero on.
    func normalized() -> MomentumPreferences {
        MomentumPreferences(
            dailyGoal: min(max(dailyGoal, Self.goalRange.lowerBound), Self.goalRange.upperBound),
            showStreaks: showStreaks
        )
    }
}

/// Seam so Settings and Home share one source of truth without touching real UserDefaults in
/// tests. Not `Sendable` for the same reason as `DailySummaryStoring` beside it: read and written
/// synchronously on the main actor, never across a suspension.
protocol MomentumPreferencesStoring {
    func read() -> MomentumPreferences
    func write(_ preferences: MomentumPreferences)
}

/// App-local UserDefaults, the `UserDefaultsDailySummaryStore` arrangement: every failure path —
/// unavailable defaults, corrupt data — degrades to the defaults instead of trapping.
struct UserDefaultsMomentumPreferencesStore: MomentumPreferencesStoring {
    static let preferencesKey = "settings.momentum.preferences"

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
    }

    func read() -> MomentumPreferences {
        guard
            let data = defaults?.data(forKey: Self.preferencesKey),
            let preferences = try? JSONDecoder().decode(MomentumPreferences.self, from: data)
        else { return .default }
        return preferences.normalized()
    }

    func write(_ preferences: MomentumPreferences) {
        guard let defaults, let data = try? JSONEncoder().encode(preferences.normalized()) else { return }
        defaults.set(data, forKey: Self.preferencesKey)
    }
}
