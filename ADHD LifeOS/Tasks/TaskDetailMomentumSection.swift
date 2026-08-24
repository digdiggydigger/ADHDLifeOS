//
//  TaskDetailMomentumSection.swift
//  ADHD LifeOS
//
//  S3's "Momentum here" section, in its own file because `TaskDetailView.swift` is at its length
//  budget. `momentumContext` is internal on the view for exactly this split.
//

import SwiftUI

extension TaskDetailView {
    /// S3's "Momentum here": the area's own movement, shown where closing this task would move
    /// it. Renders only when the pushing screen handed history over — the detail never fetches
    /// a list for a label.
    @ViewBuilder
    var momentumHereSection: some View {
        if let areaLine = momentumContext.areaLine {
            Section("Momentum here") {
                Text(areaLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("taskDetailMomentumLine")
            }
        }
    }
}
