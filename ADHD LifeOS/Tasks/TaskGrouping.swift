//
//  TaskGrouping.swift
//  ADHD LifeOS
//

import Foundation

/// Mirrors the web app's `groupTasksByLifeArea` (`src/domain/taskGrouping.ts`): active life areas
/// sorted by `sortOrder`, each yielding a group only if it has matching tasks (open before
/// done within the group). Tasks with no `lifeAreaId` — and, since the Home-reorder block, tasks
/// whose life area is **archived** — land in the trailing "Unassigned" group instead of being
/// dropped or surfacing under an archived heading. `lifeAreaId` is never mutated: archiving only
/// changes display grouping, so unarchiving restores every task to its area with no data change.
enum TaskGrouping {
    static let unassignedLifeAreaName = "Unassigned"

    static func groupTasksByLifeArea(tasks: [TaskItem], lifeAreas: [LifeArea]) -> [LifeAreaTaskGroup] {
        let activeAreas = lifeAreas
            .filter { !$0.archived }
            .sorted { $0.sortOrder < $1.sortOrder }
        let activeAreaIDs = Set(activeAreas.map(\.id))
        var groups: [LifeAreaTaskGroup] = []

        for area in activeAreas {
            let areaTasks = tasks.filter { $0.lifeAreaId == area.id }
            if !areaTasks.isEmpty {
                groups.append(
                    LifeAreaTaskGroup(lifeAreaId: area.id, lifeAreaName: area.name, tasks: sortByStatus(areaTasks))
                )
            }
        }

        // Unassigned = no life area OR a life area that is not an active one (archived, or unknown
        // to this fetch). A task keeps its `lifeAreaId` in the database — only the grouping changes.
        let unassignedTasks = tasks.filter { task in
            guard let lifeAreaId = task.lifeAreaId else { return true }
            return !activeAreaIDs.contains(lifeAreaId)
        }
        if !unassignedTasks.isEmpty {
            groups.append(
                LifeAreaTaskGroup(
                    lifeAreaId: nil,
                    lifeAreaName: unassignedLifeAreaName,
                    tasks: sortByStatus(unassignedTasks)
                )
            )
        }

        return groups
    }

    private static func sortByStatus(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.sorted { statusOrder($0.status) < statusOrder($1.status) }
    }

    private static func statusOrder(_ status: TaskStatus) -> Int {
        status == .open ? 0 : 1
    }
}
