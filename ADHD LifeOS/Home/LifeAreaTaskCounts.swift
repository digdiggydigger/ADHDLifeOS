//
//  LifeAreaTaskCounts.swift
//  ADHD LifeOS
//

import Foundation

/// Mirrors the web app's `countOpenTasksByLifeArea` (`src/domain/lifeAreaTaskCounts.ts`):
/// life areas sorted by `sortOrder`, each paired with its count of `status == .open` tasks;
/// tasks with no `lifeAreaId` count toward nothing.
enum LifeAreaTaskCounts {
    static func countOpenTasksByLifeArea(
        lifeAreas: [LifeArea],
        tasks: [TaskSummary]
    ) -> [LifeAreaTaskCount] {
        let openTasks = tasks.filter { $0.status == .open }
        return lifeAreas
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { area in
                LifeAreaTaskCount(
                    lifeArea: area,
                    openTaskCount: openTasks.filter { $0.lifeAreaId == area.id }.count
                )
            }
    }
}
