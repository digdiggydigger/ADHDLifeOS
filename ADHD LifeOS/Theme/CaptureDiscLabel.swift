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
            .foregroundStyle(AreaPalette.work.onColor)
            .scaleEffect(showsPill ? CaptureDiscMetrics.pillGlyphScale : 1)
            .frame(
                width: showsPill ? CaptureDiscMetrics.pillWidth : CaptureDiscMetrics.discDiameter,
                height: showsPill ? CaptureDiscMetrics.pillHeight : CaptureDiscMetrics.discDiameter
            )
            // The face's colours, halo and pill curves live in `CaptureDiscFace` since
            // `F-JournalPencilDisc` (2026-09-18): the Journal's pencil disc is this disc's twin —
            // the same colours with the gradient REVERSED, the same glow shrinking the same way.
            .background(CaptureDiscFace.plus.gradient, in: Capsule())
            .captureDiscHalo(CaptureDiscFace.glow(showsPill: showsPill))
            .rotationEffect(.degrees(isFabOpen ? 135 : 0))
            // Translucent as a pill (E dialled 0.85 → 0.68 off the device GIF), so the row
            // underneath reads THROUGH it — the pill's whole job, doubly so now the pill STAYS
            // through the whole read (F-PillStay) — and the regrow starts from visibly glassy,
            // making the expanding fade unmistakable.
            .opacity(showsPill ? CaptureDiscMetrics.pillOpacity : 1)
            .frame(width: CaptureDiscMetrics.discDiameter, height: CaptureDiscMetrics.discDiameter)
            .contentShape(Rectangle())
            // ASYMMETRIC by E's device verdict (F-PillTune) — the spring on the shrink, the long
            // easeOut regrow. See `CaptureDiscFace.pillAnimation`, which the pencil disc shares.
            .animation(
                CaptureDiscFace.pillAnimation(showsPill: showsPill, reduceMotion: reduceMotion),
                value: showsPill
            )
    }
}
