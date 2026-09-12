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
        // The app's SINGLE category registry (F-Routines-2). Registration REPLACES the
        // whole set on every call, so any future category joins this one call — a second
        // registration site elsewhere would silently erase this one.
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(
                identifier: PlaceRoutineNotificationContent.categoryIdentifier,
                actions: [], intentIdentifiers: [],
                // iOS reports a SWIPE on a banner only when asked (F-RoutineRecord-1): with
                // this, clearing the routine banner reaches `didReceive` as a dismiss action
                // and the offer is recorded as swiped rather than left to time out.
                options: [.customDismissAction]
            )
        ])
        // A region crossing can RELAUNCH this app in the background with no UI (block 4b).
        // Touching the trigger service here rebuilds its CLLocationManager delegate before iOS
        // delivers the event it woke us for — a monitor created lazily by the first screen
        // would sleep through it. The handler hangs off the same wiring for the same reason:
        // recording the crossing (and, block 4c, nudging about it) must not need a screen.
        LocationTriggerService.shared.onEvent = { event in
            Task { await PlaceTriggerEventHandler.shared.handle(event) }
        }
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

    private func claimRoutineDismissal(
        _ response: UNNotificationResponse, identifier: String, userInfo: [AnyHashable: Any]
    ) -> Bool {
        MainActor.assumeIsolated {
            RoutineDismissRecorder.shared.handle(
                notificationIdentifier: identifier,
                actionIdentifier: response.actionIdentifier,
                userInfo: userInfo
            )
        }
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
        let identifier = response.notification.request.identifier
        let userInfo = response.notification.request.content.userInfo
        // A SWIPE on the routine banner (F-RoutineRecord-1), claimed FIRST: the routine router
        // below reads a response on its prefix as a tap and would START the routine the user
        // just cleared. iOS delivers it only because the category asks (`.customDismissAction`).
        if claimRoutineDismissal(response, identifier: identifier, userInfo: userInfo) {
            completionHandler()
            return
        }
        // Place-action taps first (F-PlaceActions-3) — their identifiers carry a prefix, so
        // everything else still falls through to the focus router untouched. SYNCHRONOUSLY on
        // the delegate callback (documented main-thread), never through an async hop: E's
        // field test showed iOS inserting its "LifeOS wants to open Spotify" confirmation, and
        // an async dispatch before `UIApplication.open` is exactly what breaks the tap's
        // user-initiated attribution and invites that dialog.
        let handledAsPlaceAction = MainActor.assumeIsolated {
            PlaceActionNotificationRouter.shared.handle(
                notificationIdentifier: identifier,
                userInfo: userInfo,
                openURL: { url, failureBody in
                    // Universal-first for web links (the app if installed, the web if not),
                    // one plain open for schemes. The opener keeps attempt 1 synchronous on
                    // this callback — the attribution rule lives in `PlaceLinkOpening.swift`.
                    PlaceLinkOpener(
                        open: { url, universalLinksOnly, completion in
                            UIApplication.shared.open(
                                url,
                                options: universalLinksOnly ? [.universalLinksOnly: true] : [:],
                                completionHandler: completion
                            )
                        },
                        notifyFailure: { body in
                            // Honest, and through the same in-foreground banner plumbing as
                            // every other immediate notification — never silence.
                            Task {
                                await NotificationCenterImmediateNotifier().post(
                                    title: "That didn't open",
                                    body: body,
                                    identifier: "placeActionOpenFailure"
                                )
                            }
                        }
                    ).run(PlaceLinkOpenPlan.plan(for: url), failureBody: failureBody)
                }
            )
        }
        // The routine species (F-Routines-3): its own prefix, its own branch — the
        // placeAction prefix is greedy by pinned design, so ordering it first costs nothing
        // and moving it would. The routine tap carries only the run key; the door resolves it.
        let handledAsRoutine = !handledAsPlaceAction && MainActor.assumeIsolated {
            PlaceRoutineNotificationRouter.shared.handle(
                notificationIdentifier: identifier, userInfo: userInfo
            )
        }
        if !handledAsPlaceAction && !handledAsRoutine {
            FocusNotificationRouter.shared.handle(
                notificationIdentifier: identifier,
                actionIdentifier: response.actionIdentifier
            )
        }
        completionHandler()
    }
}

@main
struct ADHD_LifeOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authService: AuthService
    /// `F-CTACelebrations-3`: the app's one celebration owner, held here rather than in
    /// `RootView` so it outlives every auth-state swap and every tab switch.
    @StateObject private var celebrationCenter = CelebrationCenter()
    private let homeClient: HomeClientAdapting
    private let tasksClient: TasksClientAdapting
    private let taskCreateClient: TaskCreateClientAdapting
    private let taskDetailClient: TaskDetailClientAdapting
    private let captureClient: CaptureClientAdapting
    private let nudgesClient: NudgesClientAdapting
    private let journalClient: JournalClientAdapting
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
        nudgeNotificationSchedulingClient = NotificationCenterNudgeAdapter()
        lifeAreaDetailClient = FirebaseLifeAreaDetailClientAdapter()
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                authService: authService,
                celebrationCenter: celebrationCenter,
                homeClient: homeClient,
                tasksClient: tasksClient,
                taskCreateClient: taskCreateClient,
                taskDetailClient: taskDetailClient,
                captureClient: captureClient,
                nudgesClient: nudgesClient,
                journalClient: journalClient,
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
