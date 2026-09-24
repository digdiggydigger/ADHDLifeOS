//
//  PlaceRoutineScreen+Opening.swift
//  ADHD LifeOS
//
//  `PlaceRoutineScreen`'s external-open plumbing, moved out in `F-CTACelebrations-6` to make
//  room for the Completed flow — the move that buys TYPE-BODY lines, which is the ceiling that
//  binds (`type_body_length` 250; the preview move in C1 bought file lines and none of these).
//
//  **`openExternally` is `internal`, not `private`, and that is a consequence rather than a
//  choice.** Swift's `private` is FILE-scoped, so a method in an extension file cannot see a
//  `private` member of the type and cannot itself be `private` if the main file calls it. It is
//  the `CaptureInboxService.replaceCapture` precedent, recorded in the register: an extension
//  that moves out of its type's file leaves same-file `private` access behind with it.
//
//  It reaches nothing of the screen's own state — only its two arguments — so widening it
//  exposes no more of the screen than the call already did.
//

import SwiftUI

extension PlaceRoutineScreen {
    /// Opens a step's destination through the shared `PlaceLinkOpener`, notifying rather than
    /// alerting when the app it names is not installed.
    func openExternally(_ url: URL, failureBody: String) {
        PlaceLinkOpener(
            open: { url, universalLinksOnly, completion in
                UIApplication.shared.open(
                    url,
                    options: universalLinksOnly ? [.universalLinksOnly: true] : [:],
                    completionHandler: completion
                )
            },
            notifyFailure: { body in
                Task {
                    await NotificationCenterImmediateNotifier().post(
                        title: "That didn't open", body: body,
                        identifier: "placeActionOpenFailure"
                    )
                }
            }
        ).run(PlaceLinkOpenPlan.plan(for: url), failureBody: failureBody)
    }
}
