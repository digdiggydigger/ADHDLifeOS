//
//  Theme.swift
//  ADHD LifeOS
//

import SwiftUI

// The design-token layer, added 2026-08-19 at E's direction to mirror the Google AI Studio /
// React prototype's palette (`src/index.css`, `src/utils/areaColors.ts`):
//
//   --accent #FF5B5B · --bg #F8F7F4 · --card-light #EFECE8 · --bg-dark #111113 · border black/5
//   urgency: high #FF5B5B · medium amber-500 #F59E0B · low emerald-500 #10B981
//
// CLAUDE.md §4 ("zero hex declarations") is honoured in the letter that matters: the hex values
// live ONLY in the asset catalog's colorsets — with dark-mode variants, so every token stays
// adaptive — and views reference these named tokens, never raw colour values. Two deliberate
// §4-flavoured deviations, per E's parity direction, flagged in the build report:
// - #FF5B5B on white is ~3.3:1 — below WCAG AA for small text (the prototype ships this
//   contrast everywhere); coral text is therefore kept to bold caption-weight labels.
// - Body text stays `.primary`/`.secondary`, NOT the prototype's ink #1C1C1A — tokenising text
//   colour would defeat Increase Contrast / Smart Invert for no visible parity gain.

// NOTE: no manual `extension Color` for the surface tokens — Xcode's asset-symbol generation
// already synthesizes `Color.cardSurface` (#EFECE8 / dark #1C1C1E), `Color.pageBackground`
// (#F8F7F4 / dark #111113) and `Color.cardBorder` (ink 5% / white 10%) from the colorsets;
// declaring them again is an invalid redeclaration.

/// The prototype has THREE urgency bands; the native model has FOUR priorities. p2 and p3 fold
/// into the medium band (the chip's P1–P4 text keeps them distinguishable) — locked by
/// `UrgencyPaletteTests`.
enum UrgencyPalette {
    static func assetName(for priority: TaskPriority) -> String {
        switch priority {
        case .p1: return "UrgencyHigh"
        case .p2, .p3: return "UrgencyMedium"
        case .p4: return "UrgencyLow"
        }
    }

    static func color(for priority: TaskPriority) -> Color {
        Color(assetName(for: priority))
    }
}

// MARK: - Bento card

/// The shared bento-card treatment (E's 2026-08-19 spec): 16pt continuous corners, the
/// `CardSurface` token, a 0.5pt `CardBorder` hairline, 16pt inner padding, and the §5 soft
/// diffusion shadow. One modifier so every card on Home, Tasks, and Capture stays in lockstep.
private struct BentoCardModifier: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func bentoCard(padding: CGFloat = 16) -> some View {
        modifier(BentoCardModifier(padding: padding))
    }

    /// The prototype's `.label` treatment for card/section headers: bold mono caption, uppercase.
    /// Font stays semantic (`.caption`), so Dynamic Type scaling is untouched (§1).
    func sectionLabel() -> some View {
        font(.caption.monospaced().weight(.bold))
            .textCase(.uppercase)
    }
}
