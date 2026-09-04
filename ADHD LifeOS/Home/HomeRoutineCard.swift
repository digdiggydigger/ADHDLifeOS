//
//  HomeRoutineCard.swift
//  ADHD LifeOS
//
//  The way back into a live routine (F-Routines-4-HomeCard, the canvas HomeCard board).
//
//  A swiped-away notification would otherwise be a dead end — "not now" and an accident look
//  identical to iOS — so while a run is live, Today carries it. The card is a PULL surface:
//  it reads the run store, it is present exactly while a run is live, and it is gone the
//  moment one is not. Nothing pushes it.
//
//  Its own file, and the HomeView glue with it: `HomeView.swift` (391), `HomeAccessoryStrips`
//  (395) and `HomeMomentumSections` (390) are all within a dozen lines of the 400 lint bar.
//

import SwiftUI

/// Every word on the card, pure so each is pinned by a test rather than living in a body.
enum HomeRoutineCardModel {
    static let continueLabel = "Continue routine"

    static func headline(for run: RoutineRun) -> String {
        let moment = run.direction == .arrival ? "AT" : "LEAVING"
        return "\(moment) \(run.displayName.uppercased()) · ROUTINE LIVE"
    }

    /// A fully-resolved run stays live until the screen is LEFT (so Undo survives the last
    /// tap), which makes "everything done, still live" a reachable state Today must not lie
    /// about.
    static func stepsLeftLine(for run: RoutineRun) -> String {
        let pending = run.steps.filter { $0.state == .pending }.count
        switch pending {
        case 0: return "All steps done"
        case 1: return "1 step left"
        default: return "\(pending) steps left"
        }
    }

    static func nextLine(for run: RoutineRun) -> String? {
        guard let index = PlaceRoutineProgress.nextPendingIndex(run) else { return nil }
        return "Next: \(PlaceActionRowLabel.title(for: run.steps[index].action))"
    }

}

struct HomeRoutineCard: View {
    let run: RoutineRun
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(HomeRoutineCardModel.headline(for: run))
                .sectionLabel()
                .foregroundStyle(Color.accentColor)
            Text(HomeRoutineCardModel.stepsLeftLine(for: run))
                .font(.title2).bold()
                .minimumScaleFactor(0.8)
            if let next = HomeRoutineCardModel.nextLine(for: run) {
                Text(next)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Button(HomeRoutineCardModel.continueLabel) {
                Haptics.play(.solid)
                onContinue()
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("homeRoutineContinueButton")
            .padding(.top, 8)
        }
        .bentoCard()
        // Deliberately NO identifier on the container: an accessibility identifier on a
        // wrapper is INHERITED by every child, which would rename the Continue button out
        // from under itself. Per-control, never on the card — the house rule ToolsCatalog
        // spells out, and the exact way this card's first journey run failed.
    }
}

extension HomeView {
    /// Today's "where am I right now" slot. Both cards live here so the suppression rule is
    /// one decision in one place — and so `HomeView.swift`'s body spends ONE line on it.
    @ViewBuilder
    var arrivalAndRoutineCards: some View {
        if let liveRoutineRun {
            HomeRoutineCard(run: liveRoutineRun) {
                // The same door the notification tap uses — the `PlaceActionNotificationRouter
                // .open` precedent (block 4 of the place-actions arc): one door, one
                // pending/replay rule, and no new parameter threaded through HomeView.
                PlaceRoutineNotificationRouter.shared.open(liveRoutineRun.id)
            }
        }
        // Variation B (block 4c): here, with something to do here — pinned above everything
        // because "you are AT the place" beats every other priority signal Today has. Absent
        // the moment either half stops being true.
        //
        // It is NO LONGER suppressed while that place's routine is live (E's veto, 2026-09-04:
        // "i want it shown"). The build plan had the routine card take the slot on the grounds
        // that two cards about one place is noise; E's call is that they answer different
        // questions — the routine is the sequence you are part-way through, the arrival card is
        // the tasks that live here — and losing the second to show the first hides work.
        if let arrivalSurface {
            ArrivalSurfaceCard(surface: arrivalSurface, onOpenTask: openArrivalTask)
        }
    }

    /// Reads the one live run, applying the lifetime rules lazily on the way (the store's read
    /// IS the end-of-day sweep). Called from `refreshArrivalSurface`, so it rides every path
    /// that already refreshes Today's other place-aware card: appear, pull-to-refresh, and the
    /// app-wide `DataChangeSignal` — which the routine screen posts as it closes.
    ///
    /// HomeView ALSO calls it on `scenePhase == .active`, and that trigger is load-bearing
    /// rather than belt-and-braces: a crossing while the app is backgrounded writes the run to
    /// UserDefaults, and a routine made only of tap-steps writes NOTHING to Firestore — so no
    /// `DataChangeSignal` fires, and `.task` does not re-run on a warm return (`AppTabContent`
    /// keeps every visited tab alive). Without it the card — the whole recovery surface for a
    /// swiped-away notification — would be stale in exactly the case it exists for.
    func refreshLiveRoutine() {
        liveRoutineRun = routineRunStore.readLiveRun(now: .now)
    }
}
