//
//  TagEditorValidation.swift
//  ADHD LifeOS
//

import Foundation

/// The three outcomes of validating a proposed rename, mirroring the backend's own rules
/// (trimmed-empty → reject; unchanged after trim → no-op, don't call the API; otherwise the trimmed
/// name is what to send). Keeps the "don't fire a pointless PATCH" decision out of the view.
enum TagRenameValidation: Equatable {
    case invalidEmpty
    case unchanged
    case valid(String)
}

/// Pure, unit-testable validation for the tag editor. Mirrors `TaskCreateValidation`'s trim/reject
/// rules so the editor and the rest of the app share the same notion of a valid tag name.
enum TagEditorValidation {
    /// Decide what a proposed rename means relative to the current name. Both are trimmed of
    /// surrounding whitespace/newlines before comparison, matching `create_tag`/`rename_tag`.
    static func renameChange(current: String, proposed: String) -> TagRenameValidation {
        let trimmedProposed = proposed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedProposed.isEmpty else { return .invalidEmpty }
        let trimmedCurrent = current.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedProposed != trimmedCurrent else { return .unchanged }
        return .valid(trimmedProposed)
    }

    /// The trimmed name to create, or `nil` if it is empty after trimming (Save disabled).
    static func normalizeNewName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
