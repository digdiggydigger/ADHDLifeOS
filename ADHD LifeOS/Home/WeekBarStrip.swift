//
//  WeekBarStrip.swift
//  ADHD LifeOS
//
//  In its own file rather than `MomentumScoreboardViews.swift` purely for that file's length
//  budget — it is still the scoreboard family, drawn wherever `MomentumWeekCharts` counts.
//

import SwiftUI

/// The concept's `chartsOn` bar strip: seven trailing days, oldest first, heights relative to
/// the week's own best day. Zero days draw a short stub in the track colour — the day happened
/// and held nothing, which is a different statement from the bar being missing. `dimLast` marks
/// a still-accruing today (the focus chart's convention); the caption under each chart carries
/// the words, so no state is conveyed by colour alone (§4).
struct WeekBarStrip: View {
    let fractions: [Double]
    var dimLast = false

    private static let railHeight: CGFloat = 32

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(fractions.enumerated()), id: \.offset) { index, fraction in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        fraction > 0
                            ? AnyShapeStyle(Color.accentColor)
                            : AnyShapeStyle(Color(.tertiarySystemFill))
                    )
                    .frame(width: 8, height: fraction > 0 ? max(Self.railHeight * fraction, 4) : 4)
                    .opacity(dimLast && index == fractions.indices.last ? 0.4 : 0.85)
            }
        }
        .frame(height: Self.railHeight, alignment: .bottom)
        .accessibilityHidden(true)
    }
}
