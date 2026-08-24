//
//  MomentumPreferences.swift
//  ADHD LifeOS
//
//  "What counts as momentum" (Concept C, blocks M2/M7/M9): the preferences the scoreboard
//  honours — the daily goal behind the closure ring, whether streaks are counted at all, and the
//  two counting toggles the concept asked for, each shipped only once its event stamp existed
//  (captures' `clearedAt` in M7, nudges' `last_fired_at` in M9). Shipping a switch without its
//  data would have been a lie in a Form row.
//

import Foundation

struct MomentumPreferences: Codable, Equatable, Sendable {
    /// The Stepper's bounds, and `normalized()`'s clamp. Twelve is a ceiling, not a suggestion —
    /// an ADHD daily goal that needs thirteen slots has stopped being a goal.
    static let goalRange = 1...12

    static let `default` = MomentumPreferences(
        dailyGoal: 5, showStreaks: true, countClearedCaptures: false, countNudges: false
    )

    var dailyGoal: Int
    /// Off keeps every number but stops counting consecutive days — the scoreboard shows the
    /// "still open" counterweight instead of a streak.
    var showStreaks: Bool
    /// M7: whether captures cleared today (seen, promoted or journaled — anything that stamps
    /// `clearedAt`) count toward the closure ring alongside closed tasks.
    var countClearedCaptures: Bool
    /// M9: whether nudges dismissed today count toward the ring too. `last_fired_at` doubles as
    /// the done-event stamp — only the Dismiss tap writes it, and a schedule fires at most once
    /// a day — so no new backend field was needed (E's call, 2026-08-24).
    var countNudges: Bool

    /// Every read path passes through this, so no writer — Stepper, old build, bad migration —
    /// can hand the ring a goal it would divide by zero on.
    func normalized() -> MomentumPreferences {
        MomentumPreferences(
            dailyGoal: min(max(dailyGoal, Self.goalRange.lowerBound), Self.goalRange.upperBound),
            showStreaks: showStreaks,
            countClearedCaptures: countClearedCaptures,
            countNudges: countNudges
        )
    }

    /// Hand-written so preferences stored by earlier builds (M2 predates `countClearedCaptures`,
    /// M7 predates `countNudges`) decode with the user's choices INTACT rather than resetting
    /// to defaults.
    init(dailyGoal: Int, showStreaks: Bool, countClearedCaptures: Bool = false, countNudges: Bool = false) {
        self.dailyGoal = dailyGoal
        self.showStreaks = showStreaks
        self.countClearedCaptures = countClearedCaptures
        self.countNudges = countNudges
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dailyGoal = try container.decode(Int.self, forKey: .dailyGoal)
        showStreaks = try container.decode(Bool.self, forKey: .showStreaks)
        countClearedCaptures = try container.decodeIfPresent(Bool.self, forKey: .countClearedCaptures) ?? false
        countNudges = try container.decodeIfPresent(Bool.self, forKey: .countNudges) ?? false
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
