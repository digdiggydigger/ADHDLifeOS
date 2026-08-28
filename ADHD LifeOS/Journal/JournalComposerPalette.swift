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
/// The yellow lives in the token layer as `JournalPaper`, and it took three passes and two real
/// renders to land:
///
/// 1. `#FDF6DF` — a cream. E rejected it on device and was right: it read as off-white paper,
///    not as yellow at all.
/// 2. `#FFDA03` — E's own hex, and genuinely yellow, but a pure lemon at full bleed reads as a
///    highlighter rather than a page.
/// 3. `#DAA520` — E's other hex, goldenrod. Rendered side by side with the lemon it is plainly
///    the better one at this size: warmer, richer, and white cards sit ON it instead of glaring
///    against it.
///
/// SINGLE colour, no dark variant, because the composer forces the light appearance — see
/// `forcesLightAppearance`.
enum JournalComposerPalette {
    /// A `switch` rather than a ternary so a third `LogType` cannot silently inherit whichever
    /// branch it happened to fall into — it has to decide what it looks like.
    static func backgroundAsset(for type: LogType) -> String {
        switch type {
        case .log: return "PageBackground"
        case .journal: return "JournalPaper"
        }
    }

    /// Whether the composer renders in the LIGHT appearance regardless of the device setting.
    ///
    /// This is what makes a real yellow possible at all, and it took two rounds on device to
    /// arrive at. A yellow dimmed until white text clears AA stops being yellow — it reads as
    /// mustard, which E saw and rejected. A yellow bright enough to look like yellow puts this
    /// app's white dark-mode text at roughly 1.5:1, which is unreadable. There is no dark-mode
    /// yellow that is both.
    ///
    /// So the journal composer is a physical object rather than a themed screen: a gold pad with
    /// dark ink and white cards, the same in both appearances, the way a legal pad does not turn
    /// grey when the lights go off. Forcing the appearance on the SUBTREE brings every child —
    /// chips, pickers, the footer — along without touching a single shared component.
    static func forcesLightAppearance(for type: LogType) -> Bool {
        type == .journal
    }

    /// Whether the pinned footer wears the page colour rather than the standard bar material.
    ///
    /// `.bar` is a translucent system material: over gold it rendered as a washed-out band with a
    /// visible seam, which is exactly the mismatch E flagged. On the pad the footer is simply more
    /// pad, with the hairline doing the separating.
    static func footerMatchesPage(for type: LogType) -> Bool {
        type == .journal
    }

    /// The writing box's fill. Grey-blue (`CardSurfaceSecondary`) is right on the ordinary page
    /// and was the single worst thing on gold — it read as a bruise. On the pad it is white, so
    /// the box you type into looks like the paper it is sitting on.
    static func writingSurfaceAsset(for type: LogType) -> String {
        type == .journal ? "CardSurface" : "CardSurfaceSecondary"
    }
}

/// The composer's pinned footer: page-coloured on the journal pad, standard bar material on the
/// ordinary page. A modifier rather than an `if` at the call site, so the two branches cannot
/// drift into different padding or a missing hairline.
struct ComposerFooterBackground: ViewModifier {
    let type: LogType

    func body(content: Content) -> some View {
        if JournalComposerPalette.footerMatchesPage(for: type) {
            content
                .background(Color(JournalComposerPalette.backgroundAsset(for: type)))
                .overlay(alignment: .top) { Color.cardBorder.frame(height: 1) }
        } else {
            content.composerFooterSurface()
        }
    }
}
