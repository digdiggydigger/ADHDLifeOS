//
//  MomentumPreferences.swift
//  ADHD LifeOS
//
//  "What counts as momentum" (Concept C, blocks M2/M7/M9): the preferences the scoreboard
//  honours — the daily goal behind the closure ring, whether the weekly chain is shown at all, and
//  the two counting toggles the concept asked for, each shipped only once its event stamp existed
//  (captures' `clearedAt` in M7, nudges' `last_fired_at` in M9). Shipping a switch without its
//  data would have been a lie in a Form row.
//
//  `F-E1-WeeklyChain` (E's round 3, *"Preset goals → 'Off until you set one.'"*): both daily goals
//  are OPTIONAL now, `nil` until the user turns one on, and the weekly chain's N joined them.
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

    /// Where each goal's Stepper starts when its toggle is turned on — the values that used to be
    /// the always-on defaults, now only a starting point the user moves from.
    static let dailyGoalStartingValue = 5
    static let focusGoalStartingMinutes = 30

    static let `default` = MomentumPreferences(
        dailyGoal: nil, showStreaks: true, countClearedCaptures: false, countNudges: false,
        showCharts: true
    )

    /// `nil` = no daily close goal (HOME-10: nobody ever chose the old 5). No ring, no percentage,
    /// and no crossing for F7's celebration to fire on, until the user sets one.
    var dailyGoal: Int?
    /// Whether the weekly CHAIN is shown (`F-E1`). The field keeps its old name so no stored
    /// choice resets; it gated a daily streak until E retired that in round 3. Off keeps every
    /// number and drops the chain's gain line ("makes today count") along with the chain.
    var showStreaks: Bool
    /// Round 5b's N: how many active days make a week count toward the chain. 1…7, default 3.
    var weeklyActiveDayGoal: Int
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
    /// Minutes-per-day the focus analytics and the Home Screen widget's bar measure against (E's
    /// 2026-08-25 Settings audit). `nil` = no focus goal (`F-E1`): the bar is not drawn at all.
    var focusDailyGoalMinutes: Int?
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
    /// E's #3 (the CTA celebrations arc): one switch over every FULL-SCREEN celebration — the
    /// confetti a Confirm sets off and the milestones that follow it. On by default, because
    /// playing them is what the app already does. Haptics and the in-place flourishes are outside
    /// it on purpose; they are the feedback a switch like this should never take with it.
    var celebrationsEnabled: Bool
    /// E's F5: one soft chime on those full-screen celebrations, and nothing else. OFF by default —
    /// a sound nobody asked for is the one kind of feedback that cannot be politely ignored. The
    /// player arrives in `F-CTACelebrations-7`; until then the switch stores a choice and nothing
    /// reads it, which is why its Settings footer says so.
    var celebrationSoundsEnabled: Bool

    /// Every read path passes through this, so no writer — Stepper, old build, bad migration —
    /// can hand the ring a goal it would divide by zero on.
    ///
    /// Every field must be passed through EXPLICITLY: an omitted one silently resets to its init
    /// default on every read AND write — which is exactly how `locationTaggingEnabled` spent a
    /// session unable to stick off (found 2026-08-27, pinned in `MomentumPreferencesTests`).
    func normalized() -> MomentumPreferences {
        MomentumPreferences(
            dailyGoal: dailyGoal.map { Self.clamp($0, to: Self.goalRange) },
            showStreaks: showStreaks,
            weeklyActiveDayGoal: Self.clamp(weeklyActiveDayGoal, to: WeeklyActiveChain.goalRange),
            countClearedCaptures: countClearedCaptures,
            countNudges: countNudges,
            showCharts: showCharts,
            focusDailyGoalMinutes: focusDailyGoalMinutes.map { Self.clamp($0, to: Self.focusGoalRange) },
            defaultSprintMinutes: min(
                max(defaultSprintMinutes, Self.sprintMinutesRange.lowerBound), Self.sprintMinutesRange.upperBound
            ),
            hapticsEnabled: hapticsEnabled,
            soundEnabled: soundEnabled,
            locationTaggingEnabled: locationTaggingEnabled,
            arrivalNudgesEnabled: arrivalNudgesEnabled,
            celebrationsEnabled: celebrationsEnabled,
            celebrationSoundsEnabled: celebrationSoundsEnabled
        )
    }

    /// Settings' "Set a daily goal" toggle. On starts the Stepper at the old seed — unless a goal
    /// is already set, which a redundant "on" must never reset; off clears it.
    mutating func setDailyGoalEnabled(_ enabled: Bool) {
        dailyGoal = enabled ? (dailyGoal ?? Self.dailyGoalStartingValue) : nil
    }

    /// Settings' "Set a daily focus goal" toggle — the same contract.
    mutating func setFocusGoalEnabled(_ enabled: Bool) {
        focusDailyGoalMinutes = enabled ? (focusDailyGoalMinutes ?? Self.focusGoalStartingMinutes) : nil
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }

    /// Hand-written so preferences stored by earlier builds (M2 predates `countClearedCaptures`,
    /// M7 predates `countNudges`) decode with the user's choices INTACT rather than resetting
    /// to defaults.
    init(
        dailyGoal: Int?,
        showStreaks: Bool,
        weeklyActiveDayGoal: Int = WeeklyActiveChain.defaultGoal,
        countClearedCaptures: Bool = false,
        countNudges: Bool = false,
        showCharts: Bool = true,
        focusDailyGoalMinutes: Int? = nil,
        defaultSprintMinutes: Int = 15,
        hapticsEnabled: Bool = true,
        soundEnabled: Bool = true,
        locationTaggingEnabled: Bool = true,
        arrivalNudgesEnabled: Bool = true,
        celebrationsEnabled: Bool = true,
        celebrationSoundsEnabled: Bool = false
    ) {
        self.dailyGoal = dailyGoal
        self.showStreaks = showStreaks
        self.weeklyActiveDayGoal = weeklyActiveDayGoal
        self.countClearedCaptures = countClearedCaptures
        self.countNudges = countNudges
        self.showCharts = showCharts
        self.focusDailyGoalMinutes = focusDailyGoalMinutes
        self.defaultSprintMinutes = defaultSprintMinutes
        self.hapticsEnabled = hapticsEnabled
        self.soundEnabled = soundEnabled
        self.locationTaggingEnabled = locationTaggingEnabled
        self.arrivalNudgesEnabled = arrivalNudgesEnabled
        self.celebrationsEnabled = celebrationsEnabled
        self.celebrationSoundsEnabled = celebrationSoundsEnabled
    }

    /// **The goals-off migration (`F-E1`), keyed on the chain's field rather than on the values.**
    /// A document with no `weeklyActiveDayGoal` was written before E1, when 5 and 30 were defaults
    /// nobody chose (HOME-10) — so those two values decode as "no goal", and anything the user
    /// DID move the Stepper to survives. A document WITH the key was written after, when 5 is
    /// exactly what someone who turned the goal on and left the Stepper alone chose; testing the
    /// value alone would erase that choice on the next launch.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let chainGoal = try container.decodeIfPresent(Int.self, forKey: .weeklyActiveDayGoal)
        let storedGoal = try container.decodeIfPresent(Int.self, forKey: .dailyGoal)
        let storedFocusGoal = try container.decodeIfPresent(Int.self, forKey: .focusDailyGoalMinutes)
        if let chainGoal {
            weeklyActiveDayGoal = chainGoal
            dailyGoal = storedGoal
            focusDailyGoalMinutes = storedFocusGoal
        } else {
            weeklyActiveDayGoal = WeeklyActiveChain.defaultGoal
            dailyGoal = storedGoal == Self.dailyGoalStartingValue ? nil : storedGoal
            focusDailyGoalMinutes = storedFocusGoal == Self.focusGoalStartingMinutes ? nil : storedFocusGoal
        }
        showStreaks = try container.decode(Bool.self, forKey: .showStreaks)
        countClearedCaptures = try container.decodeIfPresent(Bool.self, forKey: .countClearedCaptures) ?? false
        countNudges = try container.decodeIfPresent(Bool.self, forKey: .countNudges) ?? false
        showCharts = try container.decodeIfPresent(Bool.self, forKey: .showCharts) ?? true
        defaultSprintMinutes = try container.decodeIfPresent(Int.self, forKey: .defaultSprintMinutes) ?? 15
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        locationTaggingEnabled = try container
            .decodeIfPresent(Bool.self, forKey: .locationTaggingEnabled) ?? true
        arrivalNudgesEnabled = try container
            .decodeIfPresent(Bool.self, forKey: .arrivalNudgesEnabled) ?? true
        celebrationsEnabled = try container
            .decodeIfPresent(Bool.self, forKey: .celebrationsEnabled) ?? true
        celebrationSoundsEnabled = try container
            .decodeIfPresent(Bool.self, forKey: .celebrationSoundsEnabled) ?? false
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
