//
//  MomentumScoreboardViews.swift
//  ADHD LifeOS
//
//  The Momentum v3 building blocks (F-V3-Today, 2026-08-24): the ring, the solid and bordered
//  buttons and the chip, shared by the sprint ring, the area screens, the inbox and more. Spacing is
//  snapped to the §2 grid (v3's 20/22px rhythm → 16/24); every colour is a catalog token.
//
//  Today's own cards that lived here — the ring card and the Best-next-move card — were retired by
//  `F-E3-OneCardToday` (round 8b: the scoreboard goes; round 5a: the one card replaces the hero).
//

import SwiftUI

/// Track + progress arc + whatever belongs in the middle. It drew at 126pt for the day until
/// `F-E3`, and still draws 52pt per area and 64pt for the focus sprint (S4), one instrument.
struct ClosureRing<Center: View>: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    /// What the arc strokes in — accent by default. Today's ring hands in the closure green; the
    /// sprint ring hands in a muted style while paused.
    var arcStyle = AnyShapeStyle(Color.accentColor)
    @ViewBuilder var center: () -> Center

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color("TrackNeutral"), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    arcStyle,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            center()
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: progress)
    }
}

/// v3's solid 54pt action button — full width, 14pt corners, pressed scale per §3. The caller
/// names the fill and its on-colour; raw opacity states are prohibited, so pressing scales.
struct MomentumSolidButtonStyle: ButtonStyle {
    let fill: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.bold())
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(fill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: configuration.isPressed)
    }
}

/// v3's bordered secondary — the quiet counterpart under a solid button.
struct MomentumBorderedButtonStyle: ButtonStyle {
    var minHeight: CGFloat = 48

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.medium))
            .foregroundStyle(Color("LabelSecondary"))
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.cardBorder, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0), value: configuration.isPressed)
    }
}

/// v3's chip: small semibold text on a rounded tint. Colours come from the caller because the
/// chip's meaning does — solid blue for effort ("in motion"), an area's tint for identity,
/// surface-secondary for quiet metadata.
struct MomentumChip: View {
    let text: String
    let background: Color
    let foreground: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(foreground)
    }
}
