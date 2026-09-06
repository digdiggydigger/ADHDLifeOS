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
///
/// Keyed PER USER since the snapshot fold (E's call, 2026-09-06; the run store led the family
/// in F-RoutineRecord-1): app-local defaults outlive a sign-out, and under one shared key the
/// next account's background wake could nudge with the previous account's place names and
/// custom messages. The cooldowns are scoped with the snapshot — they are that account's
/// bounce history. The scope is read at CALL time, so the stores the trigger service and the
/// handler build at launch follow the session; signed out, reads are empty and writes drop.
struct UserDefaultsArrivalNudgeStateStore: ArrivalNudgeStateStoring {
    /// The unscoped keys every build before the fold wrote — the leak itself. Kept as the
    /// scoped keys' prefixes, and so that `clearEveryUser` removes what those builds left.
    static let legacySnapshotKey = "places.arrivalNudge.snapshot"
    static let legacyCooldownsKey = "places.arrivalNudge.cooldowns"

    private let defaults: UserDefaults?
    private let userScope: () -> String?

    init(
        defaults: UserDefaults? = .standard,
        userScope: @escaping () -> String? = { FirebaseManager.shared.currentUser?.uid }
    ) {
        self.defaults = defaults
        self.userScope = userScope
    }

    /// The scoped keys for one user — internal so a test can look at the raw defaults.
    static func snapshotKey(forUser uid: String) -> String {
        "\(legacySnapshotKey).\(uid)"
    }

    static func cooldownsKey(forUser uid: String) -> String {
        "\(legacyCooldownsKey).\(uid)"
    }

    private var snapshotKey: String? {
        userScope().map(Self.snapshotKey(forUser:))
    }

    private var cooldownsKey: String? {
        userScope().map(Self.cooldownsKey(forUser:))
    }

    func readSnapshot() -> AtPlaceSnapshot? {
        guard let key = snapshotKey, let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AtPlaceSnapshot.self, from: data)
    }

    func writeSnapshot(_ snapshot: AtPlaceSnapshot) {
        guard let key = snapshotKey, let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: key)
    }

    func readCooldowns() -> TriggerCooldownState {
        guard
            let key = cooldownsKey,
            let data = defaults?.data(forKey: key),
            let state = try? JSONDecoder().decode(TriggerCooldownState.self, from: data)
        else { return TriggerCooldownState() }
        return state
    }

    func writeCooldowns(_ state: TriggerCooldownState) {
        guard let key = cooldownsKey, let data = try? JSONEncoder().encode(state) else { return }
        defaults?.set(data, forKey: key)
    }

    /// A session ending: every user's snapshot and cooldowns go, and so do the legacy unscoped
    /// keys an older build may have left. Needs no scope, which is the point — after an account
    /// deletion there is no user left to name.
    func clearEveryUser() {
        guard let defaults else { return }
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix(Self.legacySnapshotKey) || key.hasPrefix(Self.legacyCooldownsKey) {
            defaults.removeObject(forKey: key)
        }
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
