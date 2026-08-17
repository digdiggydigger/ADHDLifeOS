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
}

/// Mirrors the web app's `normalizeCreateTaskInput`/`normalizeCreateTagInput`
/// (trim, reject empty, default priority) so mobile and web share the same creation rules.
enum TaskCreateValidation {
    static func normalizeCreateTaskInput(
        title: String,
        notes: String?,
        lifeAreaId: UUID?,
        dueDate: Date?
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
                priority: .p4
            )
        )
    }

    static func normalizeCreateTagInput(name: String) -> Result<String, TaskCreateValidationError> {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyTagName) }
        return .success(trimmed)
    }
}
