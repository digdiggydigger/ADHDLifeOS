//
//  FocusWidgetSnapshot.swift
//  FocusTimerWidget
//

import Foundation

/// The compact payload the app publishes for the Home Screen widget.
///
/// The widget extension has no Firebase — it cannot read the user's tasks or focus history itself,
/// and a timeline provider has no time to authenticate anyway. So the app writes this snapshot into
/// the shared App Group container whenever Home's data changes, and the provider only ever decodes.
/// That makes this type the **contract between two processes**: it is versioned, and a payload
/// stamped with a version this build doesn't know is discarded rather than half-decoded.
///
/// Lives in the widget folder and is shared INTO the app target via the project's
/// `membershipExceptions` mechanism (the same one `FocusActivityAttributes` uses), so both sides
/// compile literally the same source rather than two copies that can drift.
nonisolated struct FocusWidgetSnapshot: Codable, Equatable, Sendable {
    /// Bump whenever the shape changes. An older app writing v1 while a newer widget expects v2
    /// (or the reverse, mid-upgrade) then shows the empty state instead of wrong numbers.
    ///
    /// v2 (2026-08-20) added `activeSprint`.
    static let currentVersion = 2

    /// Home's Active Goal hero, projected. `nil` when nothing is open — the hero hides itself in
    /// that state, and the widget does the same rather than inventing a task.
    nonisolated struct ActiveGoal: Codable, Equatable, Sendable {
        let title: String
        let lifeAreaName: String?
        /// The life area's emoji (stored in `LifeArea.colour`), or the unassigned target glyph.
        let emoji: String
        let focusDurationSeconds: Int
        let nudgeCount: Int
    }

    /// This calendar week's focus, mirroring the in-app `WeeklyFocusSummaryWidget` exactly.
    nonisolated struct WeekStats: Codable, Equatable, Sendable {
        let focusedSeconds: Int
        let sessionCount: Int
        let activeDayCount: Int
        let dailyAverageSeconds: Int
        let streak: Int
        let dailyGoalMinutes: Int
        /// Monday-first, always exactly 7 entries — the medium widget's spark bars.
        let dailyFocusedSeconds: [Int]

        /// Derived rather than stored: one less number that can arrive stale or inconsistent with
        /// the totals beside it. Mirrors `FocusAnalytics.goalProgress`.
        var goalProgress: Double {
            guard dailyGoalMinutes > 0, !dailyFocusedSeconds.isEmpty else { return 0 }
            let goalSeconds = Double(dailyGoalMinutes * 60 * dailyFocusedSeconds.count)
            return min(1, max(0, Double(focusedSeconds) / goalSeconds))
        }

        static let empty = WeekStats(
            focusedSeconds: 0, sessionCount: 0, activeDayCount: 0, dailyAverageSeconds: 0,
            streak: 0, dailyGoalMinutes: 30, dailyFocusedSeconds: Array(repeating: 0, count: 7)
        )
    }

    /// The sprint running right now, when there is one.
    ///
    /// Everything here is **deadline-derived rather than countdown-derived**: the widget is drawn by
    /// another process long after the app published this, very likely while the app is suspended and
    /// in no position to publish again. So there is no "remaining seconds" to go stale — the OS
    /// renders the clock itself from `deadline` (`Text(timerInterval:)`), exactly as the Live
    /// Activity does. `nil` whenever no sprint is running; the section hides rather than showing a
    /// stopped timer.
    nonisolated struct ActiveSprint: Codable, Equatable, Sendable {
        let taskTitle: String
        /// The life area's emoji, or the unassigned target glyph.
        let emoji: String
        /// Total planned length including +30s/+5m extensions, so the countdown's span stays
        /// truthful.
        let durationSeconds: Int
        /// When the countdown hits zero; `nil` while paused, where there is no live deadline at all.
        let deadline: Date?
        /// The frozen remainder while paused; `nil` while running.
        let pausedRemainingSeconds: Int?
        let checkpointsReached: Int
        let checkpointCount: Int

        var isPaused: Bool { deadline == nil }

        /// Whether the countdown has run out as of `now` — the widget's equivalent of the Live
        /// Activity's `hasElapsed`. A timeline entry scheduled AT the deadline uses this to retire
        /// the live section on time without the app having to publish anything.
        ///
        /// A paused sprint never elapses: it has no deadline to pass.
        func hasElapsed(asOf now: Date) -> Bool {
            guard let deadline else { return false }
            return deadline <= now
        }

        /// The OS-rendered countdown range, or `nil` while paused. The visual start is derived back
        /// from the deadline so the elapsed fraction survives pauses and extensions.
        var timerInterval: ClosedRange<Date>? {
            deadline.map { $0.addingTimeInterval(-TimeInterval(max(0, durationSeconds)))...$0 }
        }

        /// The paused readout, formatted like the OS timer's `showsHours: false` rendering —
        /// unpadded minutes, padded seconds, hours rolled into minutes — so pausing doesn't visibly
        /// shift the format. The same rule the Live Activity's paused frame follows.
        var frozenRemainingText: String {
            let remaining = max(0, pausedRemainingSeconds ?? 0)
            return "\(remaining / 60):" + String(format: "%02d", remaining % 60)
        }

        var checkpointSummary: String? {
            FocusCheckpointCopy.summary(reached: checkpointsReached, total: checkpointCount)
        }
    }

    let version: Int
    let generatedAt: Date
    let activeGoal: ActiveGoal?
    let activeSprint: ActiveSprint?
    let week: WeekStats

    init(
        generatedAt: Date,
        activeGoal: ActiveGoal?,
        activeSprint: ActiveSprint? = nil,
        week: WeekStats
    ) {
        self.version = Self.currentVersion
        self.generatedAt = generatedAt
        self.activeGoal = activeGoal
        self.activeSprint = activeSprint
        self.week = week
    }

    /// What the widget gallery and a fresh install show: real structure, zero fabricated history.
    static let placeholder = FocusWidgetSnapshot(
        generatedAt: Date(timeIntervalSince1970: 0), activeGoal: nil, week: .empty
    )
}

/// The one place "N of M checkpoints" is spelled, shared by the two payloads that cross a process
/// boundary — the Live Activity's content state and the Home Screen widget's snapshot. It lives in
/// this file for the same reason `FocusWidgetFormatting` does: both targets compile it, and the
/// app-side test target can therefore assert the copy.
nonisolated enum FocusCheckpointCopy {
    /// `nil` when the sprint plans no checkpoints, so no surface draws an empty caption. The reached
    /// count is clamped to the plan — the caption must never read "3 of 2".
    static func summary(reached: Int, total: Int) -> String? {
        guard total > 0 else { return nil }
        let clamped = min(max(0, reached), total)
        return "\(clamped) of \(total) checkpoint" + (total == 1 ? "" : "s")
    }
}

/// The duration formatters the widget renders with. They live in the SHARED file (rather than
/// beside the widget views) precisely so the app-side test target can see them and assert, case by
/// case, that they agree with the app's own `FocusTimeFormatting` — two processes showing the same
/// week must never disagree about how to say "1h 25m".
nonisolated enum FocusWidgetFormatting {
    /// `30s` / `15m` / `7m 30s` — mirrors `FocusTimeFormatting.human(seconds:)`.
    static func human(seconds: Int) -> String {
        let clamped = max(0, seconds)
        guard clamped >= 60 else { return "\(clamped)s" }
        let minutes = clamped / 60
        let remainder = clamped % 60
        return remainder == 0 ? "\(minutes)m" : "\(minutes)m \(remainder)s"
    }

    /// `45m` / `1h 25m` / `2h` — mirrors `FocusTimeFormatting.duration(seconds:)`.
    static func duration(seconds: Int) -> String {
        let minutes = max(0, seconds) / 60
        guard minutes >= 60 else { return "\(minutes)m" }
        let hours = minutes / 60
        let remainder = minutes % 60
        return remainder == 0 ? "\(hours)h" : "\(hours)h \(remainder)m"
    }
}

/// Reads and writes the snapshot in the App Group container shared by the app and the widget
/// extension.
///
/// Every failure path degrades to "no data" instead of trapping: `UserDefaults(suiteName:)` returns
/// `nil` when the App Group entitlement isn't provisioned, and a payload can be corrupt or written
/// by a different version of the app. In all three cases the widget shows its empty state, which is
/// honest — the alternative is a crash inside a timeline provider, which the OS shows as a blank
/// widget anyway.
nonisolated struct FocusWidgetSnapshotStore {
    /// Must match the `com.apple.security.application-groups` entitlement on BOTH targets.
    static let appGroupIdentifier = "group.com.ethananthony.ADHD-LifeOS"
    /// The widget kind, shared so the app can reload exactly this timeline.
    static let widgetKind = "FocusStatsWidget"
    static let snapshotKey = "focus.widget.snapshot"

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: FocusWidgetSnapshotStore.appGroupIdentifier)) {
        self.defaults = defaults
    }

    func write(_ snapshot: FocusWidgetSnapshot) {
        guard let defaults, let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.snapshotKey)
    }

    func read() -> FocusWidgetSnapshot? {
        guard
            let data = defaults?.data(forKey: Self.snapshotKey),
            let snapshot = try? JSONDecoder().decode(FocusWidgetSnapshot.self, from: data),
            snapshot.version == FocusWidgetSnapshot.currentVersion
        else { return nil }
        return snapshot
    }
}
