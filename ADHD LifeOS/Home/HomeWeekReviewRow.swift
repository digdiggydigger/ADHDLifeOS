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
            TodayDoneLineLabel(done: done)
                // R-h: a downgraded daily goal pops from here, so the line reports where it is.
                .celebrationPopOrigin { doneLineOrigin = $0 }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
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

/// The done line's words: the count, then its door. **E's Q3 (2026-09-26), "B · Follows the
/// count":** on the right edge the capture disc covered "review" at rest whenever the "then" list
/// was short, so the link follows the count — round 5b's own "✓ 3 done today · Week review ›".
///
/// ONE view tree whose layout switches, not a `ViewThatFits` of two copies: the daily goal's pop is
/// measured on this view, and a hidden copy must never be able to report a position. It stacks
/// from xxLarge — the longest line, "12 of 20 done today · Week review ›", is ~328pt at xLarge
/// against the row's 370pt and reaches the edge at xxLarge (§1: never truncate).
struct TodayDoneLineLabel: View {
    let done: String

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let stacks = typeSize >= .xxLarge
        let layout = stacks
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 8))
        layout {
            Label(done, systemImage: "checkmark.circle")
                .font(.subheadline)
                .foregroundStyle(Color("LabelSecondary"))
            if !stacks {
                Text("·")
                    .font(.subheadline)
                    .foregroundStyle(Color("LabelSecondary"))
            }
            HStack(spacing: 4) {
                Text("Week review")
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.accentColor)
        }
    }
}

#Preview("Done line — light") {
    VStack(alignment: .leading, spacing: 16) {
        TodayDoneLineLabel(done: "3 done today")
        TodayDoneLineLabel(done: "12 of 20 done today")
        TodayDoneLineLabel(done: "12 of 20 done today").dynamicTypeSize(.xxLarge)
    }
    .padding(16)
    .background(Color.pageBackground)
}

#Preview("Done line — dark") {
    VStack(alignment: .leading, spacing: 16) {
        TodayDoneLineLabel(done: "3 done today")
        TodayDoneLineLabel(done: "12 of 20 done today").dynamicTypeSize(.xxLarge)
    }
    .padding(16)
    .background(Color.pageBackground)
    .preferredColorScheme(.dark)
}
