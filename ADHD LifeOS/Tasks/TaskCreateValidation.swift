//
//  TaskCreateValidation.swift
//  ADHD LifeOS
//

import Foundation

enum TaskCreateValidationError: LocalizedError, Equatable {
    case emptyTitle
    case emptyTagName

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Title is required."
        case .emptyTagName:
            return "Tag name is required."
        }
    }
}

struct NormalizedCreateTaskInput: Equatable, Sendable {
    let title: String
    let notes: String?
    let lifeAreaId: UUID?
    let dueDate: Date?
    let priority: TaskPriority
    /// Where this task can be DONE (block 4a's field, on the composer since E's 2026-08-28
    /// follow-up). Intent, not history — it never touches the `place_id` a close stamps.
    let atPlaceId: UUID?

    /// Spelled out rather than left memberwise so `atPlaceId` can default — the promote path and
    /// every older call site name no place at all.
    init(
        title: String,
        notes: String?,
        lifeAreaId: UUID?,
        dueDate: Date?,
        priority: TaskPriority,
        atPlaceId: UUID? = nil
    ) {
        self.title = title
        self.notes = notes
        self.lifeAreaId = lifeAreaId
        self.dueDate = dueDate
        self.priority = priority
        self.atPlaceId = atPlaceId
    }
}

/// Mirrors the web app's `normalizeCreateTaskInput`/`normalizeCreateTagInput`
/// (trim, reject empty, default priority) so mobile and web share the same creation rules.
enum TaskCreateValidation {
    static func normalizeCreateTaskInput(
        title: String,
        notes: String?,
        lifeAreaId: UUID?,
        dueDate: Date?,
        atPlaceId: UUID? = nil
    ) -> Result<NormalizedCreateTaskInput, TaskCreateValidationError> {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return .failure(.emptyTitle) }

        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNotes = (trimmedNotes?.isEmpty ?? true) ? nil : trimmedNotes

        return .success(
            NormalizedCreateTaskInput(
                title: trimmedTitle,
                notes: normalizedNotes,
                lifeAreaId: lifeAreaId,
                dueDate: dueDate,
                priority: .p4,
                atPlaceId: atPlaceId
            )
        )
    }

    static func normalizeCreateTagInput(name: String) -> Result<String, TaskCreateValidationError> {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyTagName) }
        return .success(trimmed)
    }
}
