//
//  TaskListRefinement.swift
//  ADHD LifeOS
//

import Foundation

/// Case-insensitive title search over the loaded tasks, recomputed as the user types. The
/// web-parity urgency filter and sort dropdown that used to live here were retired in
/// F-V3-Tasks-rebuild — E confirmed the refinement menu was unused chrome — so search is the
/// whole refinement now, and order stays whatever the grouping stage decides.
enum TaskListRefinement {
    static func apply(tasks: [TaskItem], searchText: String) -> [TaskItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return tasks }
        return tasks.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
}
