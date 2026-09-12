//
//  HomeView+Refresh.swift
//  ADHD LifeOS
//
//  HomeView's two reload/publish methods, in their own file so `HomeView.swift` stays inside
//  SwiftLint's 400-line file budget (it was at 399 when `F-CTACelebrations-1` needed a line for
//  the Reduce Motion environment read). The `HomeAccessoryStrips` / `HomeMomentumSections`
//  arrangement: only methods and computed views can move — stored `@State`/`@StateObject`
//  properties must stay on the type itself.
//

import SwiftUI

extension HomeView {
    /// Every Home data source in parallel — the pull gesture and the app-wide `DataChangeSignal`
    /// run the same reload, so the two paths can never drift. Bumping `pullRefreshCount` folds
    /// the analytics section (and its widget republish) into both.
    func refreshEverything() async {
        pullRefreshCount += 1
        async let home: Void = homeService.load()
        async let nudges: Void = nudgesService.load()
        async let inbox: Void = refreshInboxCount()
        _ = await (home, nudges, inbox)
        // After the parallel block, so the card is built from the tasks that just landed.
        await refreshArrivalSurface()
        publishWidgetSnapshot(sprint: widgetSprint)
    }

    /// Rebuilds and publishes the Home Screen widget's payload. Cheap, pure and idempotent, so
    /// calling it from every path that changes either half beats working out which half moved.
    /// The sprint is passed in rather than read off `self` — and required, not defaulted, because
    /// "no sprint" is a real value here (a sprint ENDING is exactly when the live section must
    /// disappear) and a default would quietly re-read the stale stored property instead.
    ///
    /// Internal, not private: `HomeView.body` calls it from `HomeView.swift`, and `private` in an
    /// extension is scoped to the file the extension is written in.
    func publishWidgetSnapshot(sprint: FocusWidgetSnapshot.ActiveSprint?) {
        widgetPublisher.publish(
            FocusWidgetSnapshotBuilder.snapshot(
                activeGoal: homeService.activeGoal,
                lifeAreas: homeService.lifeAreas,
                sessions: publishedHistory,
                activeSprint: sprint,
                dailyGoalMinutes: momentumPreferences.focusDailyGoalMinutes,
                defaultSprintSeconds: momentumPreferences.defaultSprintMinutes * 60
            )
        )
        widgetPublisher.publishLifeAreas(
            LifeAreasWidgetSnapshotBuilder.snapshot(
                lifeAreas: homeService.lifeAreas,
                openTasks: homeService.openTasks
            )
        )
    }
}
