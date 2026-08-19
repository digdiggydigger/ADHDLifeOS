//
//  FocusSprintIntents.swift
//  FocusTimerWidget
//
//  Compiled into BOTH the app and the widget extension, like `FocusActivityAttributes`: the
//  extension needs the types to build `Button(intent:)`, and the system executes the APP's copy —
//  `LiveActivityIntent` performs in the app's process, which is what lets these drive the real
//  `FocusSessionService` engine instead of some serialized shadow of it.
//

import ActivityKit
import AppIntents
import Foundation

/// The app-side actions the intents call through. The app populates these at launch (see
/// `FocusSessionService.withLiveActivityMirroring`); inside the widget extension — and inside an
/// app process the system cold-launched just to run an intent, where no sprint engine exists —
/// they stay nil and the intent falls back to clearing orphaned Activities.
@MainActor
enum FocusSprintIntentActions {
    static var pauseResume: (() async -> Void)?
    static var stop: (() async -> Void)?
}

@available(iOS 16.1, *)
extension FocusActivityAttributes {
    /// Ends every Activity of this type immediately. Used by the mirror's launch cleanup and by
    /// intents that arrive in a cold-launched app with no live engine — in both cases whatever is
    /// on the Lock Screen is an orphan of a killed sprint.
    static func endAllActivities() async {
        for activity in Activity<FocusActivityAttributes>.activities {
            if #available(iOS 16.2, *) {
                await activity.end(nil, dismissalPolicy: .immediate)
            } else {
                await activity.end(using: nil, dismissalPolicy: .immediate)
            }
        }
    }
}

@available(iOS 17.0, *)
struct PauseResumeFocusSprintIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Pause or Resume Focus Sprint"
    /// Lock Screen plumbing, not a user-facing shortcut — keep it out of Spotlight/Shortcuts.
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        if let pauseResume = await FocusSprintIntentActions.pauseResume {
            await pauseResume()
        } else {
            await FocusActivityAttributes.endAllActivities()
        }
        return .result()
    }
}

@available(iOS 17.0, *)
struct StopFocusSprintIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop Focus Sprint"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        if let stop = await FocusSprintIntentActions.stop {
            await stop()
        } else {
            await FocusActivityAttributes.endAllActivities()
        }
        return .result()
    }
}
