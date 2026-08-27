//
//  PlaceEditorValidation.swift
//  ADHD LifeOS
//

import Foundation

/// What the place editor will and won't save.
///
/// Both rules exist to stop a silent failure later: a nameless place is unusable in a picker, and
/// a place with no coordinate cannot be geofenced at all — the region is simply never registered
/// and the nudge never fires, with nothing to see.
enum PlaceEditorValidation {
    /// Long enough for "Mum & Dad's house", short enough to keep a row and a notification title
    /// on one line.
    static let maximumNameLength = 60

    /// Trimmed, capped, and `nil` when there is nothing left. Truncates rather than rejects — a
    /// long name is a layout problem, and silently discarding what E typed is worse.
    static func normalizedName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maximumNameLength))
    }

    static func canSave(name: String, coordinate: PlaceCoordinate?) -> Bool {
        normalizedName(name) != nil && coordinate != nil
    }

    /// Build the `Place` the editor would save, or `nil` when it isn't saveable.
    ///
    /// `id` and `createdAt` are passed in rather than minted so EDITING preserves them — a save
    /// that minted a fresh id would orphan every record already tagged with this place.
    static func makePlace(
        id: UUID,
        name: String,
        coordinate: PlaceCoordinate?,
        radiusMetres: Double,
        emoji: String?,
        createdAt: Date = .now
    ) -> Place? {
        guard let name = normalizedName(name), let coordinate else { return nil }
        // A blank emoji field must store nil, not "" — an empty string renders as a blank glyph
        // slot everywhere the identity emoji is shown.
        let trimmedEmoji = emoji?.trimmingCharacters(in: .whitespacesAndNewlines)
        return Place(
            id: id,
            name: name,
            coordinate: coordinate,
            radiusMetres: radiusMetres,
            emoji: (trimmedEmoji?.isEmpty ?? true) ? nil : trimmedEmoji,
            createdAt: createdAt
        )
    }
}
