//
//  LogComposerView+Ink.swift
//  ADHD LifeOS
//
//  `F-JournalPad`'s wardrobe, read out of the composer itself: which ink this screen's quiet
//  labels take, and which chips its controls wear, for whichever kind is being written.
//
//  **Split out under SwiftLint's 250-line type-body ceiling** when `F-C2-DraftsToInbox` added the
//  draft-filing path. These three belong together — every one of them is a
//  `JournalComposerPalette` lookup keyed on `composerType`, and the failure they exist to prevent
//  is a page where SOME labels find the ink and others silently take half of it.
//

import SwiftUI

extension LogComposerView {
    /// The ink every QUIET label on this screen resolves to — section eyebrows, the "optional"
    /// suffix, the explainer, the footer line. `nil` on the ordinary page, so it keeps exactly the
    /// `.secondary` it has always had.
    ///
    /// One property rather than per-label decisions, because the failure it exists to prevent was
    /// precisely a page where SOME labels found the ink and others silently took half of it.
    var softInk: String? {
        JournalComposerPalette.softInkAsset(for: journalService.composerType)
    }

    /// The ink for text on the CHROME rather than on the page — the pinned footer's line. Not the
    /// same as `softInk`: at night the page stays gold while the desk goes near-black.
    var chromeInk: String? {
        JournalComposerPalette.chromeInkAsset(for: journalService.composerType)
    }

    /// The wardrobe for whichever kind is being written — see `ComposerChipPalette`.
    var chips: ComposerChipPalette {
        JournalComposerPalette.chipPalette(for: journalService.composerType)
    }
}
