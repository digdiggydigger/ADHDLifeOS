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

extension View {
    func bentoCard(padding: CGFloat = 16) -> some View {
        modifier(BentoCardModifier(padding: padding))
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
