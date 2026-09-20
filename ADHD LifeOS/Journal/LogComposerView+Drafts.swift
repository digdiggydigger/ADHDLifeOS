//
//  LogComposerView+Drafts.swift
//  ADHD LifeOS
//
//  `F-C2-DraftsToInbox`: the journal composer's half of "unsent text goes to the inbox".
//
//  **Its own file because `LogComposerView` is at SwiftLint's 250-line type-body ceiling**, the
//  same pressure that produced `TaskCreateView+Drafts.swift`. The members it reaches for are
//  internal rather than private for the usual reason: Swift `private` is file-scoped, so the pair
//  is the unit.
//

import SwiftUI

extension LogComposerView {
    /// Files an abandoned entry and CLEARS the composer, in that order.
    ///
    /// **The clear is the spec's named trap.** `composerBody` lives on `JournalService`, which
    /// outlives this view, so filing without clearing would leave the same words in two places —
    /// once as a capture in the inbox and once waiting in the service for the next time the
    /// composer opens, where the user would meet text they had already been told was filed.
    ///
    /// **Cleared only if the write LANDED.** `fileIfNeeded` answers `false` when it did not, and
    /// clearing then would destroy the only copy of the thought — the precise outcome this arc
    /// exists to prevent.
    ///
    /// **Only the body.** The type, energy, mood and tag chips are dropped, which is the spec's
    /// accepted cost: a filed draft is an ordinary `.note`.
    func fileDraftIfNeeded() {
        guard !didSubmit, let captureClient else { return }
        let text = journalService.composerBody
        let filer = ComposerDraftFiler(
            client: captureClient, record: recordAction, openCapture: openCapture
        )
        Task {
            if await filer.fileIfNeeded(text) {
                journalService.composerBody = ""
            }
        }
    }
}
