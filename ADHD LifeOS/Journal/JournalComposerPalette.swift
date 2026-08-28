//
//  JournalComposerPalette.swift
//  ADHD LifeOS
//

import SwiftUI

/// Which surface the new-entry composer wears, decided by the kind of entry being written
/// (E, 2026-08-28: journal entries get a yellow background, logs stay exactly as they are).
///
/// Pure, and returning an ASSET NAME rather than a colour value, for the reason §4 gives: no
/// colour is spelled in Swift, and SwiftUI's built-in hues trip the `raw_hue_color` lint rule
/// outright. (That rule reads comments too — naming the built-in yellow in this sentence flagged
/// the file, which is how it should behave.)
///
/// The yellow lives in the token layer as `JournalPaper`. **Light is E's own hex, `#FFDA03`** —
/// the first cut used a cream (`#FDF6DF`) and E was right to reject it: on a screen it read as
/// off-white paper, not as yellow at all.
///
/// Dark is `#7A6000`, the same hue taken down until white body text clears WCAG AA against it
/// (~5.8:1). `#FFDA03` cannot be used there: this app's dark mode draws text in white, and white
/// on that yellow is about 1.5:1 — unreadable, not merely ugly. The only way to put the full
/// brightness in dark mode is to make the composer an always-light surface with dark ink in both
/// appearances, which is a bigger change than a token and is E's call, not this file's.
enum JournalComposerPalette {
    /// A `switch` rather than a ternary so a third `LogType` cannot silently inherit whichever
    /// branch it happened to fall into — it has to decide what it looks like.
    static func backgroundAsset(for type: LogType) -> String {
        switch type {
        case .log: return "PageBackground"
        case .journal: return "JournalPaper"
        }
    }
}
