//
//  RootView.swift
//  ADHD LifeOS
//

import SwiftUI
import UIKit

/// The tab bar's stations under the hybrid v3 IA (E's call, 2026-08-24): five tabs stay, and
/// selection is state so screens can cross tabs (Today's "Nudges waiting" row → Nudges).
enum AppTab: Hashable {
    case today, tasks, areas, journal, nudges
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
    let taskCountdownNudgeSchedulingClient: TaskCountdownNudgeSchedulingAdapting
    let nudgeNotificationSchedulingClient: NudgeNotificationSchedulingAdapting
    let lifeAreaDetailClient: LifeAreaDetailClientAdapting

    /// The capture fan (F-V3-Capture): open = five discs over a scrim; picking one opens the
    /// composer with that kind already chosen.
    @State private var isFabOpen = false
    @State private var composerKind: CaptureKind?
    @State private var selectedTab: AppTab = .today
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

    /// Every sprint-start path (card button, detail-screen launch row) funnels here, so the
    /// success haptic the web fires on start (`triggerHaptic('success')`) happens exactly once
    /// per launch. `.sensoryFeedback` is iOS 17+, hence the UIKit generator (same §7 precedent
    /// as `saveSuccessHaptic`).
    private func startFocus(_ plan: FocusSprintPlan) {
        if AppFeedback.hapticsEnabled() {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        focusService.start(plan: plan)
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
                        schedulingClient: taskCountdownNudgeSchedulingClient,
                        onStartFocus: startFocus,
                        focusReloadToken: focusService.completedSprintCount,
                        activeSprint: focusService.session.map {
                            ActiveSprintStatus(taskId: $0.taskId, isPaused: $0.isPaused)
                        },
                        widgetSprint: focusService.widgetSprint,
                        onToggleSprintPause: { focusService.togglePause() },
                        onOpenNudges: { selectedTab = .nudges },
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
                        schedulingClient: taskCountdownNudgeSchedulingClient,
                        onStartFocus: startFocus
                    )
                        .tabItem { Label("Tasks", systemImage: "checklist") }
                        .tag(AppTab.tasks)
                    // The Captures slot became Areas in F-V3-Areas (hybrid IA, E's call):
                    // the archive of handled captures stays reachable through Areas' interim
                    // "Handled captures" door until V3-Inbox houses it properly.
                    AreasView(
                        authService: authService,
                        homeClient: homeClient,
                        journalClient: journalClient,
                        captureClient: captureClient,
                        lifeAreaDetailClient: lifeAreaDetailClient,
                        taskDetailClient: taskDetailClient,
                        schedulingClient: taskCountdownNudgeSchedulingClient,
                        onStartFocus: startFocus,
                        taskCreateClient: taskCreateClient
                    )
                        .tabItem { Label("Areas", systemImage: "square.grid.2x2") }
                        .tag(AppTab.areas)
                    JournalView(
                        client: journalClient,
                        homeClient: homeClient,
                        captureClient: captureClient,
                        taskDetailClient: taskDetailClient,
                        schedulingClient: taskCountdownNudgeSchedulingClient,
                        onStartFocus: startFocus
                    )
                        .tabItem { Label("Journal", systemImage: "book") }
                        .tag(AppTab.journal)
                    // Tab swap reverted (E, 2026-08-19): Nudges is back, Reminders removed — its
                    // Poke/DynamoDB source didn't survive the Firebase cutover, so the tab only
                    // ever showed an empty list. The Reminders feature files stay compiled but
                    // dormant, the same arrangement Nudges had during the 2026-07-22 swap.
                    NavigationStack {
                        NudgesView(
                            client: nudgesClient,
                            notificationSchedulingClient: nudgeNotificationSchedulingClient
                        )
                    }
                        .tabItem { Label("Nudges", systemImage: "bell") }
                        .tag(AppTab.nudges)
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
                            // v3's capture disc: a 60pt solid circle with the motion-blue glow,
                            // not a bare SF glyph — the fan leans out of THIS.
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(AreaPalette.work.onColor)
                                .frame(width: 60, height: 60)
                                .background(Color.accentColor, in: Circle())
                                .shadow(color: Color.accentColor.opacity(0.5), radius: 12, x: 0, y: 8)
                                .rotationEffect(.degrees(isFabOpen ? 135 : 0))
                                .contentShape(Circle())
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
            }
        }
        // b5: one application covers the tabs and every screen pushed inside them; the modal
        // composers wrap their own roots at their presentation sites.
        .keyboardDismissal()
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
        }
        // Returning to the app settles a sprint whose countdown ran out behind a locked screen: the
        // ticker is suspended with the app, so without this the finished sprint stayed "running" —
        // and its Live Activity stayed on the Lock Screen at 0:00, complete with live Pause/Stop
        // buttons — until the next ticker beat (E's bug, 2026-08-20).
        .onChange(of: scenePhase) { phase in
            if phase == .active { focusService.syncNow() }
        }
    }
}
