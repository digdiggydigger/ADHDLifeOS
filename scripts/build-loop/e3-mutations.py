#!/usr/bin/env python3
"""F-E3 red-check mutations. mutate.py <batch> applies one batch to the tree; restore with git checkout --.

Each mutation names the test(s) that must catch it. A batch mixes mutations only when their
catching tests are disjoint, so every expected failure is attributable to exactly one mutation.
"""
import sys

import os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "ADHD LifeOS") + "/"

BATCHES = {
    # Behavioural: needs a rebuild.
    "pure": [
        ("Home/TodayPlan.swift",  # place and paused swap ranks -> testWhereYouAreBeatsAPausedSprint
         """        } else if hasPlaceCard {
            slot = .place
        } else if let pausedSprint {
            slot = .paused(pausedSprint)""",
         """        } else if let pausedSprint {
            slot = .paused(pausedSprint)
        } else if hasPlaceCard {
            slot = .place"""),
        ("Home/TodayPlan.swift",  # WIDENING: every open task listed -> testTheThenListHoldsWhatIsDueExceptTheCardsTask
         """            return skipped.contains(task.id) || isDue(task)""",
         """            return true"""),
        ("Home/TodayStores.swift",  # skips never expire -> testSkipsExpireAtTheStartOfTheNextDay (+ drop-yesterday)
         """              stored[dayField] as? String == dayKey(for: now, calendar: calendar),
""",
         ""),
        ("Home/TodayCardRules.swift",  # an unchanged line still writes -> testAnUnchangedLineWritesNothing
         """        guard normalized != current else { return nil }
""",
         ""),
        ("Home/TodayCardCopy.swift",  # the goal is ignored -> testWithADailyGoalTheDoneLineSaysTheGoal
         """        guard let goal else { return "\\(count) done today" }
        return "\\(count) of \\(goal) done today\"""",
         """        _ = goal
        return "\\(count) done today\""""),
    ],
    # Source-reading guards: test-without-building sees these with no rebuild.
    "source": [
        ("Home/HomeView.swift",  # the charts' triggers no longer fetch -> testTheHistoryReloadsOnTheChartsThreeTriggers
         """            .task(id: focusReloadToken + pullRefreshCount) { await loadFocusHistory() }
""",
         ""),
        ("Tools/ToolsView.swift",  # Nudges loses its only door -> testToolsHasTheNudgesDoorBesideRoutines
         """                    ToolsNudgesSection(service: nudgesService) { pushedDestination = .nudges }
""",
         ""),
        ("Tools/ToolsView.swift",  # the centre never reaches Tools' service -> testToolsHandsItsNudgesServiceTheCentreAndTheUndoSlot
         """                nudgesService.celebrate = celebrate
""",
         ""),
        ("Home/HomeView+Refresh.swift",  # the widget stops following the card -> testTheWidgetPublishesWhatTheCardLeadsWith
         """                activeGoal: todayPlan.headlineTask,""",
         """                activeGoal: homeService.openTasks.first,"""),
        ("Home/HomeWeekReviewRow.swift",  # E's Q3 undone: the link pushed back to the edge -> testTheDoneLinesDoorFollowsTheCount
         """            if !stacks {
                Text("·")""",
         """            Spacer(minLength: 8)
            if !stacks {
                Text("·")"""),
        ("Home/HomeView+Today.swift",  # a paused sprint never reaches the plan -> testTheCardIsChosenByOnePlanFedEveryInput
         """            pausedSprint: TodayPausedSprint.from(status: activeSprint, sprint: widgetSprint),""",
         """            pausedSprint: nil,"""),
    ],
}

batch = sys.argv[1]
for rel, old, new in BATCHES[batch]:
    path = ROOT + rel
    text = open(path).read()
    assert text.count(old) == 1, f"{rel}: expected exactly one match for {old[:60]!r}, found {text.count(old)}"
    open(path, "w").write(text.replace(old, new))
    print(f"mutated {rel}")
