//
//  DailyGoalTracker.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-5`: E's third full-screen milestone — **the Momentum daily goal** (F7, "the
//  moment the count crosses the goal, any tab", about a second after the action, once per day).
//
//  **This is the one milestone with no site**, and every guard here follows from that. The other
//  three hang off a button: someone tapped Sorted, or Done for now, and the tap IS the event.
//  Nothing is tapped here. Home's ring is a sum over three reloading sources — closed tasks,
//  cleared captures, dismissed nudges — and the "event" is that sum changing, possibly while the
//  user is on another tab.
//
//  So the question this file answers is not "is the count over the goal" but **"did the count
//  moving MEAN something"**. Four ways it can move without anything being achieved:
//
//  1. the first load takes it from nothing to whatever today already was;
//  2. a reload whose nudges or captures fetch failed drops it, and the next good one puts it back;
//  3. turning "count cleared captures" on in Settings raises it with one tap;
//  4. lowering the goal in Settings puts the count over it without the count moving at all.
//
//  Each would be a full-screen celebration the user did not earn, on a screen they cannot dismiss —
//  the loudest possible false positive. (1) and (2) are the baseline rules, (3) and (4) are why the
//  RULES travel with the count.
//

import Foundation

/// Everything the ring's number depends on besides the work itself.
///
/// A change to any of these moves the count without anything having been done, so it re-baselines
/// rather than counts — the goal and the two Settings toggles are part of what the number MEANS.
struct DailyGoalRules: Equatable {
    let goal: Int
    let countsClearedCaptures: Bool
    let countsNudges: Bool
}

enum DailyGoalCrossing {
    /// Whether the count ARRIVED at the goal between these two readings.
    ///
    /// `previous < goal` is what makes a goal lowered under the count a non-event: the count was
    /// already past the new goal, so nothing crossed it. A goal of zero is crossed by standing
    /// still, so it is not treated as a goal at all.
    static func crossed(previous: Int, current: Int, goal: Int) -> Bool {
        goal > 0 && previous < goal && current >= goal
    }
}

/// Home's memory of the ring between reloads. A value type: Home keeps it in `@State`, so it lives
/// exactly as long as the screen and starts again on relaunch — which is right, because the day
/// marker, not this, is what makes the milestone once-per-day.
struct DailyGoalTracker {
    private var previous: Int?
    private var rules: DailyGoalRules?

    /// Returns whether THIS reading is a crossing worth celebrating.
    ///
    /// **`settled` neither counts nor moves the baseline, and the second half is the load-bearing
    /// one.** A reload whose nudges fetch failed reports the count without them; if that dropped
    /// reading became the baseline, recovering from it would read as a fresh rise across the goal.
    /// Ignoring it entirely keeps the last GOOD reading, so recovery compares good with good.
    mutating func observe(count: Int, rules newRules: DailyGoalRules, settled: Bool) -> Bool {
        guard settled else { return false }
        let known = previous
        let sameRules = rules == newRules
        previous = count
        rules = newRules
        // No previous reading is Home's first load; changed rules are a number that means
        // something different from the one before it. Both re-baseline and celebrate nothing — and
        // a re-baseline is not a free pass, because the very next real crossing still counts.
        guard let known, sameRules else { return false }
        return DailyGoalCrossing.crossed(previous: known, current: count, goal: newRules.goal)
    }
}

/// What VoiceOver is told when the goal is reached — **E's call, 2026-09-12: the daily goal ONLY.**
///
/// A full-screen celebration is `accessibilityHidden`, which is right for Confirm, right for the
/// nine pops and right for the other two milestones: each of those leaves the user on a screen that
/// states the outcome (an empty inbox, a card reading "7 of 7 days") and each has a haptic of its
/// own. This one fires on ANY tab about a second after the action, the ring may not be on screen,
/// and the site has no haptic — R-d has the CENTRE play `.success` for it because no site does. So
/// without this a VoiceOver user would never learn it happened.
enum DailyGoalAnnouncement {
    static func text(count: Int, goal: Int) -> String {
        "Daily goal reached — \(count) of \(goal) closed today"
    }
}
