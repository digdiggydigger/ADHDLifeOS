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
    static let currentVersion = 1

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

    let version: Int
    let generatedAt: Date
    let activeGoal: ActiveGoal?
    let week: WeekStats

    init(generatedAt: Date, activeGoal: ActiveGoal?, week: WeekStats) {
        self.version = Self.currentVersion
        self.generatedAt = generatedAt
        self.activeGoal = activeGoal
        self.week = week
    }

    /// What the widget gallery and a fresh install show: real structure, zero fabricated history.
    static let placeholder = FocusWidgetSnapshot(
        generatedAt: Date(timeIntervalSince1970: 0), activeGoal: nil, week: .empty
    )
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
