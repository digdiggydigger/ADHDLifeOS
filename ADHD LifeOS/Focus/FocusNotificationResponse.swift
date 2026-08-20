//
//  FocusNotificationResponse.swift
//  ADHD LifeOS
//

import Foundation
import UserNotifications

/// What a tap on a delivered notification asks the sprint engine to do.
///
/// iOS gives no way to dismiss a Live Activity at an exact instant while the app is suspended, so
/// between a sprint's deadline and the next unlock the card is still on the Lock Screen — rendering
/// a correct terminal frame (`hasElapsed`), but still there. The "Sprint complete" notification is
/// the deliberate route out: tapping it opens the app, the app settles the sprint, and settling ends
/// the Activity.
///
/// `scenePhase` alone does not cover this, which is why the route is explicit:
/// - a **cold launch from the notification** starts at `.active`, so `onChange(of: scenePhase)`
///   never fires — there is no transition to observe;
/// - a tap taken while the app is **already foregrounded** doesn't change the phase either.
///
/// Pure and total, so the rule is unit-tested without a notification centre.
enum FocusNotificationResponse: Equatable, Sendable {
    /// Settle the sprint against the wall clock (`FocusSessionService.syncNow`).
    case settleSprint
    /// Another feature's notification, or an action that isn't a tap. The engine is not touched.
    case ignore

    static func route(notificationIdentifier: String, actionIdentifier: String) -> Self {
        // Only the tap that opens the app. Swiping a notification away is the user saying "not
        // now" — it must not end their sprint.
        guard actionIdentifier == UNNotificationDefaultActionIdentifier else { return .ignore }
        // The three notification features share one delegate; a task countdown nudge or a
        // Nudges-tab reminder has nothing to do with the sprint engine.
        guard notificationIdentifier.hasPrefix(ScheduledFocusNotification.identifierPrefix) else {
            return .ignore
        }
        // Checkpoints settle too: `syncNow` is idempotent (on a running sprint it only catches the
        // count up), and a checkpoint banner is very often the one still on screen once the sprint
        // has run out.
        return .settleSprint
    }
}

/// Carries a notification tap from the app delegate to the sprint engine.
///
/// A reference type with a shared instance rather than static hooks (the shape
/// `FocusSprintIntentActions` uses) for one reason: tests construct their own router instead of
/// mutating and resetting global state between cases.
@MainActor
final class FocusNotificationRouter {
    static let shared = FocusNotificationRouter()

    private var settleSprint: (() -> Void)?
    /// A tap that arrived before the engine existed. iOS delivers a launch-from-notification tap
    /// during app launch, while `FocusSessionService` is not built until RootView's body first
    /// runs — dropping it would leave exactly the lingering Activity this route exists to clear.
    private var hasPendingSettle = false

    /// Points the router at the live engine, replaying a tap that beat it to the punch. Spent on
    /// replay, so a later reconnect doesn't settle a sprint the user has since started.
    func connect(settleSprint: @escaping () -> Void) {
        self.settleSprint = settleSprint
        guard hasPendingSettle else { return }
        hasPendingSettle = false
        settleSprint()
    }

    func handle(notificationIdentifier: String, actionIdentifier: String) {
        guard FocusNotificationResponse.route(
            notificationIdentifier: notificationIdentifier, actionIdentifier: actionIdentifier
        ) == .settleSprint else { return }

        if let settleSprint {
            settleSprint()
        } else {
            hasPendingSettle = true
        }
    }
}
