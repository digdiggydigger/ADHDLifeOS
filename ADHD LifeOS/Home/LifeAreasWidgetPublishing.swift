//
//  LifeAreasWidgetPublishing.swift
//  ADHD LifeOS
//

import Foundation

/// Builds the Life Areas widget's payload from Home's live state (E's 2026-08-25 widgets note).
/// Lives on the app side because `LifeArea`, `TaskSummary` and `AreaPalette` are app-target
/// types — the extension only ever sees the flattened result, which is exactly how the assigned
/// colour override reaches the Home Screen without the widget knowing the resolver exists.
enum LifeAreasWidgetSnapshotBuilder {
    /// The medium grid seats two columns of three.
    static let maxAreas = 6

    static func snapshot(
        lifeAreas: [LifeArea],
        openTasks: [TaskSummary],
        now: Date = Date()
    ) -> LifeAreasWidgetSnapshot {
        let rows = lifeAreas
            .filter { !$0.archived }
            .sorted { $0.sortOrder < $1.sortOrder }
            .prefix(maxAreas)
            .map { area in
                LifeAreasWidgetSnapshot.Area(
                    name: area.name,
                    emoji: area.colour,
                    paletteAssetStem: AreaPalette.family(for: area).assetName,
                    openCount: openTasks.filter { $0.lifeAreaId == area.id && $0.status == .open }.count
                )
            }
        return LifeAreasWidgetSnapshot(generatedAt: now, areas: Array(rows))
    }
}
