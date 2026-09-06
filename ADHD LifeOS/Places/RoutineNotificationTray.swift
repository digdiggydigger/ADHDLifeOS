//
//  RoutineNotificationTray.swift
//  ADHD LifeOS
//
//  A routine banner OUTLIVES the session that posted it (found by the routine-record journey,
//  2026-09-06): sign out, sign in as someone else, tap it, and the routine starts under the new
//  account — its place, its steps, its record writes failing against a document that account
//  never had. The same family as the run-store leak, one layer out. So a session ending clears
//  the routine species from the tray; task nudges and place-action banners are inert under a
//  new session and stay.
//

import Foundation
import UserNotifications

enum RoutineNotificationTray {
    /// The pure rule: which delivered identifiers are routine banners.
    static func identifiersToClear(from delivered: [String]) -> [String] {
        delivered.filter { $0.hasPrefix(PlaceRoutineNotificationContent.identifierPrefix) }
    }

    /// Fire-and-forget, like the sign-out that calls it: nothing waits on the tray.
    static func clearDeliveredRoutineBanners() {
        let center = UNUserNotificationCenter.current()
        center.getDeliveredNotifications { delivered in
            let doomed = identifiersToClear(from: delivered.map(\.request.identifier))
            guard !doomed.isEmpty else { return }
            center.removeDeliveredNotifications(withIdentifiers: doomed)
        }
    }
}
