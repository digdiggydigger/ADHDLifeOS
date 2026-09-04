//
//  PlaceRoutineNotificationReplay.swift
//  ADHD LifeOS
//

import Foundation
import UserNotifications

#if DEBUG
/// TEMPORARY field-test tool, the sibling of `PlaceTriggerTestFire` and added for the same
/// reason (Block A): deferred logging means a crossing now writes NOTHING until the banner is
/// tapped, so the existing test-fire button on its own can no longer produce a routine.
///
/// It does not simulate a tap — it performs one. iOS delivers a tap by handing the delegate the
/// delivered notification's identifier and userInfo; this reads the delivered routine
/// notification straight out of the tray and hands those same two values to the same router.
/// There is no second copy of the payload anywhere, so this cannot drift from the real path.
///
/// Two callers, and both want exactly that fidelity: E, testing the whole flow from the couch
/// without waiting on a banner that a foregrounded app may not even present; and the routine
/// UI journeys, which have to start a run without XCUITest wrestling SpringBoard.
///
/// The seams are closures in the `PlaceTriggerTestFire` style — the tray, the router and the
/// removal — because `UNUserNotificationCenter` cannot usefully be faked and the selection rule
/// (newest matching wins) is worth a test of its own.
@MainActor
enum PlaceRoutineNotificationReplay {
    typealias Delivered = (identifier: String, userInfo: [AnyHashable: Any])

    /// Opens the most recently delivered routine notification. Returns whether one was found —
    /// the caller decides what silence means.
    ///
    /// It POLLS rather than looking once, because the obvious sequence — fire the crossing, then
    /// immediately open the notification — races the post. Firing runs an authorization request
    /// and a tasks fetch before it posts, so the banner can land a second or two after the
    /// dialog dismisses; a single look would report "nothing delivered" about a crossing that
    /// was about to deliver. That is E's couch flow AND the journeys' flow, so it is the
    /// ordinary case, not the edge one.
    @discardableResult
    static func openLatest(
        attempts: Int = 10,
        interval: Duration = .milliseconds(300),
        delivered: () async -> [Delivered] = liveDelivered,
        route: @MainActor (String, [AnyHashable: Any]) -> Void = liveRoute,
        remove: @MainActor ([String]) -> Void = liveRemove
    ) async -> Bool {
        for attempt in 1...max(1, attempts) {
            // `deliveredNotifications()` is oldest-first, so the LAST match is the newest
            // crossing — the one a person reaching into their tray would tap.
            if let latest = await delivered().last(where: {
                $0.identifier.hasPrefix(PlaceRoutineNotificationContent.identifierPrefix)
            }) {
                route(latest.identifier, latest.userInfo)
                // A real tap clears the banner. Leaving it would let the next replay re-open a
                // routine already underway rather than the one just fired.
                remove([latest.identifier])
                return true
            }
            if attempt < max(1, attempts) {
                try? await Task.sleep(for: interval)
            }
        }
        return false
    }

    // MARK: - The live wiring

    static let liveDelivered: () async -> [Delivered] = {
        await UNUserNotificationCenter.current().deliveredNotifications().map {
            (identifier: $0.request.identifier, userInfo: $0.request.content.userInfo)
        }
    }

    @MainActor
    static let liveRoute: (String, [AnyHashable: Any]) -> Void = { identifier, userInfo in
        PlaceRoutineNotificationRouter.shared.handle(
            notificationIdentifier: identifier, userInfo: userInfo
        )
    }

    @MainActor
    static let liveRemove: ([String]) -> Void = { identifiers in
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
#endif
