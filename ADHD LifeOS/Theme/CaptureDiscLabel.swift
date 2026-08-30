//
//  CaptureDiscLabel.swift
//  ADHD LifeOS
//

import SwiftUI

/// v3's capture disc face: a 60pt solid circle with the motion-blue glow, not a bare SF glyph —
/// the fan leans out of THIS. Mid-scroll it collapses to F-DiscPill's capsule so the content
/// underneath shows past it; one `Capsule` draws both states (a square capsule IS a circle), so
/// the morph is a plain frame animation. The OUTER frame stays a full-disc square in both
/// states: the ≥44pt hit target (§3) and the overlay stack's layout never move.
struct CaptureDiscLabel: View {
    let isFabOpen: Bool
    let showsPill: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: "plus")
            .font(.title2.weight(.semibold))
            // "Deep field" (E's pick from the 2026-08-30 A/B render round, over an ink FAB):
            // the blue family survives, but as a CaptureDeep→accent gradient no flat chrome
            // element shares — so the FAB separates from the tab tint, the CTAs and the Work
            // bars without introducing a new hue. Both variants' renders live in
            // screenshots/fab-colour-variants/.
            .foregroundStyle(AreaPalette.work.onColor)
            .scaleEffect(showsPill ? CaptureDiscMetrics.pillGlyphScale : 1)
            .frame(
                width: showsPill ? CaptureDiscMetrics.pillWidth : CaptureDiscMetrics.discDiameter,
                height: showsPill ? CaptureDiscMetrics.pillHeight : CaptureDiscMetrics.discDiameter
            )
            .background(
                LinearGradient(
                    colors: [Color("CaptureDeep"), Color.accentColor],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: Capsule()
            )
            // The glow shrinks with the disc — a pill under the full 12pt bloom would still
            // haze the row it just got out of the way of.
            .shadow(
                color: Color.accentColor.opacity(showsPill ? 0.3 : 0.5),
                radius: showsPill ? 6 : 12,
                x: 0,
                y: showsPill ? 4 : 8
            )
            .rotationEffect(.degrees(isFabOpen ? 135 : 0))
            // Translucent as a pill (E dialled 0.85 → 0.68 off the device GIF), so the row
            // underneath reads THROUGH it — the pill's whole job — and the regrow below starts
            // from visibly glassy, making the expanding fade unmistakable.
            .opacity(showsPill ? CaptureDiscMetrics.pillOpacity : 1)
            .frame(width: CaptureDiscMetrics.discDiameter, height: CaptureDiscMetrics.discDiameter)
            .contentShape(Rectangle())
            // ASYMMETRIC by E's device verdict (F-PillTune): the shrink keeps the snappy spring
            // because it must feel tied to the finger, but the regrow is "a slow gradual
            // expanding fade" — a long easeOut, no bounce. The ternary reads the NEW value at
            // re-evaluation, so each direction gets its own curve.
            .animation(
                reduceMotion
                    ? nil
                    : showsPill
                        ? .spring(response: 0.35, dampingFraction: 0.8)
                        : .easeOut(duration: 0.9),
                value: showsPill
            )
    }
}
