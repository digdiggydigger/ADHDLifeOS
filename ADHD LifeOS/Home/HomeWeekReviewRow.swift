//
//  HomeWeekReviewRow.swift
//  ADHD LifeOS
//
//  Today's week-review door. Since `F-E3-OneCardToday` it is idea 9's done line — round 5b:
//  *"Idea 9's line under the 'then' list reads '✓ 3 done today · Week review ›'"* (E accepted this
//  one bend of Structure C's "nothing else") — and the Areas tab carries the second door.
//

import SwiftUI

extension HomeView {
    /// **The count is `ringCount`, the daily goal's own number.** The goal's celebration pops from
    /// this line now that the ring is gone, so the line must say the number that crossed — never a
    /// different sum beside it. It is also the number board `59` drew: the round-3 simulator's ring
    /// read "3 of 5" when those frames were made, and the board says "3 done today". A set goal
    /// shows as "3 of 5 done today" (E, 2026-09-26).
    var doneTodayLine: some View {
        // One string for the line and its VoiceOver label, so the two can never say different sums.
        let done = TodayCardCopy.doneTodayLine(count: ringCount, goal: momentumPreferences.dailyGoal)
        return Button {
            isPresentingWeekReview = true
        } label: {
            HStack(spacing: 8) {
                Label(done, systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(Color("LabelSecondary"))
                    // R-h: a downgraded daily goal pops from here, so the line reports where it is.
                    .celebrationPopOrigin { doneLineOrigin = $0 }
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    Text("Week review")
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(done). Week review")
        .accessibilityHint("Opens your week review")
        // The identifier the old row carried: it is still Today's week-review door and still the
        // last thing on the page (`CaptureDiscClearanceUITests`).
        .accessibilityIdentifier("homeWeekReviewRow")
    }

    /// Through `WeekReviewView(inputs:)`, the one construction both doors share (`F-E3`), so
    /// Today's review and the Areas tab's can never be built from different parts.
    var weekReviewDestination: some View {
        WeekReviewView(inputs: WeekReviewInputs(
            tasks: homeService.allTasks,
            lifeAreas: homeService.lifeAreas,
            sessions: publishedHistory,
            inboxCount: inboxCount,
            openTaskCount: homeService.openTasks.count,
            areaCount: homeService.activeAreas.count,
            dueNudgeCount: nudgesService.dueNudges().count
        ))
    }
}
