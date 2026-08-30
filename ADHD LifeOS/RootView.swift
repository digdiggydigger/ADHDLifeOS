//
//  RootView.swift
//  ADHD LifeOS
//

import SwiftUI
import UIKit

/// The tab bar's stations under the hybrid v3 IA (E's call, 2026-08-24): five tabs stay, and
/// selection is state so screens can cross tabs (Today's inbox card → Captures).
///
/// The fifth slot changed hands on 2026-08-28 (round 2 of E's captures rethink). Nudges held it
/// and became a section on Today; **Captures** took it back, having lost it to Areas in
/// F-V3-Areas and spent the interim as a pushed guest screen behind five separate doors. Five
/// stays five: iOS gives five slots before a "More" tab, and a sixth would bury one of these.
enum AppTab: Hashable {
    case today, tasks, areas, journal, captures
}

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
    /// composer with that kind already chosen.
    @State private var isFabOpen = false
    @State private var composerKind: CaptureKind?
    /// F-DiscPill: whether a drag is live anywhere in the window, fed by
    /// `CaptureDiscPanObserver`. The disc reads it to choose disc vs pill; `@StateObject` so
    /// the one instance outlives auth-state swaps, matching the observer's once-only install.
    @StateObject private var discScrollActivity = CaptureDiscScrollActivity()
    @State private var selectedTab: AppTab = .today
    /// The Captures tab's badge. Held here, not in a sixth `CaptureInboxService`: the tab bar
    /// outlives every screen, and this is one count, not a whole inbox.
    @State private var captureInboxCount = 0
    /// A widget door that arrived before the signed-in tabs existed (dead launch: the URL is
    /// delivered while auth is still restoring). Held here and drained the moment the tabs mount.
    @State private var pendingWidgetLink: AppDeepLink?
    /// The Settings appearance override — same key both ends, so the picker applies live.
    @AppStorage(AppearancePreference.storageKey) private var appearanceRaw = AppearancePreference.system.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    /// App-level so a running sprint survives tab switches — the web kept it in `useLifeOSState`
    /// for exactly this reason. The factory adds Live Activity mirroring on iOS 16.1+ (§7 gate),
    /// so the countdown also lives on the Lock Screen / Dynamic Island.
    @StateObject private var focusService = FocusSessionService.withLiveActivityMirroring(
        logger: FirebaseFocusSessionAdapter()
    )

    /// The pill is a MID-SCROLL state (F-DiscPill, E's call 2026-08-30: "shrink the disc to a
    /// small pill while scrolling"). An open fan forces the full disc: its scrim blocks
    /// scrolling anyway, and the ✕ rotation reads as a disc, not a sliver.
    private var showsPill: Bool {
        discScrollActivity.isScrolling && !isFabOpen
    }

    /// Every sprint-start path (card button, detail-screen launch row) funnels here, so the
    /// success haptic the web fires on start (`triggerHaptic('success')`) happens exactly once
    /// per launch.
    private func startFocus(_ plan: FocusSprintPlan) {
        Haptics.play(.success)
        focusService.start(plan: plan)
    }

    /// The tab badge's one writer. A failure leaves the previous number standing rather than
    /// dropping to zero: an offline moment is not an empty inbox.
    private func refreshCaptureInboxCount() async {
        guard let captures = try? await captureClient.fetchUnprocessedCaptures() else { return }
        captureInboxCount = captures.count
    }

    /// The widget doors' one entry point — called immediately when the tabs are on screen, and
    /// as the drain for a link that had to wait out a cold launch.
    private func openWidgetDoor(_ link: AppDeepLink) {
        switch link {
        case .areasTab:
            selectedTab = .areas
        case .captureComposer(let kind):
            isFabOpen = false
            composerKind = kind
        case .authCallback, .focusWidget:
            break
        }
    }

    var body: some View {
        Group {
            switch authService.state {
            case .unknown:
                ProgressView()
            case .signedOut, .linkSent:
                LoginView(authService: authService)
            case .signedIn:
                TabView(selection: $selectedTab) {
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
                        // "Today" with v3's trending-up glyph — the Momentum v3 tab identity. The Captures
                        // slot becomes Areas in the V3-Areas block; the rest keep their glyphs.
                        .tabItem { Label("Today", systemImage: "chart.line.uptrend.xyaxis") }
                        .tag(AppTab.today)
                    TaskListView(
                        tasksClient: tasksClient,
                        taskCreateClient: taskCreateClient,
                        taskDetailClient: taskDetailClient,
                        onStartFocus: startFocus
                    )
                        .tabItem { Label("Tasks", systemImage: "checklist") }
                        .tag(AppTab.tasks)
                    // Areas took the Captures slot in F-V3-Areas; the interim "Handled captures"
                    // door it carried is gone now that Captures has a slot of its own again.
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
                        .tabItem { Label("Areas", systemImage: "square.grid.2x2") }
                        .tag(AppTab.areas)
                    JournalView(
                        client: journalClient,
                        homeClient: homeClient,
                        captureClient: captureClient,
                        taskDetailClient: taskDetailClient,
                        onStartFocus: startFocus
                    )
                        .tabItem { Label("Journal", systemImage: "book") }
                        .tag(AppTab.journal)
                    // Captures, home at last (E's round-2 call, 2026-08-28). Nudges gave up this
                    // slot and became a section on Today, where a due one is now dismissed inline
                    // — more than the teaser row it had here could do. `NudgesView` survives,
                    // pushed from that section, holding everything a section cannot: create,
                    // edit, reschedule, history.
                    NavigationStack {
                        CaptureInboxView(
                            client: captureClient,
                            journalClient: journalClient,
                            homeClient: homeClient
                        )
                    }
                        .tabItem { Label("Captures", systemImage: "tray.full") }
                        // The count the Areas and Today tray wells used to carry, in the one place
                        // that outlives them. `.badge(0)` renders nothing, so an empty inbox is
                        // silent rather than a zero — and a failed refresh keeps the last known
                        // number instead of claiming zero (never having looked ≠ nothing there).
                        .badge(captureInboxCount)
                        .tag(AppTab.captures)
                }
                // E's 2026-08-27 call: the tab bar ticks with a light impact rather than the
                // iOS-conventional selection tick. Fires on the SELECTION, so a programmatic
                // switch (a widget door, "See nudges") buzzes too — those are still a tab change
                // from under the user's thumb.
                .haptic(HapticFeel.tabChange, trigger: selectedTab)
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
                .overlay(alignment: .bottom) {
                    // Sits above the tab bar, mirroring the web's `fixed bottom-24` placement.
                    // The FAB shares this stack so an active sprint pushes it ABOVE the timer
                    // bar instead of letting it occlude the bar's controls (E, 2026-08-19).
                    VStack(alignment: .trailing, spacing: 8) {
                        Button {
                            withAnimation(
                                reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8)
                            ) {
                                isFabOpen.toggle()
                            }
                        } label: {
                            CaptureDiscLabel(isFabOpen: isFabOpen, showsPill: showsPill)
                        }
                        .padding(.trailing, 16)
                        .accessibilityLabel(isFabOpen ? "Close capture fan" : "Capture something")
                        .accessibilityIdentifier("quickCaptureButton")

                        // A sprint that finished while the app was dead announces itself here —
                        // above the tab bar on every tab, gone only when acknowledged.
                        if let summary = focusService.offlineCompletionSummary {
                            OfflineSprintSummaryCard(record: summary) {
                                focusService.acknowledgeOfflineCompletion()
                            }
                            .padding(.horizontal, 16)
                        }

                        FocusTimerBar(service: focusService)
                    }
                    // Full width with trailing alignment: with no timer bar the stack used to
                    // shrink to the disc and the .bottom overlay CENTRED it mid-screen (E's
                    // position review, 2026-08-25). Trailing-pinned, ~12pt above the tab bar.
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom, 52)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8),
                        value: focusService.isActive
                    )
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
                .task { await refreshCaptureInboxCount() }
                // Any capture written, sorted, promoted or binned anywhere in the app moves this
                // number — the same signal every other screen reloads on.
                .onReceive(DataChangeSignal.debouncedPublisher()) { _ in
                    Task { await refreshCaptureInboxCount() }
                }
                // Drain a widget door that arrived before these tabs existed. Deliberately a state
                // change AFTER mount: presenting the composer by pre-set state on first render is
                // the flaky path; a post-mount change presents reliably.
                .task {
                    if let link = pendingWidgetLink {
                        pendingWidgetLink = nil
                        openWidgetDoor(link)
                    }
                }
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
            // F-DiscPill's scroll detector: same install site, same lifetime, same window-level
            // pattern. The callbacks capture the `@StateObject` model, the one object that
            // outlives every auth-state swap this onAppear can re-fire across.
            CaptureDiscPanObserver.installOnKeyWindow(
                onDragBegan: discScrollActivity.dragBegan,
                onDragEnded: discScrollActivity.dragEnded
            )
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
        .onReceive(DataChangeSignal.debouncedPublisher()) { _ in
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
