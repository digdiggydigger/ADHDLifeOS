//
//  TaskCreateClientAdapting.swift
//  ADHD LifeOS
//

import Foundation

/// The seam `TaskCreateService` creates a task through, so the composer is testable without a
/// network.
///
/// **One method since `F-D1-ComposerBothDoors`.** It also carried `fetchTags`/`createTag`/
/// `attachTags` while the composer asked for tags; E's round 6 moved tags onto the task, the
/// service was their only caller, and they were pruned rather than left reachable only from their
/// own tests. The composer's one follow-up write — its Time — goes through
/// `TaskDetailClientAdapting.updateTask`, the seam task detail already edits the task with.
protocol TaskCreateClientAdapting: Sendable {
    func createTask(_ input: NormalizedCreateTaskInput) async throws -> TaskItem
}
