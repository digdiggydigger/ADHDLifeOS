//
//  ADHD_LifeOSApp.swift
//  ADHD LifeOS
//
//  Created by E Anthony on 17/07/2026.
//

import Auth
import PostgREST
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
        let authClient = ADHD_LifeOSApp.makeAuthClient()
        let awsAuthClient = AWSAuthClientAdapter()
        // STOPGAP (2026-07-22, FIX: "No Supabase session after Cognito-only sign-in") — see
        // AuthService.supabaseBridge's doc comment for the full rationale and removal plan.
        let supabaseBridgeAuthClient = SupabaseAuthClientAdapter(client: authClient)
        _authService = StateObject(
            wrappedValue: AuthService(
                client: awsAuthClient,
                redirectURL: SupabaseConfig.authCallbackURL,
                supabaseBridge: supabaseBridgeAuthClient
            )
        )
        let postgrestClient = ADHD_LifeOSApp.makePostgrestClient()
        homeClient = AWSHomeClientAdapter(authClient: awsAuthClient)
        tasksClient = AWSTasksClientAdapter(authClient: awsAuthClient)
        taskCreateClient = AWSTaskCreateClientAdapter(authClient: awsAuthClient)
        taskDetailClient = AWSTaskDetailClientAdapter(authClient: awsAuthClient)
        captureClient = AWSCaptureClientAdapter(authClient: awsAuthClient)
        nudgesClient = SupabaseNudgesClientAdapter(authClient: authClient, postgrestClient: postgrestClient)
        journalClient = AWSJournalClientAdapter(authClient: awsAuthClient)
        taskCountdownNudgeSchedulingClient = NotificationCenterCountdownNudgeAdapter()
        nudgeNotificationSchedulingClient = NotificationCenterNudgeAdapter()
        lifeAreaDetailClient = AWSLifeAreaDetailClientAdapter(authClient: awsAuthClient)
        remindersClient = AWSRemindersClientAdapter()
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

    private static func makeAuthClient() -> AuthClient {
        AuthClient(
            url: SupabaseConfig.authURL,
            headers: [
                "Authorization": "Bearer \(SupabaseConfig.anonKey)",
                "Apikey": SupabaseConfig.anonKey
            ],
            localStorage: AuthClient.Configuration.defaultLocalStorage
        )
    }

    private static func makePostgrestClient() -> PostgrestClient {
        PostgrestClient(
            url: SupabaseConfig.projectURL.appendingPathComponent("rest/v1"),
            headers: ["apikey": SupabaseConfig.anonKey]
        )
    }
}
