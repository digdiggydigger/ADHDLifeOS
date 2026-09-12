//
//  HomeCaptureDoor.swift
//  ADHD LifeOS
//
//  Today's capture door and the picker's area list, split out of `HomeView.swift` when the
//  collapsible life-area section pushed that file over its 400-line budget. `journalClient` was
//  made internal for exactly this move — the house fix is an own-file split, not a bigger file.
//

import SwiftUI

extension HomeView {
    /// The FULL set including archived areas — so the Capture triage picker can grey archived
    /// areas rather than being starved of them (they used to be absent entirely here). The grid
    /// itself still shows active areas only, filtered in `HomeService`.
    var lifeAreasForPicker: [LifeArea] {
        homeService.lifeAreas
    }

    /// The inbox peek rows' pushed capture door. The rows stayed doors into their own capture when
    /// the Captures tab arrived (E asked for that on 2026-08-25); it is the card's header and
    /// "Clear the deck" that cross to the tab instead.
    @ViewBuilder
    var inspectedCaptureDoor: some View {
        if let capture = inspectingHomeCapture {
            JournalCaptureDoor(
                captureId: capture.id,
                lifeAreas: homeService.lifeAreas,
                client: captureClient,
                journalClient: journalClient,
                celebrate: celebrate
            )
        }
    }
}
