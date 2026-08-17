//
//  LifeAreaEditorValidation.swift
//  ADHD LifeOS
//

import Foundation

/// The three outcomes of validating a proposed rename, mirroring `TagEditorValidation`: trimmed-empty
/// → reject; unchanged after trim → no-op (don't fire a pointless PATCH); otherwise the trimmed name
/// is what to send.
enum LifeAreaNameValidation: Equatable {
    case invalidEmpty
    case unchanged
    case valid(String)
}

/// The outcome of validating a free-typed emoji. The grid path can never produce an invalid value,
/// so this exists for the free-type field only.
enum LifeAreaEmojiValidation: Equatable {
    case invalidEmpty
    case invalidNotSingleGlyph
    case valid(String)
}

/// Pure, unit-testable validation for the Life Area editor.
enum LifeAreaEditorValidation {
    /// Decide what a proposed rename means relative to the current name, both trimmed first
    /// (matching the backend's own trim-and-compare in `plan_life_area_patch`).
    static func renameChange(current: String, proposed: String) -> LifeAreaNameValidation {
        let trimmedProposed = proposed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedProposed.isEmpty else { return .invalidEmpty }
        let trimmedCurrent = current.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedProposed != trimmedCurrent else { return .unchanged }
        return .valid(trimmedProposed)
    }

    /// The trimmed name to create, or `nil` if empty after trimming (Save disabled).
    static func normalizeNewName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Validate a free-typed emoji: exactly **one grapheme cluster** after trimming. `String.count`
    /// counts `Character`s (extended grapheme clusters), so a multi-scalar emoji like a family
    /// (`"👨‍👩‍👧‍👦"`, a single ZWJ-joined cluster) counts as `1` and is valid, while `"ab"` (2) and `""`
    /// (0) are not. The backend accepts any non-empty string; this one-glyph rule is the client's
    /// choice because `HomeView` renders this value as a single large glyph and anything longer would
    /// render as unreadable mush on the Home card (§8).
    static func validateEmoji(_ raw: String) -> LifeAreaEmojiValidation {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalidEmpty }
        guard trimmed.count == 1 else { return .invalidNotSingleGlyph }
        return .valid(trimmed)
    }
}
