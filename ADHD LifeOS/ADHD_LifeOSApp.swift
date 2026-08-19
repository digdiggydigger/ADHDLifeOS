//
//  ADHD_LifeOSApp.swift
//  ADHD LifeOS
//
//  Created by E Anthony on 17/07/2026.
//

import SwiftUI

@main
struct ADHD_LifeOSApp: App {
    @StateObject private var authService: AuthService
    private let homeClient: HomeClientAdapting
    private let tasksClient: TasksClientAdapting
    private let taskCreateClient: TaskCreateClientAdapting
    private let taskDetailClient: TaskDetailClientAdapting
    private let captureClient: CaptureClientAdapting
    private let nudgesClient: NudgesClientAdapting
    private let journalClient: JournalClientAdapting
    private let taskCountdownNudgeSchedulingClient: TaskCountdownNudgeSchedulingAdapting
    private let nudgeNotificationSchedulingClient: NudgeNotificationSchedulingAdapting
    private let lifeAreaDetailClient: LifeAreaDetailClientAdapting
    private let remindersClient: RemindersClientAdapting

    init() {
        // Single backend: everything below is Firestore/Firebase Auth via `FirebaseManager` —
        // the Cognito adapter, Supabase clients, and the Supabase auth bridge are gone with it.
        // No `redirectURL`/`supabaseBridge`: Firebase has no magic-link flow here (the adapter
        // throws `magicLinkUnavailable`, same stub-and-hide precedent as the AWS era).
        _authService = StateObject(wrappedValue: AuthService(client: FirebaseAuthClientAdapter()))
        homeClient = FirebaseHomeClientAdapter()
        tasksClient = FirebaseTasksClientAdapter()
        taskCreateClient = FirebaseTaskCreateClientAdapter()
        taskDetailClient = FirebaseTaskDetailClientAdapter()
        captureClient = FirebaseCaptureClientAdapter()
        nudgesClient = FirebaseNudgesClientAdapter()
        journalClient = FirebaseJournalClientAdapter()
        taskCountdownNudgeSchedulingClient = NotificationCenterCountdownNudgeAdapter()
        nudgeNotificationSchedulingClient = NotificationCenterNudgeAdapter()
        lifeAreaDetailClient = FirebaseLifeAreaDetailClientAdapter()
        remindersClient = FirebaseRemindersClientAdapter()
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                authService: authService,
                homeClient: homeClient,
                tasksClient: tasksClient,
                taskCreateClient: taskCreateClient,
                taskDetailClient: taskDetailClient,
                captureClient: captureClient,
                nudgesClient: nudgesClient,
                journalClient: journalClient,
                taskCountdownNudgeSchedulingClient: taskCountdownNudgeSchedulingClient,
                nudgeNotificationSchedulingClient: nudgeNotificationSchedulingClient,
                lifeAreaDetailClient: lifeAreaDetailClient,
                remindersClient: remindersClient
            )
                .onOpenURL { url in
                    Task { await authService.completeSession(from: url) }
                }
        }
    }
}
