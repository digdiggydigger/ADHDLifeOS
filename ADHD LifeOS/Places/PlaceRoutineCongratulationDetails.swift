//
//  PlaceRoutineCongratulationDetails.swift
//  ADHD LifeOS
//
//  E's 2026-09-13 addition to the congratulation: *"a small section within the empty-space …
//  that display detailed data and info about that specific routine that was run."*
//
//  **Pinned ABOVE the scrolling step list** (E's placement answer, chosen over "inside the
//  scroller"): on a twenty-step routine anything below the list is invisible until you scroll,
//  which is the very case scrolling was added for.
//
//  Every value arrives already computed — `PlaceRoutineRunTimeline`, `PlaceRoutineComparison`
//  and `PlaceRoutineTimeFormatting` are pure and tested. This file only lays them out.
//

import SwiftUI

@available(iOS 17.0, *)
struct PlaceRoutineCongratulationDetails: View {
    let timeline: PlaceRoutineRunTimeline
    let comparison: PlaceRoutineComparison.Verdict

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // E answered BOTH to "which started" and BOTH to "which finished": the crossing and
            // the tap can be forty minutes apart, and R1 lets Completed be tapped hours after
            // the last step.
            row(PlaceRoutineCompletionCopy.arrivedLabel, PlaceRoutineTimeFormatting.clock(timeline.arrivedAt))
            if let startedAt = timeline.startedAt {
                row(PlaceRoutineCompletionCopy.startedLabel, PlaceRoutineTimeFormatting.clock(startedAt))
            }
            if let lastStepAt = timeline.lastStepAt {
                row(PlaceRoutineCompletionCopy.lastStepLabel, PlaceRoutineTimeFormatting.clock(lastStepAt))
            }
            row(PlaceRoutineCompletionCopy.confirmedLabel, PlaceRoutineTimeFormatting.clock(timeline.confirmedAt))
            if let worked = timeline.workedDuration {
                Divider()
                row(
                    PlaceRoutineCompletionCopy.totalLabel,
                    PlaceRoutineTimeFormatting.duration(worked), emphasised: true
                )
            }
            if let verdict = comparisonLine {
                Text(verdict)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(ConfirmCelebrationGlow.colorName))
                    .minimumScaleFactor(0.8)
            }
        }
        .bentoCard()
    }

    /// `nil` draws nothing at all — and that covers BOTH "this routine has no history" and
    /// "the fetch has not answered yet", so the block never flashes a line into place a beat
    /// after the screen arrives.
    private var comparisonLine: String? {
        switch comparison {
        case .noHistory:
            return nil
        case .fastestYet:
            return "Your fastest yet"
        case .usual(let typical):
            return "About usual — you normally take \(PlaceRoutineTimeFormatting.duration(typical))"
        case .longerThanUsual(let typical):
            return "Longer than usual — you normally take \(PlaceRoutineTimeFormatting.duration(typical))"
        }
    }

    private func row(_ label: String, _ value: String, emphasised: Bool = false) -> some View {
        // `LabeledContent` reflows into stacked rows at accessibility Dynamic Type sizes
        // instead of squeezing into two narrow columns, and VoiceOver reads it as one element.
        LabeledContent(label) {
            Text(value)
                .font(emphasised ? .subheadline.weight(.semibold) : .subheadline)
                .monospacedDigit()
                .minimumScaleFactor(0.8)
        }
        .font(.subheadline)
        .foregroundStyle(emphasised ? .primary : .secondary)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Routine details — light and dark") {
    let run = PlaceRoutineCongratulationPreviewFixture.run(steps: 4)
    let timeline = PlaceRoutineRunTimeline.make(run: run, confirmedAt: .now)
    return HStack(spacing: 0) {
        PlaceRoutineCongratulationDetails(timeline: timeline, comparison: .fastestYet)
            .padding(16)
            .environment(\.colorScheme, .light)
        PlaceRoutineCongratulationDetails(timeline: timeline, comparison: .usual(typical: 1_500))
            .padding(16)
            .environment(\.colorScheme, .dark)
    }
}
#endif
