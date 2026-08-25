//
//  ADHD_LifeOSApp.swift
//  ADHD LifeOS
//
//  Created by E Anthony on 17/07/2026.
//

import FirebaseCore
import SwiftUI
import UserNotifications

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
        // Without a delegate, iOS SILENTLY SUPPRESSES every notification while the app is
        // foregrounded — which is why correctly-scheduled task nudges, due-moment alerts and
        // Nudges-tab reminders all appeared to do nothing when tested with the app open (found
        // 2026-08-20). Registering here, before any scheduling can occur, is the only supported
        // place: the delegate must be set before the app finishes launching.
        UNUserNotificationCenter.current().delegate = ForegroundNotificationPresenter.shared
        return true
    }
}

/// Presents notifications that come due while the app is in the foreground, and routes taps on
/// delivered ones.
///
/// A focus checkpoint is worth interrupting for even when the user is staring at the app — that is
/// the entire point of a nudge — so these are shown as a banner with sound rather than swallowed.
final class ForegroundNotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ForegroundNotificationPresenter()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Foreground presentations follow the same Settings sound gate as scheduled content.
        let sound: UNNotificationPresentationOptions =
            AppFeedback.notificationSound() == nil ? [] : .sound
        let base: UNNotificationPresentationOptions
        if #available(iOS 14.0, *) {
            base = [.banner, .list]
        } else {
            base = .alert
        }
        completionHandler(base.union(sound))
    }

    /// A tap on a delivered notification. For a focus sprint this is the deliberate way out of a
    /// Live Activity that iOS won't let a suspended app dismiss on time: the tap settles the sprint,
    /// and settling ends the Activity. `FocusNotificationResponse` holds the rule, including why
    /// `scenePhase` alone was never enough — a cold launch from a notification starts `.active`, so
    /// there is no transition for `onChange` to see.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        FocusNotificationRouter.shared.handle(
            notificationIdentifier: response.notification.request.identifier,
            actionIdentifier: response.actionIdentifier
        )
        completionHandler()
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
        // the Cognito adapter and the Supabase clients went with it, and the Supabase auth bridge
        // that outlived them was deleted on 2026-08-23 once every screen it propped up had been
        // cut over. No `redirectURL`: Firebase has no magic-link flow here (the adapter throws
        // `magicLinkUnavailable`, same stub-and-hide precedent as the AWS era).
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
                    // A widget tap arrives on the same registered scheme as the auth callback;
                    // launching the app is the whole action, so it must NOT reach the auth layer.
                    guard AppDeepLink.route(url) == .authCallback else { return }
                    Task { await authService.completeSession(from: url) }
                }
        }
    }
}
