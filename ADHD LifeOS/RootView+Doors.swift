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

    /// What the capture disc's full-screen composer presents for a kind.
    ///
    /// `F-D1-ComposerBothDoors`, E's round 6: *"One composer, both doors"* — the Task tile opens
    /// the SAME composer as the Tasks "+", here as a cover and there as a sheet, which the doors
    /// inherited rather than chose. The widget's `.captureComposer` door routes through
    /// `composerKind` too (`openWidgetDoor`, below), so it lands here with no change of its own.
    /// `ComposerBothDoorsCallSiteTests` pins every seam each branch is handed.
    @ViewBuilder
    func composer(for kind: CaptureKind) -> some View {
        if kind == .task {
            TaskCreateView(
                client: taskCreateClient,
                taskDetailClient: taskDetailClient,
                homeClient: homeClient,
                captureClient: captureClient
            ) {}
            .keyboardDismissal()
        } else {
            QuickCaptureView(client: captureClient, kind: kind, homeClient: homeClient) {}
                .keyboardDismissal()
        }
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

    /// The SHARED instance: this factory is called from a `@ViewBuilder`, so a fresh presenter
    /// here would be replaced on every re-render — along with its handle to the running
    /// Activity. Always the real presenter since `F-Floor18` (ActivityKit sits below the 18
    /// floor); `InertRoutineActivityPresenter` remains for previews only.
    func routineActivityPresenter() -> RoutineActivityPresenting {
        RoutineActivityKitPresenter.shared
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

    /// The Captures tab, and the one screen that can answer `openCaptureDoor` below.
    ///
    /// **Out of `RootView.body` because that file is AT SwiftLint's 400-line ceiling**, which is
    /// the same pressure that created this file. The binding is what lets the door work: the door
    /// parks a capture id, this screen takes it when it mounts and clears it, exactly as
    /// `drainPendingDoors` does for the other three.
    @ViewBuilder
    var capturesTab: some View {
        NavigationStack {
            CaptureInboxView(
                client: captureClient,
                journalClient: journalClient,
                homeClient: homeClient,
                celebrate: celebrationCenter,
                pendingCaptureToInspect: $pendingCaptureToInspect
            )
        }
    }

    /// **`F-C2-DraftsToInbox`'s door: a filed draft's "Reopen".** E's Step 0 answer 1: *"Open it
    /// in the inbox (Recommended)"* — chosen over reopening the composer because it is
    /// composer-agnostic and survives arc D's composer unification unchanged.
    ///
    /// **It lives with the other doors rather than in `RootView.body` for one blunt reason:**
    /// `RootView.swift` sits within a couple of lines of SwiftLint's 400-line ceiling, which is
    /// why this file exists at all. It is also genuinely the same shape as the three doors above —
    /// something outside the tabs asking for a tab, with a slot the destination drains when it
    /// mounts.
    ///
    /// Unlike them it takes no signed-in check: the only thing that can call it is a composer,
    /// and a composer is only reachable from inside the signed-in tabs.
    func openCaptureDoor(_ captureId: UUID) {
        pendingCaptureToInspect = captureId
        selectedTab = .captures
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
                recorder: FirebaseRoutineRunRecorder(),
                // E's R4: the greeting says the ACCOUNT display name, the one Settings' account
                // row shows — not the routine's. Defaulted `nil` on the screen, so forgetting it
                // here would compile and greet everyone anonymously; `RoutineRecordCallSiteTests`
                // reads this line for exactly that reason.
                displayName: authService.signedInUser?.displayName,
                history: FirebaseRoutineRunHistoryAdapter()
            )
            // This cover sits ABOVE the root layer, so a celebration started on the routine
            // screen needs a layer of its own to be seen at all (E's ARCH answer).
            .overlay { CelebrationLayer(surface: .routineCover) }
        }
    }
}
