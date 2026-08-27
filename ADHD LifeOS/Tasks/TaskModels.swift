//
//  TaskModels.swift
//  ADHD LifeOS
//

import Foundation

enum TaskPriority: String, Codable, Equatable, Sendable, CaseIterable {
    case p1
    case p2
    case p3
    case p4
}

struct TaskItem: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let lifeAreaId: UUID?
    var title: String
    var status: TaskStatus
    var priority: TaskPriority
    var dueDate: Date?
    /// Per-task focus-sprint config (web: `focusDurationSeconds` / `nudgesCount`). `nil` on
    /// documents written before the fields existed — resolved through
    /// `FocusSprintConfiguration`'s standard defaults wherever they're displayed or started.
    var focusDurationSeconds: Int?
    var nudgesCount: Int?
    /// When this task was last marked done — the only record of *when* a task was finished, and
    /// therefore the only way the Daily Executive Summary can answer "what did I complete today?".
    /// `nil` on an open task, and on any task completed before this field existed: `status: done`
    /// with no stamp means "done, at an unknown time", which deliberately counts as no day's win.
    /// Cleared on re-open — see `TaskCompletionStamp`.
    var completedAt: Date?
    /// WHERE this task was closed (F-Location-Tagging, block 3 remainder) — stamped by the same
    /// write as `completedAt` and erased with it on re-open. `nil` on every task closed before
    /// this shipped, and on any closed with tagging or permission off.
    var placeId: UUID?
    var latitude: Double?
    var longitude: Double?

    init(
        id: UUID,
        lifeAreaId: UUID?,
        title: String,
        status: TaskStatus,
        priority: TaskPriority,
        dueDate: Date?,
        focusDurationSeconds: Int? = nil,
        nudgesCount: Int? = nil,
        completedAt: Date? = nil,
        placeId: UUID? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.lifeAreaId = lifeAreaId
        self.title = title
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.focusDurationSeconds = focusDurationSeconds
        self.nudgesCount = nudgesCount
        self.completedAt = completedAt
        self.placeId = placeId
        self.latitude = latitude
        self.longitude = longitude
    }

    enum CodingKeys: String, CodingKey {
        case id, title, status, priority, latitude, longitude
        case lifeAreaId = "life_area_id"
        case dueDate = "due_date"
        case focusDurationSeconds = "focus_duration_seconds"
        case nudgesCount = "nudges_count"
        case completedAt = "completed_at"
        case placeId = "place_id"
    }
}

/// The completion-stamp rule, split out pure so the transition and the same-day filter are
/// testable without Firestore or a live clock.
///
/// Two rules, both load-bearing for the summary:
/// - Completing stamps the moment; **re-opening clears it**. A task finished yesterday and
///   re-opened today is not a win, and a stale stamp would go on claiming it was.
/// - "Completed today" is day-granular, not a rolling 24 hours — a task finished at 09:00 is
///   still today's win at 23:00.
enum TaskCompletionStamp {
    /// The stamp a status transition implies: the moment for `done`, nothing for `open`.
    static func completedAt(for status: TaskStatus, now: Date = .now) -> Date? {
        status == .done ? now : nil
    }

    /// `task` with the new status and the stamp that status implies, applied together so the two
    /// can never drift apart.
    static func applying(status: TaskStatus, to task: TaskItem, now: Date = .now) -> TaskItem {
        var updated = task
        updated.status = status
        updated.completedAt = completedAt(for: status, now: now)
        return updated
    }

    /// Tasks completed on the same calendar day as `date`, newest first. Tasks with no stamp are
    /// excluded whatever their status — an untimed completion belongs to no particular day.
    static func completedTasks(
        in tasks: [TaskItem],
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> [TaskItem] {
        tasks
            .filter { task in
                guard task.status == .done, let completedAt = task.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: date)
            }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }
}

struct LifeAreaTaskGroup: Identifiable, Equatable, Sendable {
    let lifeAreaId: UUID?
    let lifeAreaName: String
    let tasks: [TaskItem]
    /// Momentum's due-time buckets all carry a nil life-area id, so they name their own identity;
    /// life-area groups leave this nil and keep the original derivation.
    var customId: String?

    var id: String { customId ?? lifeAreaId?.uuidString ?? "unassigned" }
}
