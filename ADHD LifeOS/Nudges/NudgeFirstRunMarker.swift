//
//  NudgeFirstRunMarker.swift
//  ADHD LifeOS
//

import Foundation

/// Whether a given ACCOUNT has ever had a nudge — the flag behind the first-run door.
///
/// **Keyed by uid, and that is the entire point.** The first version of this was a plain
/// `@AppStorage("nudges.hasEverHadAny")`, which is UserDefaults and therefore per DEVICE. The
/// second account signed into a phone would inherit the first account's answer, so a genuinely
/// new user would never see their first-run door — reintroducing the exact dead end
/// `F-FirstNudgeReachable` exists to remove, one layer up.
///
/// The comment shipped with that first version claimed the failure was harmless ("the worst case
/// is the empty door appears once more than it needed to"). That was backwards: this flag can
/// only ever SUPPRESS the door, never add one, so every error it makes is in the harmful
/// direction. Caught while planning a fresh-signup test before public release.
///
/// Device-local rather than in Firestore, deliberately: it is a presentation hint, not user data.
/// A reinstall showing the invitation once more is the harmless direction; a network read on
/// Today's critical path to decide whether to draw a card is not worth it.
enum NudgeFirstRunMarker {
    static func key(for uid: String) -> String { "nudges.hasEverHadAny.\(uid)" }

    static func hasEverHadNudges(uid: String, in defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: key(for: uid))
    }

    /// Idempotent — callers latch on every appearance and on every change, and must not have to
    /// check first.
    static func markHasHadNudges(uid: String, in defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: key(for: uid))
    }
}
