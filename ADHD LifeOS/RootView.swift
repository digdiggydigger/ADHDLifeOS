//
//  RootView.swift
//  ADHD LifeOS
//

import SwiftUI
import UIKit

struct RootView: View {
    @ObservedObject var authService: AuthService
    let homeClient: HomeClientAdapting
    let tasksClient: TasksClientAdapting
    let taskCreateClient: TaskCreateClientAdapting
    let taskDetailClient: TaskDetailClientAdapting
    let captureClient: CaptureClientAdapting
    let nudgesClient: NudgesClientAdapting
    let journalClient: JournalClientAdapting
    let nudgeNotificationSchedulingClient: NudgeNotificationSchedulingAdapting
    let lifeAreaDetailClient: LifeAreaDetailClientAdapting

    /// The capture fan (F-V3-Capture): open = five discs over a scrim; picking one opens the
    /// composer with that kind already chosen. Internal, not private: RootView+Doors mutates
    /// these (the HomeView.arrangeAreas precedent — Swift `private` is file-scoped, and the
    /// door funcs moved out for the 400-line bar).
    @State var isFabOpen = false
    @State var composerKind: CaptureKind?
    /// F-DiscPill: whether a drag is live anywhere in the window, fed by
    /// `CaptureDiscPanObserver`. The disc reads it to choose disc vs pill; `@StateObject` so
    /// the one instance outlives auth-state swaps, matching the observer's once-only install.
    @StateObject private var discScrollActivity = CaptureDiscScrollActivity()
    /// F-Tools-2-Morph: is the tab bar the floating card right now? A POSITION rule — contract
    /// on the way down, hold until the page is back near the top — so it reads scroll offsets
    /// rather than the disc's pan translation. E's device verdict replaced the momentary model
    /// this started as, and E's follow-up answer kept the DISC on its own 2026-08-31 rule.
    @StateObject private var tabBarScrollActivity = TabBarScrollActivity()
    /// F-Search-1-Row: which tab is searchable, what has been typed, and whether the full-screen
    /// surface is open. Owned here because the ROW is app-level — it shares a row with the capture
    /// disc — while each screen presents its own SURFACE, which is where the data lives.
    @StateObject private var searchModel = AppSearchModel()
    /// The tab re-tap rule's meeting point (E, 2026-09-08) — see `TabNavigation.swift`.
    @StateObject private var tabNavigation = TabNavigationCoordinator()
    @State var selectedTab: AppTab = .today  // Internal, not private: RootView+Doors reaches it.
    /// The Captures tab's badge. Held here, not in a sixth `CaptureInboxService`: the tab bar
    /// outlives every screen, and this is one count, not a whole inbox.
    @State private var captureInboxCount = 0
    /// A widget door that arrived before the signed-in tabs existed (dead launch: the URL is
    /// delivered while auth is still restoring). Held here and drained the moment the tabs mount.
    @State var pendingWidgetLink: AppDeepLink?  // Internal: RootView+Doors drains it.
    /// A place-action tap that arrived while signed out or mid-restore — the widget-link
    /// arrangement, for the same cold-launch reason.
    @State var pendingActionDoor: PlaceActionDoor?  // Internal: RootView+Doors drains it.
    /// The live routine screen (F-Routines-3), presented by run so a stale door can never
    /// show a blank screen — `openRoutineDoor` resolves the tapped key against the store
    /// first. Internal: RootView+Doors presents it.
    @State var presentedRoutineRun: RoutineRun?
    /// A routine tap that arrived signed-out or mid-restore — the pending-door pattern.
    @State var pendingRoutineRunKey: UUID?
    /// The doors' read of the one live run. Internal: RootView+Doors resolves against it.
    let routineRunStore: RoutineRunStoring = UserDefaultsRoutineRunStore()
    /// The Settings appearance override — same key both ends, so the picker applies live.
    @AppStorage(AppearancePreference.storageKey) private var appearanceRaw = AppearancePreference.system.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    /// App-level so a running sprint survives tab switches — the web kept it in `useLifeOSState`
    /// for exactly this reason. The factory adds Live Activity mirroring on iOS 16.1+ (§7 gate),
    /// so the countdown also lives on the Lock Screen / Dynamic Island.
    /// Internal, not private: RootView+Doors' sprint door starts it.
    @StateObject var focusService = FocusSessionService.withLiveActivityMirroring(
        logger: FirebaseFocusSessionAdapter()
    )

    /// The pill is a STICKY scrolled-down state (F-PillStay, E's call 2026-08-31: "stay in
    /// pill form until the page is scrolled upwards again"). An open fan forces the full disc:
    /// its scrim blocks scrolling anyway, and the ✕ rotation reads as a disc, not a sliver.
    private var showsPill: Bool {
        discScrollActivity.prefersPill && !isFabOpen
    }

    /// Every sprint-start path (card button, detail-screen launch row) funnels here, so the
    /// success haptic the web fires on start (`triggerHaptic('success')`) happens exactly once
    /// per launch.
    func startFocus(_ plan: FocusSprintPlan) {  // Internal, not private: the sprint door calls it.
        Haptics.play(.success)
        focusService.start(plan: plan)
    }

    /// The tab badge's one writer. A failure leaves the previous number standing rather than
    /// dropping to zero: an offline moment is not an empty inbox.
    private func refreshCaptureInboxCount() async {
        guard let captures = try? await captureClient.fetchUnprocessedCaptures() else { return }
        captureInboxCount = captures.count
    }

    var body: some View {
        Group {
            switch authService.state {
            case .unknown:
                ProgressView()
            case .signedOut, .linkSent:
                LoginView(authService: authService)
            case .signedIn:
                AppTabContent(selection: selectedTab) { tab in
                    // Exhaustive over `AppTab`, so the compiler — not a grep — is what
                    // guarantees every slot on the bar has a screen behind it.
                    switch tab {
                    case .today:
                        // "Today" with v3's trending-up glyph — the Momentum v3 tab identity.
                        HomeView(
                            authService: authService,
                            homeClient: homeClient,
                            captureClient: captureClient,
                            journalClient: journalClient,
                            nudgesClient: nudgesClient,
                            nudgeNotificationSchedulingClient: nudgeNotificationSchedulingClient,
                            lifeAreaDetailClient: lifeAreaDetailClient,
                            taskDetailClient: taskDetailClient,
                            onStartFocus: startFocus,
                            focusReloadToken: focusService.completedSprintCount,
                            activeSprint: focusService.session.map {
                                ActiveSprintStatus(taskId: $0.taskId, isPaused: $0.isPaused)
                            },
                            widgetSprint: focusService.widgetSprint,
                            onToggleSprintPause: { focusService.togglePause() },
                            onOpenCaptures: { selectedTab = .captures },
                            taskCreateClient: taskCreateClient
                        )
                    case .tasks:
                        TaskListView(
                            tasksClient: tasksClient,
                            taskCreateClient: taskCreateClient,
                            taskDetailClient: taskDetailClient,
                            onStartFocus: startFocus
                        )
                    case .areas:
                        // Areas took the Captures slot in F-V3-Areas; the interim "Handled
                        // captures" door it carried is gone now that Captures has its own again.
                        AreasView(
                            authService: authService,
                            homeClient: homeClient,
                            journalClient: journalClient,
                            captureClient: captureClient,
                            lifeAreaDetailClient: lifeAreaDetailClient,
                            taskDetailClient: taskDetailClient,
                            onStartFocus: startFocus,
                            taskCreateClient: taskCreateClient,
                            onOpenCaptures: { selectedTab = .captures }
                        )
                    case .journal:
                        JournalView(
                            client: journalClient,
                            homeClient: homeClient,
                            captureClient: captureClient,
                            taskDetailClient: taskDetailClient,
                            onStartFocus: startFocus
                        )
                    case .captures:
                        // Captures, home at last (E's round-2 call, 2026-08-28). Nudges gave up
                        // this slot and became a section on Today, where a due one is now
                        // dismissed inline — more than the teaser row it had here could do.
                        // `NudgesView` survives, pushed from that section, holding everything a
                        // section cannot: create, edit, reschedule, history. Its count rides the
                        // bar's badge; `AppTabBarPresentation` keeps `.badge(0)`'s silence.
                        NavigationStack {
                            CaptureInboxView(
                                client: captureClient,
                                journalClient: journalClient,
                                homeClient: homeClient
                            )
                        }
                    case .tools:
                        // The sixth station (F-Tools-1-Bar), filled in F-Tools-3-Page: bento
                        // doors to Places and the Life Areas editor, and nothing else — E wants
                        // the page sparse so Routines has somewhere obvious to land.
                        //
                        // No clients threaded from here on purpose: `RootView` never held these
                        // two (`SettingsView` constructed them itself), so `ToolsView` takes them
                        // through the same default-param door rather than adding two properties
                        // to this file and the App to pass through.
                        ToolsView()
                    }
                }
                // E's 2026-08-27 call: the tab bar ticks with a light impact rather than the
                // iOS-conventional selection tick. Fires on the SELECTION, so a programmatic
                // switch (a widget door, "See nudges") buzzes too — those are still a tab change
                // from under the user's thumb.
                .haptic(HapticFeel.tabChange, trigger: selectedTab)
                // F-PillStay's one non-scroll restore: a fresh tab starts with the full disc —
                // a sticky pill over a page the user never scrolled reads as a bug. (Judgment
                // call beyond E's stated rule; E can veto.)
                .onChange(of: selectedTab) { tab in
                    discScrollActivity.reset()
                    tabBarScrollActivity.reset()
                    // Driven from the SELECTION, not from each screen's `onAppear`.
                    // `AppTabContent` keeps every visited tab alive, so appearance callbacks fire
                    // once and then effectively never again — a screen registering its own scope
                    // would leave whichever tab registered last in charge forever.
                    searchModel.activate(AppSearchScope.scope(for: tab))
                }
                // Our bar, in the space the system's used to occupy. A bottom safe-area INSET:
                // it positions the bar correctly, insets every scroll view so the last row still
                // clears it, and — the point of E's last verdict — leaves the content itself
                // full height, so the page scrolls BEHIND the bar rather than stopping at a
                // reserved strip.
                //
                // The two screens that pin their own bottom furniture inside a `NavigationStack`
                // do not inherit this (a SwiftUI inset does not cross that boundary) and ask for
                // the room with `appTabBarClearance()` instead.
                //
                // Placed above `.blur` deliberately: the bar dims with the content when the
                // capture fan opens, the way the system bar did.
                //
                // There is no system bar to hide any more — `AppTabContent` is not a
                // `UITabBarController`, which is the whole reason a sixth tab is possible at
                // all. See that file for what `TabView` did to tabs five and six.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    AppTabBar(
                        selection: $selectedTab,
                        captureInboxCount: captureInboxCount,
                        isFloating: tabBarScrollActivity.isFloating,
                        onReselect: { tabNavigation.reselect($0) }
                    )
                }
                .blur(radius: isFabOpen ? 4 : 0)
                .overlay {
                    if isFabOpen {
                        CaptureFanOverlay(
                            onPick: { kind in
                                isFabOpen = false
                                composerKind = kind
                            },
                            onDismiss: { isFabOpen = false }
                        )
                        .transition(.opacity)
                    }
                }
                // The app's persistent bottom furniture — the capture disc, an unacknowledged
                // sprint summary, the running timer — in its own file since F-Tools-1-Bar.
                // Applied AFTER the tab bar's safe-area inset, so `.bottom` still means "the top
                // of the bar" and the disc sits exactly where it always has.
                .overlay(alignment: .bottom) {
                    RootBottomOverlay(
                        isFabOpen: $isFabOpen,
                        showsPill: showsPill,
                        focusService: focusService,
                        searchScope: searchModel.scope,
                        onOpenSearch: { searchModel.open() }
                    )
                }
                .fullScreenCover(item: $presentedRoutineRun) { run in
                    routineCover(run)
                }
                .fullScreenCover(item: $composerKind) { kind in
                    QuickCaptureView(
                        client: captureClient,
                        kind: kind,
                        homeClient: homeClient,
                        taskCreateClient: taskCreateClient,
                        taskDetailClient: taskDetailClient
                    ) {}
                    .keyboardDismissal()
                }
                // Reinstate a sprint the process died holding (F-SprintPersistence). Idempotent —
                // a no-op with nothing stored or a sprint already live.
                .task {
                    await focusService.restorePersistedSprint()
                }
                .environmentObject(searchModel)
                .environmentObject(tabNavigation)
                .task { await refreshCaptureInboxCount() }
                // Any capture written, sorted, promoted or binned anywhere in the app moves this
                // number — the same signal every other screen reloads on.
                .onReceive(DataChangeSignal.changes) { _ in
                    Task { await refreshCaptureInboxCount() }
                }
                // Drain a widget door that arrived before these tabs existed. Deliberately a state
                // change AFTER mount: presenting the composer by pre-set state on first render is
                // the flaky path; a post-mount change presents reliably.
                .task { drainPendingDoors() }
                .preferredColorScheme(
                    (AppearancePreference(rawValue: appearanceRaw) ?? .system).colorScheme
                )
                // A finished sprint's history write is best-effort, but its failure must not be
                // SILENT (found 2026-08-19: `logErrorMessage` was set and displayed nowhere) —
                // same alert pattern as the task list's mutation errors. The sprint itself ended
                // cleanly; only the history record is affected.
                .alert(
                    "Focus session couldn't be saved",
                    isPresented: Binding(
                        get: { focusService.logErrorMessage != nil },
                        set: { if !$0 { focusService.logErrorMessage = nil } }
                    )
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(focusService.logErrorMessage ?? "")
                }
                // b5: one application covers the tabs and every screen pushed inside them; the
                // modal composers wrap their own roots at their presentation sites.
                //
                // Applied to the TABS rather than to the Group around them, so the LOGIN screen
                // does not inherit a Done bar (E, on device 2026-08-30: "it's clogging the screen
                // up"). That does not reopen b5 — `KeyboardTapAway` is installed window-level and
                // already covers login, and its own note says tapping away is "the gesture people
                // actually reach for". The bar was redundant there, not load-bearing.
                .keyboardDismissal()
            }
        }
        // b5 round two: tap anywhere that isn't a text field to dismiss — one window-level
        // recognizer covers every screen INCLUDING sheets and covers (same UIWindow), so this
        // is the only install site. Idempotent across auth-state swaps.
        .onAppear {
            KeyboardTapAway.installOnKeyWindow()
            // The pill's scroll detector: same install site, same lifetime, same window-level
            // pattern. The callbacks capture the `@StateObject` model, the one object that
            // outlives every auth-state swap this onAppear can re-fire across.
            //
            // `installOnKeyWindow` is idempotent (`guard shared == nil`) and **the FIRST
            // install's callbacks win** — a second call silently no-ops, so a consumer that
            // needed different information could not simply install again.
            CaptureDiscPanObserver.installOnKeyWindow(
                onDragBegan: discScrollActivity.dragBegan,
                onDragMoved: discScrollActivity.dragMoved
            )
            // The bar's rule is about POSITION, not gesture — hold the floating card until the
            // page is back near the top — so it needs offsets the disc's pan observer does not
            // carry. Same window-level, zero-per-screen-wiring shape; separate object because
            // the disc's observer is settled and forwards no touch location.
            AppScrollOffsetObserver.installOnKeyWindow { distance in
                tabBarScrollActivity.offsetChanged(distanceFromTop: distance)
            }
        }
        // Login ↔ tabs swap on a spring instead of a hard cut, so a successful Sign in with
        // Apple (or password sign-in) lands on Home gracefully (§5).
        .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: authService.state)
        // The widget doors (E's 2026-08-25 note; cold-launch fix 2026-08-26). Mounted on the
        // Group — not the TabView — because a dead launch delivers the URL while auth is still
        // restoring, when the tabs don't exist yet. Fires for EVERY URL alongside the App-level
        // auth handler; each ignores what isn't theirs.
        .onOpenURL { url in
            let link = AppDeepLink.route(url)
            guard link.requiresSignedInUI else { return }
            if case .signedIn = authService.state {
                openWidgetDoor(link)
            } else {
                pendingWidgetLink = link
            }
        }
        .task {
            // Place-action doors: replay-on-connect, pending-while-signed-out (widget-link rules).
            PlaceActionNotificationRouter.shared.connect { door in
                if case .signedIn = authService.state { openActionDoor(door) } else { pendingActionDoor = door }
            }
            PlaceRoutineNotificationRouter.shared.connect { runKey in
                if case .signedIn = authService.state {
                    openRoutineDoor(runKey)
                } else if let runKey {
                    // A broken tap has nothing to hold — the app is opening onto Today anyway.
                    pendingRoutineRunKey = runKey
                }
            }
            if authService.state == .unknown {
                await authService.restoreSession()
            }
            // F-V3-Tasks-rebuild: the per-task nudge feature is gone, so sweep anything it
            // scheduled before its removal — nothing left in the app could ever cancel it.
            await LegacyTaskNotificationCleanup.run()
            // Block 4b: settle the geofences against the saved places on every launch.
            // Idempotent — registering the same identifier replaces, never duplicates.
            await LocationTriggerService.shared.refreshRegistrations()
        }
        // A place edit (or the Settings master switch) lands through the shared write plumbing
        // like every other mutation; the fences follow it without waiting for a relaunch. Cheap
        // when triggering is off or ungranted — the service's gate fails before any fetch.
        .onReceive(DataChangeSignal.changes) { _ in
            Task { await LocationTriggerService.shared.refreshRegistrations() }
        }
        // Returning to the app settles a sprint whose countdown ran out behind a locked screen: the
        // ticker is suspended with the app, so without this the finished sprint stayed "running" —
        // and its Live Activity stayed on the Lock Screen at 0:00, complete with live Pause/Stop
        // buttons — until the next ticker beat (E's bug, 2026-08-20).
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                focusService.syncNow()
                // Foregrounding is also the moment a fresh Always grant (given in Settings while
                // we were backgrounded) can finally register its fences.
                Task { await LocationTriggerService.shared.refreshRegistrations() }
            }
        }
    }
}
