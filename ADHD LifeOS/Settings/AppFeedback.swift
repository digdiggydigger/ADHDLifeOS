//
//  AppFeedback.swift
//  ADHD LifeOS
//

import Foundation
import UserNotifications

/// The feedback gates Settings controls (E's 2026-08-25 audit, and the CTA celebrations arc's
/// two switches): haptics, notification sound, location stamping, arrival nudges, and the two
/// celebration switches. One home, consulted at FIRE time — a preference flipped mid-session takes effect on
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

    /// The master switch over every place's arrival/departure nudges (block 4b). Read at
    /// registration AND fire time, so flipping it silences the very next crossing with no
    /// relaunch. The Always grant is a separate and stricter gate.
    static func arrivalNudgesEnabled(
        store: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore()
    ) -> Bool {
        store.read().arrivalNudgesEnabled
    }

    /// E's #3: the master switch over every FULL-SCREEN celebration. Read at FIRE time, so a flip
    /// takes effect on the very next Confirm with no relaunch and nothing plumbed through the view
    /// tree. Haptics and the in-place flourishes are deliberately NOT gated on this.
    static func celebrationsEnabled(
        store: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore()
    ) -> Bool {
        store.read().celebrationsEnabled
    }

    /// E's F5: whether those full-screen celebrations carry their one soft chime. Read at fire time
    /// for the same reason. **Nothing consults this yet** — the player ships in
    /// `F-CTACelebrations-7`, and the Settings footer says so rather than implying a sound exists.
    static func celebrationSoundsEnabled(
        store: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore()
    ) -> Bool {
        store.read().celebrationSoundsEnabled
    }

    /// What a scheduled notification's `content.sound` should be — `.default` or silent. Only
    /// governs notifications THIS APP schedules; system settings are untouched.
    static func notificationSound(
        store: MomentumPreferencesStoring = UserDefaultsMomentumPreferencesStore()
    ) -> UNNotificationSound? {
        store.read().soundEnabled ? .default : nil
    }
}
