//
//  UITestUserDefaultsSeeds.swift
//  ADHD LifeOSUITests
//
//  `UITestSession`'s UserDefaults half — the seeds a journey hands the app through its LAUNCH
//  ARGUMENTS rather than through Firestore (`UITestFixtures.swift` is the Firestore half).
//
//  **Why launch arguments.** A UI test is its own process on the simulator: it cannot import the
//  app, cannot reach the app's container, and cannot spawn `xcrun simctl … defaults write`. What
//  it CAN do is pass `argv`, and `UserDefaults.standard` reads `-key value` pairs from `argv` into
//  its argument domain before any persisted domain. So the app reads the seed through the exact
//  code path it uses in production — `UserDefaultsFocusSprintStore.readUnacknowledgedCompletion()`
//  from `restorePersistedSprint()` — and no production code knows the test exists.
//
//  **Why the value is `<hex>`.** The argument domain parses each value as an old-style property
//  list, and `<hex bytes>` is that format's spelling for `Data` — `UserDefaults.data(forKey:)`
//  then hands the store the same bytes `JSONEncoder` would have written. Verified on macOS's
//  CoreFoundation (the same code the simulator runs) on 2026-09-17: `-probe.data "<7b22…7d>"`
//  came back as a 7-byte `Data` decoding to `{"a":1}`; the bare hex came back as a `String`.
//

import XCTest

extension UITestSession {

    /// The persisted key `UserDefaultsFocusSprintStore.completionKey` names. Spelled here rather
    /// than imported, because this target cannot see the app's types; the journey that uses it
    /// asserts the CARD appears, which is what proves the spelling still matches.
    static let unacknowledgedCompletionKey = "focus.sprint.unacknowledgedCompletion"

    /// Launch arguments that raise the "Sprint finished while you were away" card at launch —
    /// `OfflineSprintSummaryCard`, the app-was-dead completion `restorePersistedSprint()` reads
    /// from `focus.sprint.unacknowledgedCompletion` and holds until the user taps Got it.
    ///
    /// The record's field names are `CompletedFocusSession.CodingKeys` (snake_case), and its dates
    /// are `JSONEncoder`'s default `.deferredToDate`: seconds since the 2001 reference date.
    /// `planned_seconds` 1500 / `focused_seconds` 1500 / two checkpoints is the same shape E's
    /// device frame carried ("0 of 0 minutes logged · 2 checkpoints" was a sub-minute test
    /// sprint; the card's HEIGHT does not depend on the numbers).
    static func unacknowledgedCompletionLaunchArguments(taskTitle: String) -> [String] {
        let endedAt = Date().timeIntervalSinceReferenceDate
        let record: [String: Any] = [
            "id": UUID().uuidString,
            "task_title": taskTitle,
            "life_area_emoji": "🎯",
            "planned_seconds": 1500,
            "focused_seconds": 1500,
            "checkpoints_reached": 2,
            "completed_naturally": true,
            "started_at": endedAt - 1500,
            "ended_at": endedAt
        ]
        return dataArgument(unacknowledgedCompletionKey, json: record)
    }

    // MARK: - A running sprint (F-FanXAtRest, F-CollapsedBarLift)

    /// `UserDefaultsFocusSprintStore.key`, `.cardCollapsedKey` and `.unconfirmedCompletionsKey`,
    /// spelled here for the reason given above; the journeys that use them assert the timer bar
    /// and the Confirm card APPEAR, which is what proves the spellings still match.
    static let runningSprintKey = "focus.sprint.running"
    static let cardCollapsedKey = "focus.card.collapsed"
    static let unconfirmedCompletionsKey = "focus.sprint.unconfirmedCompletions"

    /// Launch arguments that put a sprint's timer bar up at launch — `restorePersistedSprint()`
    /// reinstating a `PersistedFocusSprint` — optionally collapsed.
    ///
    /// **PAUSED, deliberately** (`deadline` absent, `pausedRemainingSeconds` set): a running
    /// countdown restored from a seed would finish mid-journey, turn into a Confirm card and move
    /// everything the journey is measuring. `PersistedFocusSprint` has no `CodingKeys`, so its
    /// field names are the property names; its dates are seconds since the 2001 reference date.
    static func pausedSprintLaunchArguments(taskTitle: String, collapsed: Bool) -> [String] {
        let startedAt = Date().timeIntervalSinceReferenceDate - 300
        let sprint: [String: Any] = [
            "taskTitle": taskTitle,
            "lifeAreaEmoji": "🎯",
            "durationSeconds": 1500,
            "nudgeCheckpoints": [750],
            "triggeredCheckpointIndices": [Int](),
            "startedAt": startedAt,
            "pausedRemainingSeconds": 1200,
            "cadenceCount": 1
        ]
        // `UserDefaults.bool(forKey:)` reads the argument domain's string "YES" as true.
        return dataArgument(runningSprintKey, json: sprint)
            + ["-\(cardCollapsedKey)", collapsed ? "YES" : "NO"]
    }

    /// Launch arguments that raise one Confirm card — a sprint that finished naturally and waits
    /// on the user's Confirm (`FocusCompletionCardStack`), newest first. The record is the same
    /// snake_case `CompletedFocusSession` shape as the away card's, in an ARRAY.
    static func unconfirmedCompletionLaunchArguments(taskTitle: String) -> [String] {
        let endedAt = Date().timeIntervalSinceReferenceDate - 60
        let record: [String: Any] = [
            "id": UUID().uuidString,
            "task_title": taskTitle,
            "life_area_emoji": "🎯",
            "planned_seconds": 30,
            "focused_seconds": 30,
            "checkpoints_reached": 2,
            "completed_naturally": true,
            "started_at": endedAt - 30,
            "ended_at": endedAt
        ]
        return dataArgument(unconfirmedCompletionsKey, json: [record])
    }

    /// `-key <hex>`: the argument domain's spelling for `Data` (see the file comment).
    private static func dataArgument(_ key: String, json object: Any) -> [String] {
        guard let json = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else {
            XCTFail("The \(key) seed could not be serialised — the seed is empty")
            return []
        }
        let hex = json.map { String(format: "%02x", $0) }.joined()
        return ["-\(key)", "<\(hex)>"]
    }
}
