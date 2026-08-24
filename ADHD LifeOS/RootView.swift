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
    let taskCountdownNudgeSchedulingClient: TaskCountdownNudgeSchedulingAdapting
    let nudgeNotificationSchedulingClient: NudgeNotificationSchedulingAdapting
    let lifeAreaDetailClient: LifeAreaDetailClientAdapting

    @State private var isPresentingQuickCapture = false
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
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        focusService.start(plan: plan)
    }

    var body: some View {
        Group {
            switch authService.state {
            case .unknown:
                ProgressView()
            case .signedOut, .linkSent:
                LoginView(authService: authService)
            case .signedIn:
                TabView {
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
                        onToggleSprintPause: { focusService.togglePause() }
                    )
                        // "Today" with v3's trending-up glyph — the Momentum v3 tab identity. The Captures
                        // slot becomes Areas in the V3-Areas block; the rest keep their glyphs.
                        .tabItem { Label("Today", systemImage: "chart.line.uptrend.xyaxis") }
                    TaskListView(
                        tasksClient: tasksClient,
                        taskCreateClient: taskCreateClient,
                        taskDetailClient: taskDetailClient,
                        schedulingClient: taskCountdownNudgeSchedulingClient,
                        onStartFocus: startFocus
                    )
                        .tabItem { Label("Tasks", systemImage: "checklist") }
                    // Captures joined the bar 2026-08-23 (E's Captures-tab direction): the
                    // archive of handled captures — Seen and Promoted — while the Inbox (reached
                    // from Home) became purely the to-triage queue. Stack wrapped at the call
                    // site, the Nudges precedent below.
                    NavigationStack {
                        CapturesTabView(
                            client: captureClient,
                            journalClient: journalClient,
                            homeClient: homeClient
                        )
                    }
                        .tabItem { Label("Captures", systemImage: "tray.full") }
                    JournalView(client: journalClient)
                        .tabItem { Label("Journal", systemImage: "book") }
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
                }
                .overlay(alignment: .bottom) {
                    // Sits above the tab bar, mirroring the web's `fixed bottom-24` placement.
                    // The quick-capture button shares this stack so an active sprint pushes it
                    // ABOVE the timer bar instead of letting it occlude the bar's controls
                    // (E's bug report, 2026-08-19).
                    VStack(alignment: .trailing, spacing: 8) {
                        Button {
                            isPresentingQuickCapture = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 48))
                        }
                        .padding(.trailing, 20)
                        .accessibilityIdentifier("quickCaptureButton")

                        FocusTimerBar(service: focusService)
                    }
                    .padding(.bottom, 60)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8),
                        value: focusService.isActive
                    )
                }
                .sheet(isPresented: $isPresentingQuickCapture) {
                    QuickCaptureView(client: captureClient) {}
                }
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
        // Login ↔ tabs swap on a spring instead of a hard cut, so a successful Sign in with
        // Apple (or password sign-in) lands on Home gracefully (§5).
        .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: authService.state)
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

#Preview {
    struct PreviewAuthClient: AuthClientAdapting {
        func restoredUser() async -> AuthUser? { nil }
        func signIn(email: String, password: String) async throws -> AuthUser { fatalError("unused in preview") }
        func requestOTP(email: String, redirectTo: URL?) async throws {}
        func completeSession(from url: URL) async throws -> AuthUser { fatalError("unused in preview") }
        func signOut() async throws {}
        func validIDToken() async throws -> String { "preview-token" }
        func signInWithApple(idToken: String, rawNonce: String, displayName: String?) async throws -> AuthUser {
            fatalError("unused in preview")
        }
    }

    struct PreviewHomeClient: HomeClientAdapting {
    func fetchAllTasks() async throws -> [TaskItem] { [] }
        func fetchLifeAreas() async throws -> [LifeArea] { [] }
        func fetchOpenTasks() async throws -> [TaskSummary] { [] }
        func reorder(order: [UUID]) async throws {}
    }

    struct PreviewTasksClient: TasksClientAdapting {
        func fetchLifeAreas() async throws -> [LifeArea] { [] }
        func fetchAllTasks() async throws -> [TaskItem] { [] }
        func setStatus(taskId: UUID, status: TaskStatus) async throws {}
        func deleteTask(taskId: UUID) async throws {}
    }

    struct PreviewTaskCreateClient: TaskCreateClientAdapting {
        func fetchTags() async throws -> [Tag] { [] }
        func createTag(name: String) async throws -> Tag { fatalError("unused in preview") }
        func createTask(_ input: NormalizedCreateTaskInput) async throws -> TaskItem { fatalError("unused in preview") }
        func attachTags(taskId: UUID, tagIds: [UUID]) async throws {}
    }

    struct PreviewTaskDetailClient: TaskDetailClientAdapting {
        func fetchTask(id: UUID) async throws -> TaskDetail { fatalError("unused in preview") }
        func fetchTagsForTask(taskId: UUID) async throws -> [Tag] { [] }
        func fetchAllTags() async throws -> [Tag] { [] }
        func updateTask(id: UUID, payload: TaskUpdatePayload) async throws -> TaskDetail {
            fatalError("unused in preview")
        }
        func updateStatus(id: UUID, status: TaskStatus) async throws -> TaskDetail { fatalError("unused in preview") }
        func createTag(name: String) async throws -> Tag { fatalError("unused in preview") }
        func addTagToTask(taskId: UUID, tagId: UUID) async throws {}
        func removeTagFromTask(taskId: UUID, tagId: UUID) async throws {}
    }

    struct PreviewCaptureClient: CaptureClientAdapting {
        func createCapture(_ input: NormalizedCreateCaptureInput) async throws -> Capture {
            fatalError("unused in preview")
        }
        func fetchUnprocessedCaptures() async throws -> [Capture] { [] }
        func fetchCaptures() async throws -> [Capture] { [] }
        func fetchCapture(id: UUID) async throws -> Capture { fatalError("unused in preview") }
        func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
            fatalError("unused in preview")
        }
        func markProcessed(captureId: UUID) async throws {}
        func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
            fatalError("unused in preview")
        }

    func fetchProcessedCaptures() async throws -> [Capture] { [] }
    func fetchSeenCaptures() async throws -> [Capture] { [] }
    func deleteCapture(id: UUID) async throws {}
        func uploadMedia(to uploadURL: URL, data: Data, contentType: String) async throws {}
        func updateCapture(id: UUID, changes: CaptureUpdate) async throws -> Capture {
            fatalError("unused in preview")
        }
        func fetchAllTags() async throws -> [Tag] { [] }
        func createTag(name: String) async throws -> Tag { fatalError("unused in preview") }
        func fetchTags(captureId: UUID) async throws -> [Tag] { [] }
        func addTag(captureId: UUID, tagId: UUID) async throws {}
        func removeTag(captureId: UUID, tagId: UUID) async throws {}
    }

    struct PreviewNudgesClient: NudgesClientAdapting {
        func fetchNudges() async throws -> [Nudge] { [] }
        func createNudge(label: String, schedule: NudgeSchedule) async throws -> Nudge {
            fatalError("unused in preview")
        }
        func updateNudge(id: UUID, payload: NudgeUpdatePayload) async throws -> Nudge {
            fatalError("unused in preview")
        }
        func markFired(id: UUID) async throws -> Nudge { fatalError("unused in preview") }
    }

    struct PreviewJournalClient: JournalClientAdapting {
        func fetchLifeAreas() async throws -> [LifeArea] { [] }
        func fetchLogs() async throws -> [Log] { [] }
        func createLog(_ input: NormalizedCreateLogInput) async throws -> Log { fatalError("unused in preview") }
    }

    struct PreviewNudgeSchedulingClient: TaskCountdownNudgeSchedulingAdapting {
        func requestAuthorizationIfNeeded() async -> Bool { false }
        func scheduleNudges(taskId: UUID, taskTitle: String, fireDates: [ScheduledCountdownNudge]) async {}
        func cancelNudges(taskId: UUID) async {}
        func hasScheduledNudges(taskId: UUID) async -> Bool { false }
        func scheduleDueMomentNotification(taskId: UUID, taskTitle: String, dueDate: Date) async {}
        func cancelDueMomentNotification(taskId: UUID) async {}
        func hasDueMomentNotificationScheduled(taskId: UUID) async -> Bool { false }
    }

    struct PreviewNudgeNotificationSchedulingClient: NudgeNotificationSchedulingAdapting {
        func requestAuthorizationIfNeeded() async -> Bool { false }
        func scheduleNotifications(nudgeId: UUID, label: String, schedule: NudgeSchedule) async {}
        func cancelNotifications(nudgeId: UUID) async {}
        func hasScheduledNotifications(nudgeId: UUID) async -> Bool { false }
    }

    struct PreviewLifeAreaDetailClient: LifeAreaDetailClientAdapting {
        func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem] { [] }
        func fetchLogs(lifeAreaId: UUID) async throws -> [Log] { [] }
    }

    return RootView(
        authService: AuthService(client: PreviewAuthClient()),
        homeClient: PreviewHomeClient(),
        tasksClient: PreviewTasksClient(),
        taskCreateClient: PreviewTaskCreateClient(),
        taskDetailClient: PreviewTaskDetailClient(),
        captureClient: PreviewCaptureClient(),
        nudgesClient: PreviewNudgesClient(),
        journalClient: PreviewJournalClient(),
        taskCountdownNudgeSchedulingClient: PreviewNudgeSchedulingClient(),
        nudgeNotificationSchedulingClient: PreviewNudgeNotificationSchedulingClient(),
        lifeAreaDetailClient: PreviewLifeAreaDetailClient()
    )
}
