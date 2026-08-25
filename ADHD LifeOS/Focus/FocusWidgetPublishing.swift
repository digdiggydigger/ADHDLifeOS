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
        activeSprint: FocusWidgetSnapshot.ActiveSprint? = nil,
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
            activeSprint: activeSprint,
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

extension FocusSessionService {
    /// The running sprint, projected for the Home Screen widget — `nil` when none is running.
    ///
    /// Deliberately built from the DEADLINE rather than from `remainingSeconds`, for two reasons.
    /// It has to survive the trip: the widget is drawn by another process long after this was
    /// written, so a countdown value would arrive stale while a deadline stays correct. And it has
    /// to be STABLE while a sprint simply runs — Home republishes whenever this value changes, and a
    /// value that moved twice a second would hand WidgetKit a reload storm. What legitimately moves
    /// it is pause, resume, extend, and a cadence re-plan: everything that changes the deadline or
    /// the PLAN. A checkpoint merely being crossed does not, because the widget works that out for
    /// itself from the positions.
    var widgetSprint: FocusWidgetSnapshot.ActiveSprint? {
        guard let session else { return nil }
        return FocusWidgetSnapshot.ActiveSprint(
            taskTitle: session.taskTitle,
            emoji: session.lifeAreaEmoji,
            durationSeconds: session.durationSeconds,
            deadline: session.isPaused ? nil : sprintDeadline,
            pausedRemainingSeconds: session.isPaused ? session.remainingSeconds : nil,
            // Positions, not counts. The widget derives "how many have passed" from these against
            // the deadline, so the readout keeps moving after the app is suspended and can no
            // longer publish anything.
            checkpointSeconds: session.nudgeCheckpoints
        )
    }
}

/// Seam over "publish a snapshot the Home Screen widget can read" — the same `*Adapting` convention
/// as every other feature's backend edge, so Home can be built and previewed without touching the
/// real App Group container.
protocol FocusWidgetPublishing: Sendable {
    func publish(_ snapshot: FocusWidgetSnapshot)
    /// The Life Areas widget's payload, published from the same Home choke point (E's 2026-08-25
    /// widgets note) — the two snapshots move together because both are built from Home's state.
    func publishLifeAreas(_ snapshot: LifeAreasWidgetSnapshot)
}

extension FocusWidgetPublishing {
    /// Default no-op so single-purpose fakes and previews keep compiling; the live publisher
    /// overrides it. Publishing stays best-effort decoration either way.
    func publishLifeAreas(_ snapshot: LifeAreasWidgetSnapshot) {}
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

    func publishLifeAreas(_ snapshot: LifeAreasWidgetSnapshot) {
        LifeAreasWidgetStore().write(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: LifeAreasWidgetStore.widgetKind)
    }
}
