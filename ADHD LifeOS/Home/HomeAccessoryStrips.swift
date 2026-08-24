//
//  HomeAccessoryStrips.swift
//  ADHD LifeOS
//
//  Home's secondary strip — the due-nudges row — moved out of
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
                        // Names the nudge it dismisses. With several due at once, a row of
                        // buttons all reading "Dismiss" tells a VoiceOver user nothing about
                        // which one they are about to act on — the visible label sits in a
                        // separate element, so the association is lost the moment you navigate
                        // by control rather than by reading order.
                        //
                        // It is also the only handle a UI test has here: the identifier below is
                        // overwritten by the enclosing stack's own identifier (SwiftUI pushes
                        // that down over the subtree), so every dismiss button answers to
                        // "homeDueNudgesStrip" and none can be told apart by id. The label
                        // survives that, which is why the test targets it.
                        .accessibilityLabel("Dismiss \(nudge.label)")
                        .accessibilityIdentifier("homeDueNudgeDismissButton-\(nudge.id)")
                    }
                    .bentoCard()
                }
            }
            .accessibilityIdentifier("homeDueNudgesStrip")
        }
    }
}
