//
//  FocusWidgetPublishing.swift
//  ADHD LifeOS
//

import Foundation
import WidgetKit

/// Builds the Home Screen widget's payload from Home's live state. Pure and total — the numbers on
/// the Home Screen come from exactly the same `FocusAnalytics` maths as the in-app weekly widget,
/// so the two can never quietly disagree.
///
/// Lives on the app side (not in the shared widget file) because `TaskSummary` and `LifeArea` are
/// app-target types the extension neither has nor needs; it only ever sees the flattened result.
enum FocusWidgetSnapshotBuilder {
    /// The daily target `WeeklyFocusSummaryWidget` shows; kept in one place so both readouts move
    /// together if it ever becomes a setting.
    static let dailyGoalMinutes = 30

    static func snapshot(
        activeGoal: TaskSummary?,
        lifeAreas: [LifeArea],
        sessions: [CompletedFocusSession],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> FocusWidgetSnapshot {
        let buckets = FocusAnalytics.currentWeek(sessions: sessions, now: now, calendar: calendar)
        return FocusWidgetSnapshot(
            generatedAt: now,
            activeGoal: activeGoal.map { goal in
                let area = lifeAreas.first { $0.id == goal.lifeAreaId }
                let duration = FocusSprintConfiguration.resolvedDuration(explicit: goal.focusDurationSeconds)
                return FocusWidgetSnapshot.ActiveGoal(
                    title: goal.title,
                    lifeAreaName: area?.name,
                    // The same fallback glyph every sprint-start path uses for an unfiled task.
                    emoji: area?.colour ?? "🎯",
                    focusDurationSeconds: duration,
                    nudgeCount: FocusSprintConfiguration.resolvedNudgeCount(
                        explicit: goal.nudgesCount, durationSeconds: duration
                    )
                )
            },
            week: FocusWidgetSnapshot.WeekStats(
                focusedSeconds: FocusAnalytics.totalFocusedSeconds(buckets),
                sessionCount: FocusAnalytics.totalSessions(buckets),
                activeDayCount: FocusAnalytics.activeDayCount(buckets),
                dailyAverageSeconds: FocusAnalytics.dailyAverageSeconds(buckets),
                streak: FocusAnalytics.currentStreak(buckets),
                dailyGoalMinutes: dailyGoalMinutes,
                dailyFocusedSeconds: buckets.map(\.focusedSeconds)
            )
        )
    }
}

/// Seam over "publish a snapshot the Home Screen widget can read" — the same `*Adapting` convention
/// as every other feature's backend edge, so Home can be built and previewed without touching the
/// real App Group container.
protocol FocusWidgetPublishing: Sendable {
    func publish(_ snapshot: FocusWidgetSnapshot)
}

/// The live publisher: writes into the shared App Group container, then asks WidgetKit to rebuild
/// the timeline so the Home Screen reflects the new numbers instead of waiting for the system's own
/// refresh budget.
///
/// Deliberately silent on failure. Publishing is best-effort decoration around the app's real work:
/// if the App Group isn't provisioned the store's `defaults` is `nil`, the write is a no-op and the
/// widget keeps showing its empty state — never an error the user has to dismiss mid-task.
struct AppGroupFocusWidgetPublisher: FocusWidgetPublishing {
    private let store: FocusWidgetSnapshotStore

    init(store: FocusWidgetSnapshotStore = FocusWidgetSnapshotStore()) {
        self.store = store
    }

    func publish(_ snapshot: FocusWidgetSnapshot) {
        store.write(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: FocusWidgetSnapshotStore.widgetKind)
    }
}
