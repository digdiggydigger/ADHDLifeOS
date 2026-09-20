//
//  TaskCreateView+Drafts.swift
//  ADHD LifeOS
//
//  `F-C2-DraftsToInbox`: the task composer's half of "unsent text goes to the inbox".
//
//  **Its own file because `TaskCreateView` is at SwiftLint's 250-line type-body ceiling** — the
//  same pressure that produced `TaskDetailFormSections.swift`, and the reason the members this
//  needs are internal rather than private (Swift `private` is file-scoped, so the pair is the
//  unit and nothing outside it should reach in).
//

import SwiftUI

extension TaskCreateView {
    /// Files an abandoned title — E, round 2: *"A composer closed with text files it into the
    /// Capture Inbox as a note."*
    ///
    /// **Only the title.** The due choice, area, place, notes and tags are dropped, which is the
    /// spec's accepted cost named out loud: a filed draft is an ordinary `.note`, matching what a
    /// fan-opened Task capture already looks like in the inbox rather than a richer draft object
    /// nothing else knows how to read.
    ///
    /// **Nothing happens without a `captureClient`**, and that is deliberate rather than
    /// defensive: the argument is optional so every preview builds unchanged, and the app's own
    /// two call sites are asserted by `ComposerDraftCallSiteTests` instead.
    func fileDraftIfNeeded() {
        guard !didSubmit, let captureClient else { return }
        let text = service.title
        let filer = ComposerDraftFiler(
            client: captureClient, record: recordAction, openCapture: openCapture
        )
        Task { await filer.fileIfNeeded(text) }
    }
}
