//
//  TodayCardRules.swift
//  ADHD LifeOS
//
//  `F-E3-OneCardToday`: the two decisions Today's one card makes that are not words.
//

import SwiftUI

/// Round 5a: *"Next step → 'A "Next step" field.' One optional line on a task, editable from the
/// card and from task detail."* The card writes exactly what Task Detail's row writes (`F-E2`):
/// trimmed, empty means none, and a cleared line DELETES the key rather than storing "".
enum TodayNextStep {
    /// `nil` when the edit changes nothing — a tap in and out of the field costs no write and no
    /// refetch of Today. Otherwise a payload carrying the next step and nothing else, so an edit on
    /// the card can never overwrite a field the card does not show.
    static func payload(draft: String, current: String?) -> TaskUpdatePayload? {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized: String? = trimmed.isEmpty ? nil : trimmed
        guard normalized != current else { return nil }
        var payload = TaskUpdatePayload()
        payload.nextStep = .some(normalized)
        return payload
    }
}

/// Round 5a: *"At AX3 the card is taller than the screen, so the build needs a COMPACT AX3 card
/// with Start above the fold."* Compact at every accessibility size — the same line the house's
/// other stacking layouts draw (`UndoCapsuleLayout.isStacked`).
enum TodayCardLayout {
    static func isCompact(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }
}
