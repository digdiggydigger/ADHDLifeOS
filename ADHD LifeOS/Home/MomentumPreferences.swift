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

    /// The focus-goal stepper's bounds (minutes per day the analytics and widget ring divide by).
    static let focusGoalRange = 10...120
    /// The default-sprint stepper's bounds, in minutes. The floor mirrors the shortest sprint the
    /// planner treats as real; the ceiling is the config's own two-hour cap.
    static let sprintMinutesRange = 5...120

    static let `default` = MomentumPreferences(
        dailyGoal: 5, showStreaks: true, countClearedCaptures: false, countNudges: false,
        showCharts: true
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
    /// Charts (`chartsOn` in the concept): the weekly bars on Today and Tasks. Display-only, so
    /// it ships at the concept's own default (on) — unlike the counting toggles, an enabled
    /// chart cannot misstate anything.
    var showCharts: Bool
    /// Minutes-per-day the focus analytics and the Home Screen widget's ring measure against
    /// (E's 2026-08-25 Settings audit) — ships at the old hardcoded 30.
    var focusDailyGoalMinutes: Int
    /// The sprint length the one-tap start uses for a task with no stored config — ships at the
    /// old `FocusNudgeCadence.standardDurationSeconds` (15 minutes). A task's own config always
    /// wins; this is only the starting point.
    var defaultSprintMinutes: Int
    /// The app's tactile confirmations, globally. Off silences every generator; nothing else
    /// changes.
    var hapticsEnabled: Bool
    /// Whether the notifications THIS APP schedules carry sound. System notification settings
    /// are untouched — this only decides what the app asks for.
    var soundEnabled: Bool
    /// Whether captures, journal entries, closed tasks and sprints record WHERE they happened.
    /// Consulted at stamp time, so switching it off silences the very next one with no relaunch.
    /// Location permission is a separate, stricter gate — this only decides whether the app asks
    /// for a fix at all.
    var locationTaggingEnabled: Bool
    /// The master switch over every place's arrival/departure nudges (block 4b). One flip
    /// silences every fence at once; the per-place toggles are kept, so turning it back on
    /// restores exactly what was set up.
    var arrivalNudgesEnabled: Bool

    /// Every read path passes through this, so no writer — Stepper, old build, bad migration —
    /// can hand the ring a goal it would divide by zero on.
    ///
    /// Every field must be passed through EXPLICITLY: an omitted one silently resets to its init
    /// default on every read AND write — which is exactly how `locationTaggingEnabled` spent a
    /// session unable to stick off (found 2026-08-27, pinned in `MomentumPreferencesTests`).
    func normalized() -> MomentumPreferences {
        MomentumPreferences(
            dailyGoal: min(max(dailyGoal, Self.goalRange.lowerBound), Self.goalRange.upperBound),
            showStreaks: showStreaks,
            countClearedCaptures: countClearedCaptures,
            countNudges: countNudges,
            showCharts: showCharts,
            focusDailyGoalMinutes: min(
                max(focusDailyGoalMinutes, Self.focusGoalRange.lowerBound), Self.focusGoalRange.upperBound
            ),
            defaultSprintMinutes: min(
                max(defaultSprintMinutes, Self.sprintMinutesRange.lowerBound), Self.sprintMinutesRange.upperBound
            ),
            hapticsEnabled: hapticsEnabled,
            soundEnabled: soundEnabled,
            locationTaggingEnabled: locationTaggingEnabled,
            arrivalNudgesEnabled: arrivalNudgesEnabled
        )
    }

    /// Hand-written so preferences stored by earlier builds (M2 predates `countClearedCaptures`,
    /// M7 predates `countNudges`) decode with the user's choices INTACT rather than resetting
    /// to defaults.
    init(
        dailyGoal: Int,
        showStreaks: Bool,
        countClearedCaptures: Bool = false,
        countNudges: Bool = false,
        showCharts: Bool = true,
        focusDailyGoalMinutes: Int = 30,
        defaultSprintMinutes: Int = 15,
        hapticsEnabled: Bool = true,
        soundEnabled: Bool = true,
        locationTaggingEnabled: Bool = true,
        arrivalNudgesEnabled: Bool = true
    ) {
        self.dailyGoal = dailyGoal
        self.showStreaks = showStreaks
        self.countClearedCaptures = countClearedCaptures
        self.countNudges = countNudges
        self.showCharts = showCharts
        self.focusDailyGoalMinutes = focusDailyGoalMinutes
        self.defaultSprintMinutes = defaultSprintMinutes
        self.hapticsEnabled = hapticsEnabled
        self.soundEnabled = soundEnabled
        self.locationTaggingEnabled = locationTaggingEnabled
        self.arrivalNudgesEnabled = arrivalNudgesEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dailyGoal = try container.decode(Int.self, forKey: .dailyGoal)
        showStreaks = try container.decode(Bool.self, forKey: .showStreaks)
        countClearedCaptures = try container.decodeIfPresent(Bool.self, forKey: .countClearedCaptures) ?? false
        countNudges = try container.decodeIfPresent(Bool.self, forKey: .countNudges) ?? false
        showCharts = try container.decodeIfPresent(Bool.self, forKey: .showCharts) ?? true
        focusDailyGoalMinutes = try container.decodeIfPresent(Int.self, forKey: .focusDailyGoalMinutes) ?? 30
        defaultSprintMinutes = try container.decodeIfPresent(Int.self, forKey: .defaultSprintMinutes) ?? 15
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        locationTaggingEnabled = try container
            .decodeIfPresent(Bool.self, forKey: .locationTaggingEnabled) ?? true
        arrivalNudgesEnabled = try container
            .decodeIfPresent(Bool.self, forKey: .arrivalNudgesEnabled) ?? true
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
