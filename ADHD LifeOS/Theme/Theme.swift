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
}

/// Room to keep clear of the global capture disc.
///
/// The FAB is a fixed overlay above the tab bar, so ANY pinned bar or bottom-of-scroll content
/// lands underneath it. This was first hit on the journal composer bar (E's screenshot,
/// 2026-08-25) and again on the inbox's Sorted button and undo bar (E's screenshots,
/// 2026-08-28) — where it made the undo bar's own Undo button unreachable.
///
/// 60pt disc + its 16pt trailing margin + an 8pt breathing gap.
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
    static let pillWidth: CGFloat = 52
    static let pillHeight: CGFloat = 32
    static let pillGlyphScale: CGFloat = 0.8

    /// E's number, chosen off the device GIF (2026-08-30): "try .68 — just below the 0.7 sweet
    /// spot." The GIF showed the OPAQUE pill still swallowing whatever scrolls through the
    /// trailing corner (a nudges chip, a capture row's edge); at 0.68 that content reads
    /// through it, and the regrow's fade-in starts from visibly glassy. Below ~0.5 the pill
    /// would read as disabled — keep taste changes above that floor.
    static let pillOpacity: CGFloat = 0.68

    /// Derived from the REST state deliberately: the pill is transient, and the last row of
    /// every scroll still has to clear the full disc it settles back into.
    static let clearance: CGFloat = discDiameter + 16 + 8
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
    func captureDiscClearance() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            // Non-hit-testable, or this reserved strip would swallow taps on the rows that scroll
            // up through it — the exact reachability problem it exists to fix.
            Color.clear
                .frame(height: CaptureDiscMetrics.clearance)
                .allowsHitTesting(false)
        }
    }
}
