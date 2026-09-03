//
//  Theme.swift
//  ADHD LifeOS
//

import SwiftUI

// The design-token layer. Re-valued 2026-08-24 for the Momentum v3 redesign (Claude Design
// handoff, E's palette Option A): the prototype's coral is gone, colour now carries two jobs and
// never both at once —
// - STATE: StateGo/StateWarn/StateRisk (+Vivid fill variants) — closed / at-risk / overdue.
// - IDENTITY: five per-area hue families, resolved by `AreaPalette` (its own file).
// Surfaces (PageBackground, CardSurface(+Secondary), BarSurface, CardBorder), labels
// (LabelPrimary/Secondary/Tertiary), tracks and Scrim complete the set. CLAUDE.md §4 holds: every
// hex lives ONLY in the asset catalog's colorsets, always with light+dark variants; light-mode
// label hues are darkened separately from their Vivid fill twins so text stays WCAG-readable.

// NOTE: no manual `extension Color` for the surface tokens — Xcode's asset-symbol generation
// already synthesizes `Color.cardSurface`, `Color.pageBackground`, `Color.cardBorder` and the
// rest from the colorsets; declaring them again is an invalid redeclaration.

/// Three urgency bands, four priorities: p2 and p3 fold into the medium band (the chip's P1–P4
/// text keeps them distinguishable). Since Momentum v3 the bands point at the shared State
/// tokens — the legacy Urgency colorsets are gone. Locked by `UrgencyPaletteTests`.
enum UrgencyPalette {
    static func assetName(for priority: TaskPriority) -> String {
        switch priority {
        case .p1: return "StateRisk"
        case .p2, .p3: return "StateWarn"
        case .p4: return "StateGo"
        }
    }

    static func color(for priority: TaskPriority) -> Color {
        Color(assetName(for: priority))
    }
}

// MARK: - Bento card

/// The shared card treatment, now in v3's language: 16pt continuous corners, the `CardSurface`
/// token, a 1pt `CardBorder` stroke (v3 draws a visible 1px border, not a hairline), 16pt inner
/// padding, and the §5 soft diffusion shadow. One modifier so every card stays in lockstep.
private struct BentoCardModifier: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

/// The same card, for something that is ASKING rather than merely present.
///
/// E's 2026-08-28 call: Today's nudges door was raised out of a grey footer into a real card, and
/// a due nudge has to keep outranking it — two cards of equal weight say "these matter equally",
/// which on this screen is the wrong signal. The warn tint and its matching border are what put a
/// due nudge above the quiet door below it.
///
/// The tint is an ALPHA over the card surface rather than its own colorset: it has to sit on the
/// same surface in both appearances, and `StateWarn` is already the app's one "wants attention"
/// hue (the inbox chip, the inbox headline, the nudges eyebrow). A second baked token would be a
/// second thing to keep in agreement with it.
private struct UrgentBentoCardModifier: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Tint FIRST, surface behind it: chained `.background` stacks backwards, so the
            // opaque surface must be the OUTER one or it paints over the tint entirely.
            .background(
                Color("StateWarn").opacity(0.10),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color("StateWarn").opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func bentoCard(padding: CGFloat = 16) -> some View {
        modifier(BentoCardModifier(padding: padding))
    }

    /// A bento card carrying the "wants attention" treatment — see `UrgentBentoCardModifier`.
    func urgentBentoCard(padding: CGFloat = 16) -> some View {
        modifier(UrgentBentoCardModifier(padding: padding))
    }

    /// v3's section-header treatment: bold SANS caption, uppercase, letterspaced (700 11px,
    /// .1em in the handoff). Mono is reserved for system metadata now — "Space Mono → SF" is an
    /// explicit v3 note. Font stays semantic (`.caption2`), so Dynamic Type scaling holds (§1).
    func sectionLabel() -> some View {
        font(.caption2.weight(.bold))
            .tracking(1.1)
            .textCase(.uppercase)
    }

    /// `sectionLabel()` for a header that PINS — one treatment, so a screen with a sticky list
    /// cannot invent its own (F-Tools-4-Headers).
    ///
    /// **The defect this replaces, measured rather than described.** Both pinned headers wore
    /// `.background(.bar)`. On the iPhone 17 render a row through the header and a row through
    /// the card below it gave:
    ///
    ///     header  x 16.0 → 386.0pt   #F9F9F9   (`.bar`)
    ///     card    x 16.0 → 386.0pt   #FFFFFF   (`CardSurface`, 16pt continuous corners)
    ///     page                       #F0F3F6   (`PageBackground`)
    ///
    /// So the strip was a THIRD surface — neither page nor card — spanning the card's exact
    /// width with SQUARE corners, resting on a 16pt-rounded card. Nine units off the page is too
    /// little to read as a deliberate surface and too much to disappear. E's word was
    /// "unfinished", and that is what unfinished looks like.
    ///
    /// **And `.bar` was never opaque, which both call sites' own comments claimed it was.** Each
    /// said, in as many words, that the header is "opaque on purpose" because a transparent one
    /// lets the rows sliding under it show through its letters. `.bar` is a MATERIAL — it blurs
    /// what is behind it rather than hiding it. Scrolled so a row sits beneath the pinned header,
    /// and sampling the band to the RIGHT of the label where no header text exists at all:
    ///
    ///     before   43–59 distinct colour bands   (the row underneath, showing through)
    ///     after     1 band, #F0F3F6              (the page)
    ///
    /// The comment named the exact defect it was failing to prevent, and nothing checked it —
    /// `PinnedSectionHeaderTests` now asserts the surface resolves at alpha 1.
    ///
    /// **The fix is subtraction.** The header is painted the PAGE: opaque for the first time, and
    /// the rectangle stops existing, because its fill and the 16pt gutters either side of it are
    /// now the same colour. A pinned header ends up looking exactly like every other
    /// `sectionLabel()` in the app, which is the point: sticky is a behaviour, not a costume.
    ///
    /// Applied to the header's `Text`; the caller keeps its own `foregroundStyle`, because the
    /// Tasks board's buckets speak in colour (warn / motion / closure) and the app picker's do
    /// not. `PinnedSectionHeaderCallSiteTests` enumerates the call sites — a shared treatment
    /// nothing calls is this repo's most repeated defect.
    func pinnedSectionHeader() -> some View {
        sectionLabel()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, PinnedHeaderMetrics.verticalPadding)
            .background(Color(PinnedHeaderMetrics.surfaceAssetName))
    }
}

/// The pinned header's two numbers, spelled once so the treatment and its tests cannot disagree.
enum PinnedHeaderMetrics {
    /// §2 spacing, not a component dimension — so unlike `AppTabBarMetrics.rowHeight`, the
    /// 4/8/16/24 grid governs it. 8 gives the letters room from the card that stops beneath them
    /// without the header costing a group separation's worth of scroll on every screen.
    static let verticalPadding: CGFloat = 8

    /// **The page, deliberately, and this is the whole decision.** See `pinnedSectionHeader()`
    /// for the measurement. Any other fill re-creates the strip: a header is visible as a shape
    /// only when it disagrees with what surrounds it.
    static let surfaceAssetName = "PageBackground"
}

/// Room to keep clear of the global capture disc.
///
/// The FAB is a fixed overlay above the tab bar, so ANY pinned bar or bottom-of-scroll content
/// lands underneath it. This was first hit on the journal composer bar (E's screenshot,
/// 2026-08-25) and again on the inbox's Sorted button and undo bar (E's screenshots,
/// 2026-08-28) — where it made the undo bar's own Undo button unreachable.
///
/// 60pt disc + its 24pt edge margin + an 8pt breathing gap.
enum CaptureDiscMetrics {
    /// The disc at rest. RootView reads this — the disc's size and the clearance below must
    /// move together, so the measurement is spelled once.
    static let discDiameter: CGFloat = 60

    /// The disc mid-scroll (F-DiscPill, E's call 2026-08-30): a small capsule, so the content
    /// the user is actually scrolling through shows past it. Visual only — the button's outer
    /// frame stays `discDiameter` square, keeping the ≥44pt hit target (§3) and the overlay
    /// stack's layout untouched in both states.
    ///
    /// Sized by E's device verdict (F-PillTune): the first cut, 40×24, "is too small" — a
    /// sliver rather than a button. 52×32 stays clearly smaller than the disc it stands in for.
    /// 60 after E's fourth pass (2026-08-31): "add more padding to the left-hand & right-hand
    /// sides… goto 4pt" — 4pt per side over the 52 it launched at. Width now fills the disc's
    /// own slot, so the pill-vs-disc distinction rides entirely on HEIGHT (48 vs 60), which
    /// the guard test holds strictly.
    static let pillWidth: CGFloat = 60
    /// 48 after two device passes (2026-08-31), each E asking for more room above and below
    /// the plus: 32 → 40 ("ADD more spacing/padding to the top and bottom"), then 40 → 48
    /// ("ONLY ADD a little bit more padding to the TOP and the BOTTOM").
    static let pillHeight: CGFloat = 48
    static let pillGlyphScale: CGFloat = 0.8

    /// E's number, chosen off the device GIF (2026-08-30): "try .68 — just below the 0.7 sweet
    /// spot." The GIF showed the OPAQUE pill still swallowing whatever scrolls through the
    /// trailing corner (a nudges chip, a capture row's edge); at 0.68 that content reads
    /// through it, and the regrow's fade-in starts from visibly glassy. Below ~0.5 the pill
    /// would read as disabled — keep taste changes above that floor.
    static let pillOpacity: CGFloat = 0.68

    /// The disc's distance from the trailing screen edge — and, since E's 2026-08-31 margin
    /// pass raised the disc by the same 8pt the margin grew, the number that keeps the
    /// clearance sum true on BOTH axes at once.
    static let edgeMargin: CGFloat = 24

    /// Derived from the REST state deliberately: the pill is transient, and the last row of
    /// every scroll still has to clear the full disc it settles back into.
    static let clearance: CGFloat = discDiameter + edgeMargin + 8
}

extension View {
    /// Bottom room for the capture disc, on a scrolling screen that lives INSIDE the tab bar.
    ///
    /// The metric above had said since 2026-08-25 that any bottom-of-scroll content lands under
    /// the disc, and two screens out of ten acted on it — so on the other eight the last row sat
    /// under an opaque 60pt circle permanently, with nothing below it to scroll to. E hit it on
    /// the nudges screen, whose last row is the only way to create a nudge (2026-08-29).
    ///
    /// `safeAreaInset` rather than `.padding(.bottom,)`, so this works on a `Form` and a `List`
    /// (whose rows are not ours to pad) as well as on a `ScrollView`, and so one spelling serves
    /// every screen — see `CaptureDiscClearanceCallSiteTests` for why that matters here.
    /// Applied OUTSIDE the scroll container, which is what makes it an inset rather than content.
    ///
    /// Not for sheets or full-screen covers: they are presented above the disc and hide it.
    ///
    /// **`hasSearchRow` (F-Search-1-Row).** Three screens now also carry the bottom search row,
    /// which sits in this same band, and they need more room than the eight that do not. The
    /// parameter defaults to `false` so every existing call site keeps its exact meaning, and the
    /// extra is DERIVED in `AppSearchRowMetrics.clearance(hasSearchRow:)` rather than typed a
    /// second time — a second literal is how the two drift the first time the field's height moves.
    func captureDiscClearance(hasSearchRow: Bool = false) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            // Non-hit-testable, or this reserved strip would swallow taps on the rows that scroll
            // up through it — the exact reachability problem it exists to fix.
            Color.clear
                .frame(height: AppSearchRowMetrics.clearance(hasSearchRow: hasSearchRow))
                .allowsHitTesting(false)
        }
    }
}
