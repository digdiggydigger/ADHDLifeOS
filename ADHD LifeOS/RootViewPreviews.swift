//
//  RootViewPreviews.swift
//  ADHD LifeOS
//
//  RootView's #Preview and its stub clients, split out on the house pattern
//  (CaptureInboxSections / JournalViewPreviews) to keep RootView.swift inside the
//  400-line file budget.
//

import SwiftUI

#Preview {
    struct PreviewAuthClient: AuthClientAdapting {
        func restoredUser() async -> AuthUser? { nil }
        func signIn(email: String, password: String) async throws -> AuthUser { fatalError("unused in preview") }
        func requestOTP(email: String, redirectTo: URL?) async throws {}
        func completeSession(from url: URL) async throws -> AuthUser { fatalError("unused in preview") }
        func signUp(email: String, password: String, displayName: String?) async throws -> AuthUser {
            AuthUser(id: UUID(), email: email)
        }

        func updateDisplayName(_ displayName: String?) async throws -> AuthUser {
            AuthUser(id: UUID(), email: "preview@example.com", displayName: displayName)
        }
        func sendPasswordReset(email: String) async throws {}

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
        func deleteTask(id: UUID) async throws {}
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
        func markUnprocessed(captureId: UUID) async throws {}
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
        func markFired(id: UUID, existingCompletionDates: [Date]) async throws -> Nudge {
        fatalError("unused in preview")
    }
    }

    struct PreviewJournalClient: JournalClientAdapting {
        func fetchLifeAreas() async throws -> [LifeArea] { [] }
        func fetchLogs() async throws -> [Log] { [] }
        func fetchFocusSessions() async throws -> [CompletedFocusSession] { [] }
        func fetchCaptures() async throws -> [Capture] { [] }
        func fetchLocationEvents() async throws -> [LocationEvent] { [] }
        func fetchPlaces() async throws -> [Place] { [] }
        func fetchAllTags() async throws -> [Tag] { [] }
        func createTag(name: String) async throws -> Tag { fatalError("unused in preview") }
        func createLog(_ input: NormalizedCreateLogInput) async throws -> Log { fatalError("unused in preview") }
        func deleteLog(id: UUID) async throws {}
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
        nudgeNotificationSchedulingClient: PreviewNudgeNotificationSchedulingClient(),
        lifeAreaDetailClient: PreviewLifeAreaDetailClient()
    )
}
