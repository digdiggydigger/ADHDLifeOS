//
//  PlaceRoutineScreenPreviews.swift
//  ADHD LifeOS
//
//  `PlaceRoutineScreen`'s preview scaffolding, moved out of the screen in
//  `F-CTACelebrations-6` to make room for the Completed flow. Nine `*Previews.swift` files
//  already do this; no test in either target references a preview or this fixture.
//
//  **Moving it buys FILE lines and no TYPE-BODY lines**, and knowing which ceiling binds is the
//  point: the `#if DEBUG` block sat OUTSIDE `PlaceRoutineScreen`'s body, so the screen's
//  `type_body_length` (235 of SwiftLint's 250) did not move by a line. The second room move —
//  `openExternally` into `PlaceRoutineScreen+Opening.swift` — is the one that buys body lines.
//

#if DEBUG
import SwiftUI

/// Preview scaffolding only. Built outside the `#Preview` body because a result-builder
/// closure cannot carry an explicit `return`, and the fixture needs a mutation.
@available(iOS 17.0, *)
enum PlaceRoutineScreenPreviewFixture {
    static var run: RoutineRun {
        let gymId = UUID()
        let actions = [
            PlaceAction(id: UUID(), direction: .arrival, kind: .journalLine(body: "Leg day")),
            PlaceAction(
                id: UUID(), direction: .arrival,
                kind: .openApp(scheme: "snapchat", displayName: "Snapchat")
            ),
            PlaceAction(
                id: UUID(), direction: .arrival,
                kind: .openApp(scheme: "gym", displayName: "Gym")
            ),
            PlaceAction(id: UUID(), direction: .arrival, kind: .openLink(
                displayName: "Gym Music on Spotify",
                link: "https://open.spotify.com/playlist/abc", scheme: "spotify"
            ))
        ]
        var run = RoutineRun.make(
            event: PlaceTriggerEvent(
                placeId: gymId, kind: .arrival, occurredAt: .now.addingTimeInterval(-120)
            ),
            entry: AtPlaceSnapshot.PlaceEntry(
                placeId: gymId, displayName: "Gym 🏋️", openTaskTitles: [],
                arrivalMessage: "Time to train", actions: actions,
                latitude: nil, longitude: nil
            ),
            plan: PlaceRoutinePlan.make(actions, for: .arrival)
        )
        // One tapped step, so the preview shows the Undo chip and a part-filled bar.
        run.steps[1].state = .done
        return run
    }
}

@available(iOS 17.0, *)
#Preview("Routine — light and dark") {
    HStack(spacing: 0) {
        PlaceRoutineScreen(
            run: PlaceRoutineScreenPreviewFixture.run,
            store: UserDefaultsRoutineRunStore(defaults: nil),
            onOpenTab: { _ in }, onStartSprint: { _ in },
            activity: InertRoutineActivityPresenter(),
            recorder: InertRoutineRunRecorder()
        )
        .environment(\.colorScheme, .light)
        PlaceRoutineScreen(
            run: PlaceRoutineScreenPreviewFixture.run,
            store: UserDefaultsRoutineRunStore(defaults: nil),
            onOpenTab: { _ in }, onStartSprint: { _ in },
            activity: InertRoutineActivityPresenter(),
            recorder: InertRoutineRunRecorder()
        )
        .environment(\.colorScheme, .dark)
    }
}
#endif
