//
//  PlaceRoutineCompletedCard.swift
//  ADHD LifeOS
//
//  E's R1 and R2: once every step is resolved — done OR skipped — the next-step slot has
//  nothing left to promote, and this takes its place. **Nothing is recorded as completed, and
//  nothing celebrates, without this tap** (E, unprompted: *"the user must have to confirm by
//  manually tapping a 'Completed' button before any actions such as logging it to the Journal
//  or running the animation etc are run"*).
//
//  **It records its own origin rather than being wrapped in `CelebrationPopSource`, and that is
//  forced rather than chosen.** The wrapper's handle only ever requests `.pop`; this button
//  needs `.milestone(.routineFinished)`. So it measures its own centre and hands it up, the
//  same shape the Momentum ring uses for R-h's fallback pop — which is why the app's hand-rolled
//  origin count is four rather than three.
//
//  The origin is measured on the BUTTON, never on the card: a centre taken from the bento is
//  the middle of the whole card rather than the thing the thumb pressed.
//

import SwiftUI

@available(iOS 17.0, *)
struct PlaceRoutineCompletedCard: View {
    let run: RoutineRun
    /// Hands the screen the button's global centre, so the celebration leaves from the control
    /// that was pressed. `nil` until the first geometry reading, which the layer treats as
    /// "centre of the screen" rather than as an error.
    let onComplete: (CGPoint?) -> Void

    @State private var origin: CGPoint?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(PlaceRoutineCompletionCopy.completedEyebrow)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .tracking(0.5)
                // E's own wording, hyphen-minus and all: "4 of 4 done - Ready to finish?"
                Text(PlaceRoutineCompletionCopy.completedTitle(for: run))
                    .font(.title2).bold()
                    .minimumScaleFactor(0.8)
            }
            Button(PlaceRoutineCompletionCopy.completedButton) {
                // `.success`, not the `.solid` a step's action plays: this is the run ending.
                Haptics.play(.success)
                onComplete(origin)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("routineCompletedButton")
            .celebrationPopOrigin { origin = $0 }
        }
        .bentoCard()
        // Deliberately NO identifier on the card: one on a container is INHERITED by every
        // child, which would rename the Completed button out from under itself — the exact way
        // `HomeRoutineCard`'s first journey run failed.
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Completed card — light and dark") {
    let run = PlaceRoutineCongratulationPreviewFixture.run(steps: 4)
    return VStack(spacing: 24) {
        PlaceRoutineCompletedCard(run: run, onComplete: { _ in })
            .environment(\.colorScheme, .light)
        PlaceRoutineCompletedCard(run: run, onComplete: { _ in })
            .environment(\.colorScheme, .dark)
    }
    .padding(16)
    .background(Color.pageBackground)
}
#endif
