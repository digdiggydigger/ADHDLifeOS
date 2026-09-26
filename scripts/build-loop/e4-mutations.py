#!/usr/bin/env python3
"""F-E4 red-check mutations. e4-mutations.py <batch>; restore with git checkout -- "ADHD LifeOS".

Each mutation names the test(s) that must catch it; a batch mixes mutations only when their
catching tests are disjoint, so every expected failure is attributable to exactly one mutation.
"""
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "ADHD LifeOS") + "/"

BATCHES = {
    # Behavioural: needs a rebuild.
    "pure": [
        ("Home/WeekReviewInputs.swift",  # a rolling window, not the calendar week -> testTheReviewChartsTheCalendarWeekMondayFirst
         "focusWeek: FocusAnalytics.currentWeek(sessions: inputs.sessions, now: now, calendar: calendar),",
         "focusWeek: FocusAnalytics.currentWeek(sessions: inputs.sessions, now: now.addingTimeInterval(-86_400 * 3), calendar: calendar),"),
        ("Home/WeekReviewInputs.swift",  # a goal nobody chose -> testNoGoalSetMeansNoGoalBar (+ WeeklyChain's pin, source)
         "dailyGoalMinutes: inputs.focusDailyGoalMinutes ?? 0",
         "dailyGoalMinutes: inputs.focusDailyGoalMinutes ?? 30"),
        ("Areas/AreasService.swift",  # the Areas door forgets the goal -> testTheAreasDoorCarriesTheFocusGoal (+ testBothDoorsCarryTheFocusGoal)
         "focusDailyGoalMinutes: preferencesStore.read().focusDailyGoalMinutes",
         "focusDailyGoalMinutes: nil"),
    ],
    # Source-reading guards: test-without-building sees these with no rebuild.
    "source": [
        ("Focus/WeeklyFocusSummaryWidget.swift",  # the streak stat comes back -> testTheChartShedsItsStreakAndItsUnitToggle
         """            stat(value: FocusTimeFormatting.duration(seconds: averageSeconds), label: "Daily Avg")""",
         """            stat(value: FocusTimeFormatting.duration(seconds: averageSeconds), label: "Daily Avg")
            stat(value: "\\(FocusAnalytics.currentStreak(buckets))", label: "Day Streak")"""),
        ("Home/WeekReviewView.swift",  # the closures bars come back beside it -> testWeekReviewDrawsTheOneFocusChartInPlaceOfTheClosureBars
         "    private var winsSection: some View {",
         "    private var barsCard: some View { EmptyView() }\n\n    private var winsSection: some View {"),
        ("Home/HomeWeekReviewRow.swift",  # Today's door forgets the goal -> testBothDoorsCarryTheFocusGoal
         "focusDailyGoalMinutes: momentumPreferences.focusDailyGoalMinutes",
         "focusDailyGoalMinutes: nil"),
    ],
}

batch = sys.argv[1]
for rel, old, new in BATCHES[batch]:
    path = ROOT + rel
    text = open(path).read()
    assert text.count(old) == 1, f"{rel}: expected exactly one match for {old[:60]!r}, found {text.count(old)}"
    open(path, "w").write(text.replace(old, new))
    print(f"mutated {rel}")
