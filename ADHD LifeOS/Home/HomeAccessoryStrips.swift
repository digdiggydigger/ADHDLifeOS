//
//  HomeAccessoryStrips.swift
//  ADHD LifeOS
//
//  Home's two secondary strips — the Supabase-bridge warning and the due-nudges row — moved out of
//  `HomeView.swift` on 2026-08-20 so that file fits its length budget again after the Active Goal
//  hero gained sprint state. Same code, different file.
//

import SwiftUI

extension HomeView {
    var reorderList: some View {
        List {
            ForEach(arrangeAreas) { area in
                HStack(spacing: 8) {
                    Text(area.colour)
                    Text(area.name)
                        .font(.body)
                }
                .accessibilityIdentifier("homeReorderRow-\(area.id.uuidString)")
            }
            .onMove(perform: moveArrangeAreas)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }

    /// Each completed drag persists immediately (E's per-move decision): reorder `arrangeAreas`
    /// optimistically, then fire ONE serialised bulk reorder carrying the full ordering. TRAP 6's
    /// serialisation + coalescing lives in `HomeService.submitReorder`.
    func moveArrangeAreas(from source: IndexSet, to destination: Int) {
        arrangeAreas.move(fromOffsets: source, toOffset: destination)
        Task { await homeService.submitReorder(activeInNewOrder: arrangeAreas) }
    }

    @ViewBuilder
    var supabaseBridgeWarningBanner: some View {
        if let warning = authService.supabaseBridgeWarning {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(warning)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityIdentifier("homeSupabaseBridgeWarningBanner")
        }
    }

    @ViewBuilder
    var dueNudgesStrip: some View {
        let due = nudgesService.dueNudges()
        if !due.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(due) { nudge in
                    HStack {
                        Text(nudge.label)
                        Spacer()
                        Button("Dismiss") {
                            Task { await nudgesService.dismiss(nudge) }
                        }
                        .accessibilityIdentifier("homeDueNudgeDismissButton-\(nudge.id)")
                    }
                    .bentoCard()
                }
            }
            .accessibilityIdentifier("homeDueNudgesStrip")
        }
    }
}

/// Pure sizing logic for `LifeAreaCardView`'s emoji glyph, split out so it's unit-testable
/// without a `GeometryReader` host.
enum LifeAreaCardMetrics {
    static let emojiWidthFraction: CGFloat = 0.7

    static func emojiFontSize(forCardWidth width: CGFloat) -> CGFloat {
        width * emojiWidthFraction
    }
}

struct LifeAreaCardView: View {
    let count: LifeAreaTaskCount

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                Text(count.lifeArea.colour)
                    .font(.system(size: LifeAreaCardMetrics.emojiFontSize(forCardWidth: geometry.size.width)))
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .aspectRatio(1, contentMode: .fit)
            Text(count.lifeArea.name)
                .font(.headline)
            Text("\(count.openTaskCount)")
                .font(.title.bold())
        }
        .bentoCard()
    }
}
