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
    /// **44 since E's height round, 2026-09-20.** It shipped at 48 with a two-line `.callout`
    /// subject, which drew a **74pt** card — E marked a **45.3pt** band on
    /// `screenshots/undo-capsule/02-…-EDITED.jpg`: *"the UndoCapsule must be made smaller in
    /// height, it looks ugly with the UndoCapsule at the same height as the FAB Icon."* (The
    /// capture disc is 60.) E was shown four shapes rendered on the real screen and chose **two
    /// lines, a size smaller** — board `54`'s arrangement kept, the type stepped down.
    ///
    /// **A floor, not a frame.** A fixed height would clip the stacked layout at accessibility
    /// sizes. 44 is also §3's touch floor, so the capsule is itself exactly one touch target tall.
    static let minHeight: CGFloat = 44

    /// What the Undo pill is DRAWN at. **Its TARGET is still 44** — see `undoHitOverflow`.
    ///
    /// Round 7's *"48pt for anything that … undoes"* cannot be drawn inside a 44pt band, and E
    /// chose the trade explicitly over keeping the capsule tall: *"Yes — draw 32, tap 44"*. Round
    /// 7's number was written for a control that owns its space; this one now sits inside one.
    static let undoDrawnHeight: CGFloat = 32

    /// The tab bar's own trick (`AppTabBarMetrics.slotHitOverflow`), applied here: negative
    /// vertical padding around the `contentShape`, so the layout stays the pill's drawn height
    /// while taps a little above and below it still land. §3's 44pt is kept without drawing 44pt.
    static var undoHitOverflow: CGFloat { max(0, (44 - undoDrawnHeight) / 2) }

    /// It stands in for the search row, so it wears that row's corner rather than inventing one.
    /// A second radius in the same slot would read as a different control having replaced the row.
    static var cornerRadius: CGFloat { AppSearchRowMetrics.fieldCornerRadius }

    // MARK: - §2's grid, one name per gap

    /// The page margin, matching `AppSearchRow`'s own.
    static let horizontalPadding: CGFloat = 16
    /// 4 since the height round — 8 top and bottom is a fifth of E's whole band.
    static let verticalPadding: CGFloat = 4
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
