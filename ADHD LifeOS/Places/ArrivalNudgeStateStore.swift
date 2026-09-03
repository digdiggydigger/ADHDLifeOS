//
//  ArrivalNudgeStateStore.swift
//  ADHD LifeOS
//

import Foundation
import UserNotifications

/// The nudge state a background relaunch needs back: the at-place snapshot and the cooldowns.
/// One seam so the handler and the trigger service share a single source of truth in tests.
protocol ArrivalNudgeStateStoring {
    func readSnapshot() -> AtPlaceSnapshot?
    func writeSnapshot(_ snapshot: AtPlaceSnapshot)
    func readCooldowns() -> TriggerCooldownState
    func writeCooldowns(_ state: TriggerCooldownState)
}

/// App-local UserDefaults, the `UserDefaultsMomentumPreferencesStore` arrangement: every failure
/// path — unavailable defaults, corrupt data — degrades to empty instead of trapping.
struct UserDefaultsArrivalNudgeStateStore: ArrivalNudgeStateStoring {
    static let snapshotKey = "places.arrivalNudge.snapshot"
    static let cooldownsKey = "places.arrivalNudge.cooldowns"

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
    }

    func readSnapshot() -> AtPlaceSnapshot? {
        guard let data = defaults?.data(forKey: Self.snapshotKey) else { return nil }
        return try? JSONDecoder().decode(AtPlaceSnapshot.self, from: data)
    }

    func writeSnapshot(_ snapshot: AtPlaceSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: Self.snapshotKey)
    }

    func readCooldowns() -> TriggerCooldownState {
        guard
            let data = defaults?.data(forKey: Self.cooldownsKey),
            let state = try? JSONDecoder().decode(TriggerCooldownState.self, from: data)
        else { return TriggerCooldownState() }
        return state
    }

    func writeCooldowns(_ state: TriggerCooldownState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults?.set(data, forKey: Self.cooldownsKey)
    }
}

/// Posts one local notification, now. Distinct from the sprint/nudge SCHEDULERS on purpose —
/// a fence crossing is already the moment, so there is nothing to schedule.
protocol ImmediateNotifying: Sendable {
    /// `userInfo` carries what a TAP on the notification needs (a place action's own JSON);
    /// empty for notifications whose tap just opens the app.
    func post(title: String, body: String, identifier: String, userInfo: [String: String]) async
    /// Named widening #1 (F-Routines-2): the routine notification is its OWN species with its
    /// own `UNNotificationCategory`. A requirement, not an extension default — the recording
    /// fakes must see the category or the species split is untestable.
    func post(
        title: String, body: String, identifier: String,
        userInfo: [String: String], categoryIdentifier: String
    ) async
    /// Named widening #2 (F-Routines-2): tray hygiene. Posting a routine removes the place's
    /// still-delivered per-action notifications, so one crossing never leaves two eras of
    /// notification competing in the tray.
    func removeDelivered(identifiers: [String]) async
}

extension ImmediateNotifying {
    func post(title: String, body: String, identifier: String) async {
        await post(title: title, body: body, identifier: identifier, userInfo: [:])
    }
}

struct NotificationCenterImmediateNotifier: ImmediateNotifying {
    func post(title: String, body: String, identifier: String, userInfo: [String: String]) async {
        await post(
            title: title, body: body, identifier: identifier,
            userInfo: userInfo, categoryIdentifier: ""
        )
    }

    func post(
        title: String, body: String, identifier: String,
        userInfo: [String: String], categoryIdentifier: String
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if !userInfo.isEmpty {
            content.userInfo = userInfo
        }
        if !categoryIdentifier.isEmpty {
            content.categoryIdentifier = categoryIdentifier
        }
        // The same Settings sound gate every scheduled notification honours.
        if let sound = AppFeedback.notificationSound() {
            content.sound = sound
        }
        // A stable identifier per place+direction REPLACES an undelivered predecessor rather
        // than stacking — two arrivals must never sit in the tray together.
        try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        )
    }

    func removeDelivered(identifiers: [String]) async {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
