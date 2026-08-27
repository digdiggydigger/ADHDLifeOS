//
//  AppFeedback.swift
//  ADHD LifeOS
//

import Foundation
import UserNotifications

/// The two feedback gates Settings controls (E's 2026-08-25 audit): haptics and notification
/// sound. One home, consulted at FIRE time — a preference flipped mid-session takes effect on
/// the very next tap or schedule, no relaunch, no plumbing through every view.
enum AppFeedback {
    static func hapticsEnabled(
        store: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore()
    ) -> Bool {
        store.read().hapticsEnabled
    }

    /// Whether records should stamp WHERE they happened. Read at stamp time, so flipping the
    /// Settings switch silences the very next capture with no relaunch. Location permission is a
    /// separate and stricter gate — this only decides whether a fix is requested at all.
    static func locationTaggingEnabled(
        store: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore()
    ) -> Bool {
        store.read().locationTaggingEnabled
    }

    /// What a scheduled notification's `content.sound` should be — `.default` or silent. Only
    /// governs notifications THIS APP schedules; system settings are untouched.
    static func notificationSound(
        store: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore()
    ) -> UNNotificationSound? {
        store.read().soundEnabled ? .default : nil
    }
}
