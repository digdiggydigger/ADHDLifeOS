//
//  RootView.swift
//  ADHD LifeOS
//

import SwiftUI

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
    let remindersClient: RemindersClientAdapting

    @State private var isPresentingQuickCapture = false

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
                        nudgesClient: nudgesClient,
                        nudgeNotificationSchedulingClient: nudgeNotificationSchedulingClient,
                        lifeAreaDetailClient: lifeAreaDetailClient,
                        taskDetailClient: taskDetailClient,
                        schedulingClient: taskCountdownNudgeSchedulingClient
                    )
                        .tabItem { Label("Home", systemImage: "house") }
                    TaskListView(
                        tasksClient: tasksClient,
                        taskCreateClient: taskCreateClient,
                        taskDetailClient: taskDetailClient,
                        schedulingClient: taskCountdownNudgeSchedulingClient
                    )
                        .tabItem { Label("Tasks", systemImage: "checklist") }
                    JournalView(client: journalClient)
                        .tabItem { Label("Journal", systemImage: "book") }
                    // TEMPORARY TAB SWAP (E's decision 2026-07-22, see ARCHITECTURE.md §3 and the
                    // AWS Reminders View feature block in the CC handoff doc) — Nudges tab entry
                    // commented out, not deleted. Restoring it is uncommenting this block and
                    // removing the Reminders tab below.
                    // NavigationStack {
                    //     NudgesView(
                    //         client: nudgesClient,
                    //         notificationSchedulingClient: nudgeNotificationSchedulingClient
                    //     )
                    // }
                    //     .tabItem { Label("Nudges", systemImage: "bell") }
                    NavigationStack {
                        RemindersView(client: remindersClient)
                    }
                        .tabItem { Label("Reminders", systemImage: "clock.badge") }
                }
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        isPresentingQuickCapture = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 48))
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 70)
                    .accessibilityIdentifier("quickCaptureButton")
                }
                .sheet(isPresented: $isPresentingQuickCapture) {
                    QuickCaptureView(client: captureClient) {}
                }
            }
        }
        .task {
            if authService.state == .unknown {
                await authService.restoreSession()
            }
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
    }

    struct PreviewHomeClient: HomeClientAdapting {
        func fetchLifeAreas() async throws -> [LifeArea] { [] }
        func fetchOpenTasks() async throws -> [TaskSummary] { [] }
        func reorder(order: [UUID]) async throws {}
    }

    struct PreviewTasksClient: TasksClientAdapting {
        func fetchLifeAreas() async throws -> [LifeArea] { [] }
        func fetchAllTasks() async throws -> [TaskItem] { [] }
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
        func fetchCapture(id: UUID) async throws -> Capture { fatalError("unused in preview") }
        func createTask(_ input: NormalizedPromoteToTaskInput) async throws -> TaskItem {
            fatalError("unused in preview")
        }
        func markProcessed(captureId: UUID) async throws {}
        func requestUploadURL(kind: CaptureKind, contentType: String) async throws -> CaptureUploadTarget {
            fatalError("unused in preview")
        }
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

    struct PreviewRemindersClient: RemindersClientAdapting {
        func fetchReminders() async throws -> [Reminder] { [] }
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
        lifeAreaDetailClient: PreviewLifeAreaDetailClient(),
        remindersClient: PreviewRemindersClient()
    )
}
