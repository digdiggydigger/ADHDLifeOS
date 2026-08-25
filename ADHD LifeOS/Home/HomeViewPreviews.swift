//
//  HomeViewPreviews.swift
//  ADHD LifeOS
//
//  Preview scaffolding for HomeView, split out of HomeView.swift to keep that file within the
//  SwiftLint 400-line file-length budget. DEBUG-only.
//

import SwiftUI

#if DEBUG
private struct PreviewAuthClientAdapting: AuthClientAdapting {
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

private struct PreviewHomeClientAdapting: HomeClientAdapting {
    func fetchAllTasks() async throws -> [TaskItem] { [] }
    let lifeAreas = [
        LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0),
        LifeArea(id: UUID(), name: "Work", colour: "💼", sortOrder: 1)
    ]

    func fetchLifeAreas() async throws -> [LifeArea] { lifeAreas }

    func fetchOpenTasks() async throws -> [TaskSummary] {
        lifeAreas.map { TaskSummary(lifeAreaId: $0.id, status: .open) }
    }

    func reorder(order: [UUID]) async throws {}
}

private struct PreviewCaptureClientAdapting: CaptureClientAdapting {
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

private struct PreviewNudgesClientAdapting: NudgesClientAdapting {
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

private struct PreviewNudgeNotificationSchedulingClient: NudgeNotificationSchedulingAdapting {
    func requestAuthorizationIfNeeded() async -> Bool { false }
    func scheduleNotifications(nudgeId: UUID, label: String, schedule: NudgeSchedule) async {}
    func cancelNotifications(nudgeId: UUID) async {}
    func hasScheduledNotifications(nudgeId: UUID) async -> Bool { false }
}

private struct PreviewLifeAreaDetailClientAdapting: LifeAreaDetailClientAdapting {
    func fetchTasks(lifeAreaId: UUID) async throws -> [TaskItem] { [] }
    func fetchLogs(lifeAreaId: UUID) async throws -> [Log] { [] }
}

private struct PreviewTaskDetailClientAdapting: TaskDetailClientAdapting {
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

private struct PreviewNudgeSchedulingClientAdapting: TaskCountdownNudgeSchedulingAdapting {
    func requestAuthorizationIfNeeded() async -> Bool { false }
    func scheduleNudges(taskId: UUID, taskTitle: String, fireDates: [ScheduledCountdownNudge]) async {}
    func cancelNudges(taskId: UUID) async {}
    func hasScheduledNudges(taskId: UUID) async -> Bool { false }
    func scheduleDueMomentNotification(taskId: UUID, taskTitle: String, dueDate: Date) async {}
    func cancelDueMomentNotification(taskId: UUID) async {}
    func hasDueMomentNotificationScheduled(taskId: UUID) async -> Bool { false }
}

#Preview {
    HomeView(
        authService: AuthService(client: PreviewAuthClientAdapting()),
        homeClient: PreviewHomeClientAdapting(),
        captureClient: PreviewCaptureClientAdapting(),
        nudgesClient: PreviewNudgesClientAdapting(),
        nudgeNotificationSchedulingClient: PreviewNudgeNotificationSchedulingClient(),
        lifeAreaDetailClient: PreviewLifeAreaDetailClientAdapting(),
        taskDetailClient: PreviewTaskDetailClientAdapting(),
        schedulingClient: PreviewNudgeSchedulingClientAdapting()
    )
}
#endif
