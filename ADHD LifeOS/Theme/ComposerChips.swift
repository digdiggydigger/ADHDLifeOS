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

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(title)
                .sectionLabel()
                .foregroundStyle(.secondary)
            if let detail {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Color("LabelTertiary"))
            }
        }
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
        if selected, let family {
            (background, foreground) = (AnyShapeStyle(family.tint), family.color)
        } else if selected {
            (background, foreground) = (AnyShapeStyle(Color.accentColor), AreaPalette.work.onColor)
        } else {
            (background, foreground) = (AnyShapeStyle(Color("CardSurfaceSecondary")), Color("LabelSecondary"))
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
    @Binding var text: String
    var accessibilityID: String

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .lineLimit(4...8)
            .padding(16)
            .background(Color("CardSurfaceSecondary"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
