//
//  CelebrationDayMarking.swift
//  ADHD LifeOS
//
//  `F-CTACelebrations-5`: which milestones have already been celebrated TODAY, for the one of E's
//  four that is once-per-day (F7: "once per day; no replay after an undo-and-recross").
//
//  **Keyed by uid, and that is the entire point** — `NudgeFirstRunMarker`'s lesson, applied before
//  it could bite a second time. `UserDefaults` is per DEVICE, so a plain key would let a second
//  account signed into one phone inherit the first account's "already celebrated today" and
//  swallow a real crossing in silence.
//
//  **One key per (milestone, account), holding the DAY** — not one key per day, which would
//  accumulate a row in the defaults for every day the app is ever used. Today's entry simply
//  overwrites yesterday's.
//
//  Device-local rather than in Firestore, for `NudgeFirstRunMarker`'s reason: it is a presentation
//  hint, not user data, and celebrating once more after a reinstall is the harmless direction.
//

import Foundation

enum CelebrationDayMarking {
    static func key(for milestone: CelebrationMilestone, uid: String) -> String {
        "celebrations.lastCelebratedDay.\(milestone.rawValue).\(uid)"
    }

    static func hasCelebrated(
        _ milestone: CelebrationMilestone,
        uid: String,
        asOf now: Date = .now,
        calendar: Calendar = .current,
        in defaults: UserDefaults = .standard
    ) -> Bool {
        // `object(forKey:)`, not `double(forKey:)`: the latter answers 0 for a key that was never
        // written, which is a real timestamp rather than "never".
        guard let stamped = defaults.object(forKey: key(for: milestone, uid: uid)) as? Double else {
            return false
        }
        return stamped == calendar.startOfDay(for: now).timeIntervalSince1970
    }

    /// Idempotent — the caller marks whenever it celebrates and never has to check first.
    static func markCelebrated(
        _ milestone: CelebrationMilestone,
        uid: String,
        asOf now: Date = .now,
        calendar: Calendar = .current,
        in defaults: UserDefaults = .standard
    ) {
        defaults.set(
            calendar.startOfDay(for: now).timeIntervalSince1970,
            forKey: key(for: milestone, uid: uid)
        )
    }
}
