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
/// 4. E, 2026-08-28, after seeing the night face rendered: rather than keep hunting for a gold
///    that survives the dark appearance, redesign what SURROUNDS it. The clash was never one wrong
///    yellow — it was a warm page wearing a cool wardrobe (a blue accent at goldenrod's near-exact
///    complement, cool-grey quiet chips, a cool near-black writing box). Widen the change and the
///    contrast ceiling moves. See `chipPalette(for:)` and `chromeAsset(for:)`.
enum JournalComposerPalette {
    /// A `switch` rather than a ternary so a third `LogType` cannot silently inherit whichever
    /// branch it happened to fall into — it has to decide what it looks like.
    static func backgroundAsset(for type: LogType) -> String {
        switch type {
        case .log: return "PageBackground"
        case .journal: return "JournalPaper"
        }
    }

    /// Whether this kind of entry gets the pad's paper treatment at all — the ruling, the ink,
    /// the page. Journal only; a Log is a quick line on the ordinary screen.
    ///
    /// The pad now has TWO faces rather than one forced light one (E, 2026-08-28: "do the legal
    /// pad treatment for dark mode"). The earlier version rendered the light face whatever the
    /// device was set to, which was defensible — a legal pad does not turn grey when the lights go
    /// off — but it meant a bright gold page at night, and no night face at all.
    ///
    /// The night face is a real pad in the dark rather than a dimmed version of the day one, and
    /// that distinction is forced by contrast rather than taste. Dimming the gold far enough to be
    /// comfortable at night drags dark ink under 4.5:1 against it — measured, not guessed: ink
    /// `#4A3506` on a dimmed `#A97C10` is about 3.1:1. So the night page goes properly dark
    /// (`#2A2109`, warm brown-black) and the ink inverts to parchment (`#F2E2B8`, ~13:1), with the
    /// same gold ruling lifted to 32% so it still reads. Same object, lights off.
    static func isPaper(for type: LogType) -> Bool {
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

    /// The colour every label on the page resolves against.
    ///
    /// System grey on gold reads as mud — E saw it and said the text gets lost. Warm ink
    /// (`#4A3506`) clears AA against the pad at about 5:1 and belongs to the same world as the
    /// paper. `LabelPrimary` on the ordinary page, which is exactly what it already was.
    static func inkAsset(for type: LogType) -> String {
        type == .journal ? "JournalPaperInk" : "LabelPrimary"
    }

    /// The writing box's fill. Grey-blue (`CardSurfaceSecondary`) is right on the ordinary page
    /// and was the single worst thing on gold — it read as a bruise. On the pad it is
    /// `CardSurface`, which is white by day and near-black by night: the sheet you write on,
    /// either way.
    static func writingSurfaceAsset(for type: LogType) -> String {
        type == .journal ? "JournalPaperSurface" : "CardSurfaceSecondary"
    }

    /// The desk the pad sits on.
    ///
    /// In LIGHT this is the pad's own gold, so the page still reads full-bleed and the day face E
    /// approved is untouched. At night it goes dark and the same structure becomes a lit pad on a
    /// dark desk. One layout, two appearances, decided entirely in the token layer — there is no
    /// `colorScheme` branch in this file, and there must not be one.
    static func chromeAsset(for type: LogType) -> String {
        type == .journal ? "JournalPaperChrome" : "PageBackground"
    }

    /// Secondary text on the pad, and it is deliberately the SAME ink as primary.
    ///
    /// Arithmetic, not preference: the ink clears AA against the gold at about 5.2:1, so anything
    /// dimmed from it falls under 4.5:1 — `#6B4E12` on `#DAA520` measures 3.45:1. A mid-tone
    /// saturated ground simply has no room for a second, quieter ink. So hierarchy on this page
    /// comes from type weight and size (§1) rather than from a lighter colour or an opacity (§4),
    /// which is what those rules ask for anyway.
    static func softInkAsset(for type: LogType) -> String {
        type == .journal ? inkAsset(for: type) : "LabelSecondary"
    }

    /// The writing box's prompt. The SHEET has headroom the gold page does not — the ink clears
    /// about 9.5:1 there — so this is the one place on the pad where a genuinely quieter colour
    /// can live and still pass AA (`#6B5220` measures 5.98:1 on the day sheet, 5.61:1 at night).
    /// The system placeholder is near-white and simply vanished on warm paper.
    static func placeholderAsset(for type: LogType) -> String? {
        type == .journal ? "JournalPaperPlaceholder" : nil
    }

    /// The chip wardrobe. Selection on the pad is MONOCHROME (E's call, 2026-08-28): a chosen chip
    /// fills with the pad's own ink and labels itself in the page colour, so it reads as something
    /// written on the page rather than a control pasted onto it — and it introduces no new hue to
    /// keep in agreement with the gold.
    static func chipPalette(for type: LogType) -> ComposerChipPalette {
        type == .journal ? .pad : .ordinary
    }
}

/// What a composer's chips wear. Value type rather than scattered asset names so the pad and the
/// ordinary page cannot drift into half-states — every call site takes the whole wardrobe or none
/// of it.
///
/// `ComposerAreaChips` is shared with task-create and capture triage, which must keep the app
/// accent; `.ordinary` is the default so those screens are unchanged by construction.
struct ComposerChipPalette: Equatable {
    let quietSurface: String
    let quietLabel: String
    let selectedFill: String
    let selectedLabel: String

    static let ordinary = ComposerChipPalette(
        quietSurface: "CardSurfaceSecondary",
        quietLabel: "LabelSecondary",
        selectedFill: "AccentColor",
        selectedLabel: "OnAreaWork"
    )

    static let pad = ComposerChipPalette(
        quietSurface: "JournalPaperSurface",
        quietLabel: "JournalPaperInk",
        selectedFill: "JournalPaperInk",
        selectedLabel: "JournalPaper"
    )
}

/// The composer's pinned footer: page-coloured on the journal pad, standard bar material on the
/// ordinary page. A modifier rather than an `if` at the call site, so the two branches cannot
/// drift into different padding or a missing hairline.
struct ComposerFooterBackground: ViewModifier {
    let type: LogType

    func body(content: Content) -> some View {
        if JournalComposerPalette.footerMatchesPage(for: type) {
            content
                // The CHROME, not the page. The pad is inset now, so a page-coloured footer ran
                // full width underneath it and swallowed its bottom corners — the pad stopped
                // looking like an object exactly where it should have ended (E's render,
                // 2026-08-28). In light the chrome IS the page gold, so the day face is unchanged.
                .background(Color(JournalComposerPalette.chromeAsset(for: type)))
                .overlay(alignment: .top) { Color.cardBorder.frame(height: 1) }
        } else {
            content.composerFooterSurface()
        }
    }
}
