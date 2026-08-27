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

    /// The name this place will actually be saved under.
    ///
    /// E's 2026-08-27 rule: choosing an address must NOT write into the name field — it only
    /// supplies a name when the place is saved with the field still empty. So the fallback is
    /// resolved HERE, at save time, rather than by mutating what E sees.
    static func effectiveName(typed: String, addressFallback: String?) -> String? {
        if let typed = normalizedName(typed) { return typed }
        guard let addressFallback else { return nil }
        return normalizedName(addressFallback)
    }

    static func canSave(name: String, coordinate: PlaceCoordinate?, addressFallback: String? = nil) -> Bool {
        // Save must ENABLE on a blank name when an address was chosen, or the fallback could
        // never fire — the button would stay disabled and the rule would be unreachable.
        effectiveName(typed: name, addressFallback: addressFallback) != nil && coordinate != nil
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
        createdAt: Date = .now,
        addressFallback: String? = nil,
        nudgeOnArrival: Bool = false,
        nudgeOnDeparture: Bool = false,
        arrivalMessage: String? = nil,
        departureMessage: String? = nil
    ) -> Place? {
        guard let name = effectiveName(typed: name, addressFallback: addressFallback),
              let coordinate else { return nil }
        // A blank emoji field must store nil, not "" — an empty string renders as a blank glyph
        // slot everywhere the identity emoji is shown. Both messages follow the same rule for a
        // sharper reason: "" would count as "has a message" and blank-nudge every crossing.
        let trimmedEmoji = emoji?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedArrival = arrivalMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDeparture = departureMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
        return Place(
            id: id,
            name: name,
            coordinate: coordinate,
            radiusMetres: radiusMetres,
            emoji: (trimmedEmoji?.isEmpty ?? true) ? nil : trimmedEmoji,
            createdAt: createdAt,
            nudgeOnArrival: nudgeOnArrival,
            nudgeOnDeparture: nudgeOnDeparture,
            arrivalMessage: (trimmedArrival?.isEmpty ?? true) ? nil : trimmedArrival,
            departureMessage: (trimmedDeparture?.isEmpty ?? true) ? nil : trimmedDeparture
        )
    }
}
