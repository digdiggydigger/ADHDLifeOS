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
    /// `#4A3506` on a dimmed `#A97C10` is about 3.1:1.
    ///
    /// The dark-PAGE answer that reasoning points at (a `#2A2109` page with parchment `#F2E2B8`
    /// ink) was written up here for a while and never shipped — E chose the other exit. What ships,
    /// and what was measured off E's device on 2026-08-28, is that the pad KEEPS its gold at night:
    /// `JournalPaper` dark is `#C99A1E`, a shade off the day face rather than a fifth of it, and
    /// the DESK behind it goes near-black (`JournalPaperChrome` `#1A1610`). That reuses the day
    /// face's proven gold-and-dark-ink pairing — 5.25:1 at night against 5.20:1 by day — instead of
    /// hunting in the mid-tone valley where no ink passes. Same object, lights off, lamp still on
    /// it. The gold ruling sits at 32% at night against 22% by day so it still reads.
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

    /// The pinned footer's own surface — a LIFTED bar, not the desk it sits on.
    ///
    /// E marked this band up on a device shot of the night pad (2026-08-28): "it should not be jet
    /// black … it's very abrupt to view". The measurement agrees, and the app had already answered
    /// the question elsewhere: the ORDINARY composer lifts its footer above its own page
    /// (`#2C2E32` on `#15171C`, a step of 1.32:1). The gold pad was the only screen painting its
    /// footer with the desk instead, which meant stepping DOWN from the page by 6.97:1 — five
    /// times the house cliff, and precisely the abruptness E saw.
    ///
    /// **It wears the DESK, and that is now the whole answer** (E, 2026-08-29: "do the header and
    /// gutters too").
    ///
    /// For one day this was its own token, lifted off a jet-black desk, because E had marked up
    /// only this band. Once the whole surround lifts, that split stops earning anything: the two
    /// values could never differ, and two tokens that can never differ are drift-bait. The bar is
    /// already told apart by its hairline and by the cream Save button standing on it.
    ///
    /// The lift moved into `JournalPaperChrome` instead — dark `#1A1610` -> `#332C20` — so the
    /// header band, the pad's side gutters and this bar are one warm desk. See `chromeAsset(for:)`.
    ///
    /// Kept as a named accessor rather than inlined, so `testThePadsFooterWearsTheDesk` has
    /// something to assert: a future re-split fails that test and has to write its reasoning down.
    static func footerSurfaceAsset(for type: LogType) -> String? {
        isPaper(for: type) ? chromeAsset(for: type) : nil
    }

    /// The ink for text on the CHROME — the desk, not the page — which today is the pinned
    /// footer's one line.
    ///
    /// A separate token because the chrome does not track the page: in light it IS the pad's gold,
    /// but at night it goes near-black while the page stays gold. Painting the footer with the
    /// PAGE ink was tried and measured before it shipped — `#3D2B05` on the night chrome `#1A1610`
    /// is **1.33:1**, i.e. an invisible line — while the same ink on the day chrome is a healthy
    /// 5.20:1. That asymmetry is exactly what a light-only or a render-only check misses.
    ///
    /// So the ink follows the surface: `#4A3506` on gold by day (5.20:1), parchment `#EFE0B4` on
    /// near-black by night (13.71:1).
    static func chromeInkAsset(for type: LogType) -> String? {
        isPaper(for: type) ? "JournalPaperChromeInk" : nil
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
    /// `JournalPaperSurface`: warm parchment in BOTH appearances (`#F5E7C0` by day, `#EFE0B4` at
    /// night) rather than a surface that flips to near-black. Deliberate — the sheet is where this
    /// screen's contrast headroom lives (ink clears 9.47:1 on it by day and 10.34:1 at night,
    /// against only ~5.2:1 on the page itself), and inverting it at night would throw that away.
    static func writingSurfaceAsset(for type: LogType) -> String {
        type == .journal ? "JournalPaperSurface" : "CardSurfaceSecondary"
    }

    /// The desk the pad sits on.
    ///
    /// In LIGHT this is the pad's own gold, so the page still reads full-bleed and the day face E
    /// approved is untouched. At night it goes dark and the same structure becomes a lit pad on a
    /// dark desk. One layout, two appearances, decided entirely in the token layer — there is no
    /// `colorScheme` branch in this file, and there must not be one.
    ///
    /// **The night desk is `#332C20`, not a near-black** (E, 2026-08-29, after marking up the
    /// footer band on a device shot: "it should not be jet black … it's very abrupt to view", then
    /// "do the header and gutters too"). It was `#1A1610`, which put a 6.97:1 cliff between the
    /// gold page and everything around it — where the ORDINARY composer steps only 1.32:1 between
    /// its page and its footer. The pad was the outlier, so the desk moved to match the house step:
    /// a 1.31:1 lift, warm at hue 38° so no cool grey returns to this screen, and at 23% saturation
    /// against the ink's 85% it stays a surface rather than reading as ink. The drop from the page
    /// softens to 5.47:1, which still leaves the pad plainly an object on a desk, and the parchment
    /// chrome ink clears 10.51:1 against it.
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
    ///
    /// **This returned `"LabelSecondary"` for a log, and was dead code for BOTH kinds — no view
    /// ever called it, and the pad shipped with dimmed labels as a result** (E's device shots,
    /// 2026-08-28: every `.secondary` label on the page measured 2.13:1 by day and 2.18:1 at
    /// night, against a 4.5 bar, because `.foregroundStyle(.secondary)` under a container that
    /// sets a plain `Color` inherits that colour at roughly HALF alpha rather than inheriting it).
    ///
    /// Why the opt-out is `nil` and not a colour: an opaque `LabelSecondary` is not what
    /// `.foregroundStyle(.secondary)` paints, so wiring the old shape up would have restyled the
    /// ordinary composer as a side effect of fixing the pad. `nil` means "keep exactly what you
    /// already do", so only the pad opts in — the containment F-PadBalance used for the wardrobe.
    static func softInkAsset(for type: LogType) -> String? {
        isPaper(for: type) ? inkAsset(for: type) : nil
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
    /// The ink for the QUIET text AROUND the chips — a section eyebrow, a chip's sublabel. `nil`
    /// leaves the caller's existing `.secondary` untouched, which is what every screen but the pad
    /// wants; see `JournalComposerPalette.softInkAsset(for:)` for why the opt-out is `nil`.
    let softInk: String?

    static let ordinary = ComposerChipPalette(
        quietSurface: "CardSurfaceSecondary",
        quietLabel: "LabelSecondary",
        selectedFill: "AccentColor",
        selectedLabel: "OnAreaWork",
        softInk: nil
    )

    static let pad = ComposerChipPalette(
        quietSurface: "JournalPaperSurface",
        quietLabel: "JournalPaperInk",
        selectedFill: "JournalPaperInk",
        selectedLabel: "JournalPaper",
        softInk: "JournalPaperInk"
    )
}

/// The composer's pinned footer: page-coloured on the journal pad, standard bar material on the
/// ordinary page. A modifier rather than an `if` at the call site, so the two branches cannot
/// drift into different padding or a missing hairline.
struct ComposerFooterBackground: ViewModifier {
    let type: LogType

    /// `footerMatchesPage(for:)` and `footerSurfaceAsset(for:)` are both `isPaper`, so inside the
    /// branch below the fallback is unreachable — it is here to keep this total rather than to
    /// force-unwrap something that is only conditionally true by coincidence of two predicates.
    private var surfaceAsset: String {
        JournalComposerPalette.footerSurfaceAsset(for: type)
            ?? JournalComposerPalette.chromeAsset(for: type)
    }

    func body(content: Content) -> some View {
        if JournalComposerPalette.footerMatchesPage(for: type) {
            content
                // Its OWN lifted surface — not the page, and no longer the desk either.
                //
                // Not the page: the pad is inset, so a page-coloured footer ran full width
                // underneath it and swallowed its bottom corners, and the pad stopped looking like
                // an object exactly where it should have ended (E's render, 2026-08-28).
                //
                // Not the desk: that made the night footer jet black, a 6.97:1 step DOWN from the
                // page where the ordinary composer steps 1.32:1 UP from its own — five times the
                // cliff, which is what E marked up as abrupt. See `footerSurfaceAsset(for:)`.
                //
                // In light this token is byte-identical to the chrome, so the day face is unchanged.
                .background(Color(surfaceAsset))
                .overlay(alignment: .top) { Color.cardBorder.frame(height: 1) }
        } else {
            content.composerFooterSurface()
        }
    }
}
