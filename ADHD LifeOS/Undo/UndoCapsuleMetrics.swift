//
//  UndoCapsuleMetrics.swift
//  ADHD LifeOS
//
//  `F-C1-UndoCapsule`: the capsule's numbers, its layout rule and its one animation, kept out of
//  the view body for the reason every presentation type in this app is — a SwiftUI body is ~0%
//  covered by design, so a rule left inside one is a rule nothing checks.
//

import SwiftUI

/// E's round-2b shape, as numbers.
enum UndoCapsuleMetrics {
    /// Round 7: *"48pt for anything that starts, closes, adds, undoes, ends or saves"*.
    ///
    /// **A floor, not a frame, and deliberately NOT `AppSearchRowMetrics.fieldHeight` (44).** The
    /// search field's 44 is §3's floor for a control that must never out-grow the capture disc;
    /// this is a taller metric for the one control round 7 names, and it has to be able to grow —
    /// a fixed height would clip the stacked layout at accessibility sizes.
    static let minHeight: CGFloat = 48

    /// The Undo control's own target. It is the reason the capsule exists, so it takes round 7's
    /// 48 rather than §3's 44 floor.
    static let undoMinHeight: CGFloat = 48

    /// It stands in for the search row, so it wears that row's corner rather than inventing one.
    /// A second radius in the same slot would read as a different control having replaced the row.
    static var cornerRadius: CGFloat { AppSearchRowMetrics.fieldCornerRadius }

    // MARK: - §2's grid, one name per gap

    /// The page margin, matching `AppSearchRow`'s own.
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 8
    /// Asset-to-text: the glyph and the verb beside it.
    static let glyphSpacing: CGFloat = 8
    /// Micro positioning: the verb over the subject it names.
    static let verbToSubjectSpacing: CGFloat = 4
    /// Inter-element: the words and the Undo control.
    static let undoSpacing: CGFloat = 8
    /// The stacked (accessibility) layout's row gap.
    static let stackedSpacing: CGFloat = 8
    /// Inside the Undo pill.
    static let undoHorizontalPadding: CGFloat = 16
    static let undoGlyphSpacing: CGFloat = 8

    /// Every gap the capsule spends, so §2's grid is a property a test can sweep rather than a
    /// convention each new value has to remember.
    static var spacings: [(name: String, value: CGFloat)] {
        [
            ("horizontalPadding", horizontalPadding),
            ("verticalPadding", verticalPadding),
            ("glyphSpacing", glyphSpacing),
            ("verbToSubjectSpacing", verbToSubjectSpacing),
            ("undoSpacing", undoSpacing),
            ("stackedSpacing", stackedSpacing),
            ("undoHorizontalPadding", undoHorizontalPadding),
            ("undoGlyphSpacing", undoGlyphSpacing)
        ]
    }
}

/// Which way the capsule lays itself out.
enum UndoCapsuleLayout {
    /// E, round 2b: *"a stacked layout at accessibility sizes"*. Pure, so the rule is checked
    /// without a rendered view — the layout itself is then a single `if` over this answer.
    static func isStacked(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }
}

/// The capsule's one motion.
enum UndoCapsuleMotion {
    /// §7.2: something that APPEARS gets a fade under Reduce Motion, never a cut.
    ///
    /// **The opening-pose rule is satisfied by construction here.** E's shape A moves nothing and
    /// stacks nothing — the capsule arrives in the slot the search row was already occupying — so
    /// the geometry is final on the first frame in BOTH modes and only the opacity ever travels.
    /// That is why this is one curve rather than a curve plus a set of pinned offsets.
    static func appearance(reduceMotion: Bool) -> Animation {
        reduceMotion ? .default : .spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
    }
}
