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
    func post(title: String, body: String, identifier: String) async
}

struct NotificationCenterImmediateNotifier: ImmediateNotifying {
    func post(title: String, body: String, identifier: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
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
}
