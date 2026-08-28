//
//  ComposerChips.swift
//  ADHD LifeOS
//
//  Shared leaf views for the S1-style composers (task create, journal entry): the eyebrow that
//  says a section's question with its optional-ness out loud, and value-fed life-area chips.
//  `QuickCaptureView` keeps its own service-bound copies; these exist so the other composers
//  don't have to bind to `CaptureInboxService` to look the same.
//

import SwiftUI

/// "Life area  optional" — the S1 section eyebrow: the question in the section label style, the
/// optional-ness beside it in tertiary, never implied by silence.
struct ComposerSectionHeader: View {
    let title: String
    var detail: String?
    /// The "optional" suffix's colour. `nil` keeps the ordinary page's tertiary grey.
    var detailAsset: String?
    /// The TITLE's ink. `nil` keeps the ordinary page's `.secondary`.
    ///
    /// Separate from `detailAsset` because the two fall back to different things — this one to
    /// `.secondary`, that one to `LabelTertiary` — even though the pad hands both the same ink.
    /// On the pad this is not decoration: `.secondary` here measured 2.13:1 on E's device (§4).
    var titleAsset: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(title)
                .sectionLabel()
                .composerSoftInk(titleAsset)
            if let detail {
                Text(detail)
                    .font(.footnote)
                    // Tertiary grey is right on the ordinary page and wrong on the pad, where it
                    // was the last grey left. The pad has ONE ink; "optional" is told apart by
                    // weight and size, which is what §1 asks for anyway.
                    .foregroundStyle(Color(detailAsset ?? "LabelTertiary"))
            }
        }
    }
}

/// An ink override that changes NOTHING when it is `nil`.
///
/// The branch is the whole point. `.foregroundStyle(.secondary)` and `.foregroundStyle(Color(x))`
/// are not two values of one expression — they are two different renderings — so the `nil` case
/// has to be the LITERAL previous expression rather than a "secondary-looking" stand-in. That is
/// what keeps task-create and capture triage unchanged BY CONSTRUCTION rather than by inspection,
/// which is the containment F-PadBalance established across ~20 call sites.
///
/// Why it exists at all: under a container that sets a plain `Color` as its foreground style,
/// `.secondary` inherits that colour at roughly HALF alpha rather than inheriting it. On the
/// journal pad that turned the page's one ink into a second, dimmer one — measured off E's device
/// on 2026-08-28 at 2.13:1 by day and 2.18:1 at night, against a 4.5 bar, on a page where the
/// same ink at full strength clears 5.20:1 / 5.25:1.
struct ComposerSoftInk: ViewModifier {
    let asset: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let asset {
            content.foregroundStyle(Color(asset))
        } else {
            content.foregroundStyle(.secondary)
        }
    }
}

extension View {
    /// Paint quiet composer text in `asset`, or leave it exactly as it was when `asset` is `nil`.
    func composerSoftInk(_ asset: String?) -> some View {
        modifier(ComposerSoftInk(asset: asset))
    }
}

/// Value-fed life-area chips: the no-selection escape first (S1's "Decide later"), then each
/// area — its own tint once chosen, quiet surface otherwise.
struct ComposerAreaChips: View {
    let lifeAreas: [LifeArea]
    /// `nil` omits the no-selection chip entirely. The capture triage card REQUIRES an area, and
    /// there the escape chip did real harm: with nothing chosen it rendered in the accent, so
    /// "no decision" looked like a decision that had been made (E's screenshot, 2026-08-28).
    /// Skip is that screen's "not now".
    let noSelectionLabel: String?
    /// Tapping the chip that is already on clears it. Off by default — the composers offer an
    /// explicit "Decide later" chip instead. The capture triage card has no such escape (an area
    /// is its requirement), so there the lit chip itself has to be the way back to an unmade
    /// choice (E, 2026-08-28).
    var allowsDeselection: Bool = false
    /// The wardrobe. Defaults to the app accent, so task-create and capture triage are unchanged
    /// by construction — only the journal pad passes `.pad`.
    var palette: ComposerChipPalette = .ordinary
    @Binding var selection: UUID?

    var body: some View {
        FlowingChips(spacing: 8) {
            if let noSelectionLabel {
                chip(id: nil, label: noSelectionLabel, family: nil)
            }
            ForEach(lifeAreas) { area in
                chip(
                    id: area.id,
                    label: "\(area.colour) \(area.name)",
                    family: AreaPalette.family(for: area)
                )
            }
        }
    }

    private func chip(id: UUID?, label: String, family: AreaPalette?) -> some View {
        let selected = selection == id
        let background: AnyShapeStyle
        let foreground: Color
        let isPad = palette == .pad
        if selected, let family, !isPad {
            // Per-area tints are right on the ordinary page. On the pad they would smuggle eight
            // more hues onto a surface whose whole problem was hue disagreement, so it stays
            // monochrome and the area is told apart by its emoji and name.
            (background, foreground) = (AnyShapeStyle(family.tint), family.color)
        } else if selected {
            (background, foreground) = (
                AnyShapeStyle(Color(palette.selectedFill)), Color(palette.selectedLabel)
            )
        } else {
            (background, foreground) = (
                AnyShapeStyle(Color(palette.quietSurface)), Color(palette.quietLabel)
            )
        }
        return Button {
            Haptics.play(.selection)
            selection = (selected && allowsDeselection) ? nil : id
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(foreground)
                .padding(.horizontal, 8)
                .frame(minHeight: 36)
                .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        // One identifier shared by every area chip, the way Today's life-area strips share
        // `homeAreaMomentumStrip`. The areas are seeded server-side with UUIDs no test can know in
        // advance, so "any area chip" is the only addressable thing — and it is also exactly what
        // a journey wants to say. The escape chip is named apart so it can never be picked by
        // accident on a screen that offers both.
        .accessibilityIdentifier(id == nil ? "composerAreaChipNone" : "composerAreaChip")
    }
}

/// Feint horizontal rules and a margin line — a sheet of paper, drawn rather than illustrated.
///
/// The structure encodes something true rather than decorating: this is the one box on the screen
/// you write prose INTO, and paper is what that is. Deliberately feint (a 22%-alpha gold) so it
/// reads as texture at a glance and never competes with the words on top of it.
private struct PaperRuling: View {
    /// Roughly one line of body text at default Dynamic Type, so the rules sit under the writing
    /// rather than across it.
    private let lineHeight: CGFloat = 28
    /// Where a notebook's margin falls, and clear of the 16pt text inset.
    private let marginInset: CGFloat = 44

    var body: some View {
        GeometryReader { proxy in
            let rule = Color("JournalPaperRule")
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<Int(proxy.size.height / lineHeight), id: \.self) { _ in
                        Spacer(minLength: lineHeight - 1)
                        rule.frame(height: 1)
                    }
                    Spacer(minLength: 0)
                }
                rule.frame(width: 1).offset(x: marginInset)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The pinned bottom bar's surface: bar material with a hairline top edge, so the boundary
/// between scrolling content and the fixed bar is VISIBLE instead of implied — E's 2026-08-25
/// review marked exactly this line on a screenshot. Every pinned composer/footer bar wears it,
/// so the rule holds app-wide rather than screen by screen.
struct ComposerFooterSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.bar)
            .overlay(alignment: .top) {
                Color.cardBorder
                    .frame(height: 1)
            }
    }
}

extension View {
    func composerFooterSurface() -> some View {
        modifier(ComposerFooterSurface())
    }
}

/// The composer text input — S1's "one big honest box" instead of a Form row.
struct ComposerTextBox: View {
    let placeholder: String
    /// The prompt's colour. `nil` keeps the system placeholder; the pad passes its own, because
    /// the system one is near-white and vanished on the warm sheet.
    var placeholderAsset: String?
    @Binding var text: String
    var accessibilityID: String
    /// The fill, so a composer on a coloured page can hand it one that belongs there. Defaulted to
    /// the ordinary secondary surface, which is what every caller but the journal pad wants.
    var surfaceAsset: String = "CardSurfaceSecondary"
    /// Draws feint rules and a margin behind the text, turning the box into a sheet of paper.
    /// Off everywhere but the journal composer — this is the pad's signature, and a signature
    /// repeated on every composer is just wallpaper.
    var ruled = false

    /// The prompt as its own `Text`, which is the only way to recolour it independently:
    /// `.foregroundStyle` on the `TextField` paints the TYPED TEXT as well, so the pad's ink would
    /// go with it. `prompt:` is iOS 15+, comfortably under this project's 16.0 floor.
    private var prompt: Text {
        guard let placeholderAsset else { return Text(placeholder) }
        return Text(placeholder).foregroundColor(Color(placeholderAsset))
    }

    var body: some View {
        TextField("", text: $text, prompt: prompt, axis: .vertical)
            .lineLimit(4...8)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(surfaceAsset))
                    .overlay { if ruled { PaperRuling() } }
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
            )
            .accessibilityIdentifier(accessibilityID)
    }
}

#if DEBUG
#Preview("Chips Light") {
    VStack(alignment: .leading, spacing: 16) {
        ComposerSectionHeader(title: "Life area", detail: "optional")
        ComposerAreaChips(
            lifeAreas: [
                LifeArea(id: UUID(), name: "Health", colour: "🫀", sortOrder: 0),
                LifeArea(id: UUID(), name: "Work & Career", colour: "💼", sortOrder: 1)
            ],
            noSelectionLabel: "Decide later",
            selection: .constant(nil)
        )
        ComposerTextBox(placeholder: "What's on your mind?", text: .constant(""), accessibilityID: "preview")
    }
    .padding(16)
    .background(Color.pageBackground)
    .preferredColorScheme(.light)
}

#Preview("Chips Dark") {
    VStack(alignment: .leading, spacing: 16) {
        ComposerSectionHeader(title: "Life area", detail: "optional")
        ComposerAreaChips(
            lifeAreas: [LifeArea(id: UUID(), name: "Growth", colour: "🌱", sortOrder: 0)],
            noSelectionLabel: "Decide later",
            selection: .constant(nil)
        )
    }
    .padding(16)
    .background(Color.pageBackground)
    .preferredColorScheme(.dark)
}
#endif
