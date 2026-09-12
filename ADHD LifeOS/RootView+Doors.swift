//
//  RootView+Doors.swift
//  ADHD LifeOS
//
//  RootView's notification and widget DOORS, split out in F-Routines-3 when the routine door
//  would have tipped `RootView.swift` over the 400-line bar. The members these functions
//  touch are `internal` on RootView with a comment saying why — Swift `private` is
//  file-scoped, the HomeView.arrangeAreas precedent.
//

import SwiftUI

extension RootView {
    /// Every sprint-start path (card button, detail-screen launch row) funnels here, so the
    /// success haptic the web fires on start (`triggerHaptic('success')`) happens exactly once
    /// per launch. Moved here from `RootView.swift` in F-ConfirmCelebration-1, for the 400-line
    /// bar; the sprint door below is one of its callers.
    func startFocus(_ plan: FocusSprintPlan) {
        Haptics.play(.success)
        focusService.start(plan: plan)
    }

    /// The widget doors' one entry point — called immediately when the tabs are on screen,
    /// and as the drain for a link that had to wait out a cold launch.
    func openWidgetDoor(_ link: AppDeepLink) {
        switch link {
        case .areasTab:
            selectedTab = .areas
        case .captureComposer(let kind):
            isFabOpen = false
            composerKind = kind
        case .routineScreen:
            // The Live Activity's tap. Same resolution as the notification's — the STORE is
            // the truth — so a card left over from an ended run lands on Today, never on a
            // blank screen.
            openRoutineDoor(routineRunStore.readLiveRun(now: .now)?.id)
        case .authCallback, .focusWidget:
            break
        }
    }

    /// ActivityKit is 16.1+ and the routine screen is 17-gated, so in practice this is always
    /// the real presenter — the inert one keeps the type total rather than guarding at the
    /// call site.
    func routineActivityPresenter() -> RoutineActivityPresenting {
        if #available(iOS 16.1, *) {
            // The SHARED instance: this factory is called from a `@ViewBuilder`, so a fresh
            // presenter here would be replaced on every re-render — along with its handle to
            // the running Activity.
            return RoutineActivityKitPresenter.shared
        }
        return InertRoutineActivityPresenter()
    }

    /// The place-action doors (F-PlaceActions-3): a tapped notification's in-app half.
    /// External URL opens never reach here — the router hands those straight to the system.
    func openActionDoor(_ door: PlaceActionDoor) {
        switch door {
        case .screen(let screen):
            selectedTab = screen.appTab
        case .sprint(let minutes):
            let fallback = UserDefaultsMomentumPreferencesStore().read().defaultSprintMinutes
            startFocus(PlaceActionSprint.plan(minutes: minutes, defaultMinutes: fallback))
        }
    }

    /// The routine door (F-Routines-3). The tap carries only the minted run key; the STORE is
    /// the source of truth, and a mismatch — an old notification, an ended run, a broken
    /// payload, a pre-17 device — is the stale-tap rule: open Today, nothing else. Never a
    /// blank routine screen.
    func openRoutineDoor(_ runKey: UUID?) {
        guard #available(iOS 17.0, *),
              let runKey,
              let run = routineRunStore.readLiveRun(now: .now),
              run.id == runKey else {
            selectedTab = .today
            return
        }
        presentedRoutineRun = run
    }

    /// Doors that arrived before the signed-in tabs existed, drained the moment they mount.
    /// A state change AFTER mount on purpose: presenting by pre-set state on first render is
    /// the flaky path.
    func drainPendingDoors() {
        if let link = pendingWidgetLink {
            pendingWidgetLink = nil
            openWidgetDoor(link)
        }
        if let door = pendingActionDoor {
            pendingActionDoor = nil
            openActionDoor(door)
        }
        if let runKey = pendingRoutineRunKey {
            pendingRoutineRunKey = nil
            openRoutineDoor(runKey)
        }
    }

    /// The routine screen behind its 17-gate (Places UI's floor; the door above never
    /// presents below it, so the empty branch is unreachable belt-and-braces).
    @ViewBuilder
    func routineCover(_ run: RoutineRun) -> some View {
        if #available(iOS 17.0, *) {
            PlaceRoutineScreen(
                run: run,
                store: routineRunStore,
                onOpenTab: { selectedTab = $0 },
                onStartSprint: { minutes in
                    let fallback = UserDefaultsMomentumPreferencesStore().read().defaultSprintMinutes
                    startFocus(PlaceActionSprint.plan(minutes: minutes, defaultMinutes: fallback))
                },
                activity: routineActivityPresenter(),
                recorder: FirebaseRoutineRunRecorder()
            )
            // This cover sits ABOVE the root layer, so a celebration started on the routine
            // screen needs a layer of its own to be seen at all (E's ARCH answer).
            .overlay { CelebrationLayer(surface: .routineCover) }
        }
    }
}
