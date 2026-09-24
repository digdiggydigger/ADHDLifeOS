//
//  ComposerMenuTile.swift
//  ADHD LifeOS
//
//  The label of a composer's pop-up menu — glyph, caption, value, ⌃⌄ — as round 7b's boards drew
//  it and E approved by looking (`F-D2-ComposerKeyboardLayout`). The Area and Time menus of the
//  task composer wear it in both its layouts.
//
//  **It is only ever a `Menu`'s LABEL, never a card around one.** A `Menu`'s hit area is its
//  label: `F-D1`'s first build padded a card from outside the Menu and measured a 338 × 20.3pt tap
//  target inside a card drawn 48pt tall. Everything that sizes this tile lives in here, so the
//  whole tile is the target by construction.
//

import SwiftUI

struct ComposerMenuTile: View {
    let glyph: String
    let caption: String
    let value: String
    /// The keyboard bar's thirds are about 132pt wide: an 8pt inset and 4pt gaps keep "15 min"
    /// whole, where the full-width tile's 16 / 8 truncated it to "15…" (round 7b's board, fixed
    /// before E saw it).
    var compact = false

    /// Two lines, the caption over the value, which is why this is 56 where the composer's
    /// one-line controls are 48 (round 7's floor for them).
    static let minHeight: CGFloat = 56
    /// Shared by every control in the composer, so the segments, the tiles and Add read as one set.
    static let cornerRadius: CGFloat = 16

    /// How far the words may shrink before they clip. §1's 0.8 up to xLarge; 0.7 from xxLarge up,
    /// where the compact third is narrowest and 0.7 of `.subheadline` is still at least 13pt. A
    /// single 0.7 would let a long area name reach 10.5pt at the default size, under `typography.md`'s
    /// 11pt minimum. At xxxLarge, 0.8 left "15 min" as "15…" (F-D2's XXXL render).
    static func scaleFloor(at size: DynamicTypeSize) -> CGFloat {
        size >= .xxLarge ? 0.7 : 0.8
    }

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
        HStack(spacing: compact ? 4 : 8) {
            Image(systemName: glyph)
                .foregroundStyle(Color.accentColor)
            // The words outrank the ornaments: at the largest ordinary text size (xxxLarge) the
            // compact third is ~123pt wide, and at 0.9 with no priority the value truncated to
            // "No…" and "15…" (F-D2's XXXL render). They shrink to `scaleFloor` before they clip.
            VStack(alignment: .leading, spacing: 0) {
                Text(caption)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("LabelSecondary"))
                    .lineLimit(1)
                    .minimumScaleFactor(Self.scaleFloor(at: typeSize))
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("LabelPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(Self.scaleFloor(at: typeSize))
            }
            .layoutPriority(1)
            Spacer(minLength: 4)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("LabelSecondary"))
        }
        .padding(.horizontal, compact ? 8 : 16)
        .frame(maxWidth: .infinity, minHeight: Self.minHeight)
        .background(Color.cardSurface, in: shape)
        .overlay(shape.strokeBorder(Color.cardBorder, lineWidth: 1))
        .contentShape(shape)
        // One element that reads "Area, None": the caption is the label and the value its value.
        // The glyphs are decoration, and the ⌃⌄ says what the Menu's pop-up trait already says.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
        .accessibilityValue(value)
    }
}

#if DEBUG
private struct ComposerMenuTilePreview: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ComposerMenuTile(glyph: "square.grid.2x2", caption: "Area", value: "None", compact: true)
                ComposerMenuTile(glyph: "timer", caption: "Time", value: "15 min", compact: true)
            }
            ComposerMenuTile(glyph: "square.grid.2x2", caption: "Area", value: "Work & Career")
        }
        .padding(16)
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    ComposerMenuTilePreview()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ComposerMenuTilePreview()
        .preferredColorScheme(.dark)
}
#endif
