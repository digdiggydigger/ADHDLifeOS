//
//  HomeView+DailyGoal.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-5`: the Momentum daily goal — E's F7, "the moment the count crosses the goal,
//  any tab", about a second after the action, once per day.
//
//  In its own file on the `HomeView+Refresh` arrangement: only methods and computed views can leave
//  `HomeView.swift`, so the three stored properties this needs (`dailyGoalTracker`, `ringOrigin`,
//  `hasLoadedClearedCaptures`) stay on the type and everything else lives here.
//
//  **"Any tab" costs nothing, and that is a property of the container rather than of this code.**
//  `AppTabContent` builds a tab once and then KEEPS it, merely offsetting the hidden ones off
//  screen — so Home is still mounted, still receiving `DataChangeSignal`, and still recomputing
//  this while the user is on Tasks. The celebration is drawn by whichever layer is frontmost, not
//  by Home.
//

import SwiftUI

extension HomeView {
    /// The ring's number, named once so the scoreboard and the milestone can never read a
    /// different sum. Both Settings toggles are already folded into the two counts it adds.
    var ringCount: Int {
        closedToday.count + capturesClearedToday + nudgesDismissedToday
    }

    /// What the number MEANS. A change here moves the ring without anything having been achieved,
    /// so `DailyGoalTracker` re-baselines instead of celebrating — see that file.
    var ringRules: DailyGoalRules {
        DailyGoalRules(
            goal: momentumPreferences.dailyGoal,
            countsClearedCaptures: momentumPreferences.countClearedCaptures,
            countsNudges: momentumPreferences.countNudges
        )
    }

    /// **Whether every input behind `ringCount` is currently KNOWN**, which is not the same as
    /// "has loaded once".
    ///
    /// Each of the three contributes 0 when its fetch failed, and 0 is indistinguishable from a
    /// real zero: `homeService` and `nudgesService` both fall to `.failed` (whose `nudges`/`allTasks`
    /// read as empty), and `capturesClearedToday` is written from two `try?` fetches. A dip like
    /// that followed by a recovery is a rise across the goal that nobody earned — so while any
    /// input is unknown the tracker is told to ignore the reading entirely, keeping the last good
    /// baseline rather than adopting the dip.
    var ringSettled: Bool {
        guard case .loaded = homeService.state, case .loaded = nudgesService.state else { return false }
        return hasLoadedClearedCaptures
    }

    /// Called whenever the ring's count or its settledness changes.
    ///
    /// **The day is marked BEFORE the request**, because nothing downstream marks it: a request
    /// that fired and left the day unmarked would replay on the next crossing, and F7's
    /// "no replay after an undo-and-recross" is exactly that case.
    ///
    /// With no signed-in user there is nothing to key the day on, so nothing fires — the
    /// `refreshNudgeFirstRunMarker` precedent, and the same reason: guessing is the harmful
    /// direction.
    func observeDailyGoal() {
        guard dailyGoalTracker.observe(count: ringCount, rules: ringRules, settled: ringSettled),
              let uid = authService.signedInUser?.id.uuidString,
              !CelebrationDayMarking.hasCelebrated(.dailyGoal, uid: uid)
        else { return }
        CelebrationDayMarking.markCelebrated(.dailyGoal, uid: uid)
        // R-h: with E's switch off, or inside the cooldown, this becomes a pop — and the ring is
        // one of the two sites with no pop of its own, so it hands over where it is.
        celebrate.request(.milestone(.dailyGoal), at: ringOrigin)
        // E's call, 2026-09-12: the daily goal is the ONE milestone that announces itself. The
        // celebration is `accessibilityHidden`; this site has no haptic of its own (R-d puts that
        // in the centre) and no guaranteed on-screen change, because it can fire on any tab.
        // Posted after the request so VoiceOver speaks over a celebration that is already running.
        let reached = DailyGoalAnnouncement.text(count: ringCount, goal: ringRules.goal)
        UIAccessibility.post(notification: .announcement, argument: reached)
    }
}
