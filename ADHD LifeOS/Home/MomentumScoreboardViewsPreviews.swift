//
//  MomentumScoreboardViewsPreviews.swift
//  ADHD LifeOS
//
//  The Momentum building blocks' gallery, split out on the house pattern. Today's ring card, the
//  Best-next-move card and the area list it once showed left with `F-E3-OneCardToday`; Today's
//  one card has its own previews in `HomeTodayCard.swift`.
//

import SwiftUI

#if DEBUG
private struct MomentumScoreboardGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ClosureRing(progress: 0.6, size: 64, lineWidth: 8) {
                    Text("12:00").font(.callout.monospacedDigit().weight(.semibold))
                }
                HStack(spacing: 8) {
                    MomentumChip(text: "15 min", background: .accentColor, foreground: AreaPalette.work.onColor)
                    MomentumChip(
                        text: "📝 Admin", background: Color("CardSurfaceSecondary"), foreground: Color("LabelSecondary")
                    )
                }
                Button("Solid") {}
                    .buttonStyle(MomentumSolidButtonStyle(fill: Color("StateGo"), foreground: Color("OnStateGo")))
                Button("Bordered") {}
                    .buttonStyle(MomentumBorderedButtonStyle())
            }
            .padding(16)
        }
        .background(Color.pageBackground)
    }
}

#Preview("Light") {
    MomentumScoreboardGallery()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    MomentumScoreboardGallery()
        .preferredColorScheme(.dark)
}
#endif
