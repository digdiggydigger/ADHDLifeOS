//
//  ADHD_LifeOSApp.swift
//  ADHD LifeOS
//
//  Created by E Anthony on 17/07/2026.
//

import FirebaseCore
import SwiftUI

/// Configures Firebase at the earliest app-lifecycle point, per Firebase's canonical setup. The
/// `FirebaseApp.app() == nil` guard is load-bearing in BOTH places it appears: `ADHD_LifeOSApp.init`
/// runs before this delegate callback and constructs the Firebase adapters, so `FirebaseManager`'s
/// own lazy configure usually wins the race — and calling `configure()` twice raises an exception.
/// Keeping both guarded paths means configuration is exactly-once and always precedes any
/// Firestore/Auth access, regardless of which entry point runs first.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        return true
    }
}

@main
struct ADHD_LifeOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
                lifeAreaDetailClient: lifeAreaDetailClient
            )
                .onOpenURL { url in
                    Task { await authService.completeSession(from: url) }
                }
        }
    }
}
